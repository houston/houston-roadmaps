class Roadmaps.RoadmapHistoryView extends Backbone.View
  el: '#roadmap_history_view'
  milestones: {}

  events:
    'click :radio': 'changeCommit'

  initialize: ->
    @commits = @options.commits
    @commitId = @options.commitId

    dup = (milestones)-> _.clone(milestone) for milestone in milestones

    # The current state of the Roadmap
    # is the result of the last commit
    currentMilestones = @options.milestones
    @milestones[0] = dup(currentMilestones)

    for commit in @commits
      for change in commit.changes
        milestone = _(currentMilestones).findWhere(id: change.milestoneId)
        continue unless milestone

        if change.number is 1
          currentMilestones = _(currentMilestones).without(milestone)
        else
          for attribute, [before, after] of change.modifications
            milestone[attribute] = before

      @milestones[commit.id] = dup(currentMilestones)

    @visibleMilestones = new Roadmaps.Milestones()
    @updateRoadmap()

    @roadmap = new Roadmaps.GanttChart(@visibleMilestones, @options)
    @template = HandlebarsTemplates['houston/roadmaps/roadmap/history']
    super

  render: ->
    @$el.html @template
      commits: @commits

    $form = @$el.find('form')
    $form.css(bottom: 42) if App.meta('env') is 'development'

    setTop = ->
      roadmapBottom = $('#roadmap').position().top + $('#roadmap').height() - 10
      $form.css(top: roadmapBottom)
    setTop()
    $(window).resize(setTop)
    addResizeListener $('#roadmap')[0], setTop

    @$el.find(':radio').first().prop('checked', true)
    @roadmap.render()
    @

  changeCommit: (e)->
    $radio = $(e.target)
    $commit = $radio.closest('.roadmap-commit')
    $commit.prevAll().andSelf().addClass('roadmap-commit-reverted')
    $commit.nextAll().removeClass('roadmap-commit-reverted')
    @commitId = +$radio.val()
    @updateRoadmap()

  updateRoadmap: ->
    milestones = @milestones[@commitId]
    @visibleMilestones.reset milestones, parse: true
