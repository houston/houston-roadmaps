class Roadmaps.RoadmapHistoryView extends Backbone.View
  el: '#roadmap_history_view'
  milestones: {}

  events:
    'click :radio': 'changeCommit'

  initialize: (options)->
    @options = options
    @commits = @options.commits
    @milestones = @options.milestones
    @commitId = @options.commitId

    @visibleMilestones = new Roadmaps.Milestones()
    @updateRoadmap()

    @roadmap = new Roadmaps.GanttChart(@visibleMilestones, @options)
    @template = HandlebarsTemplates['houston/roadmaps/roadmap/history']
    super

  render: ->
    @$el.html @template
      commits: _(@commits).reverse()

    $form = @$el.find('form')
    $form.css(bottom: 42) if App.meta('env') is 'development'

    setTop = ->
      roadmapBottom = $('#roadmap').position().top + $('#roadmap').height() - 10
      $form.css(top: roadmapBottom)
    setTop()
    $(window).resize(setTop)
    addResizeListener $('#roadmap')[0], setTop

    @$el.find(":radio[name=commit_id][value=#{@commitId}]").first().prop('checked', true)
    @roadmap.render()
    @

  changeCommit: (e)->
    $radio = $(e.target)
    $commit = $radio.closest('.roadmap-commit')
    $commit.prevAll().addClass('roadmap-commit-reverted')
    $commit.nextAll().andSelf().removeClass('roadmap-commit-reverted')
    @commitId = +$radio.val()
    @updateRoadmap()

  updateRoadmap: ->
    milestones = @milestones[@commitId]
    @visibleMilestones.reset milestones, parse: true
