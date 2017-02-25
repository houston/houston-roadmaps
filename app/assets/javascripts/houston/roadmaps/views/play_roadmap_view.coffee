class Roadmaps.PlayRoadmapView extends Backbone.View
  el: '#play_roadmap_view'
  milestones: {}

  initialize: (options)->
    @options = options
    @commits = @options.commits
    @milestones = @options.milestones

    @options.viewport = new Roadmaps.Viewport
      start: @options.start,
      end: @options.end
    @options.showThumbnail = false
    @options.showToday = false
    # @options.transition = 50
    # marker =
    #   id: 1,
    #   date: @options.start
    # @options.markers = [marker]

    for commit in @commits
      commit.createdAt = App.serverTimeFormat.parse(commit.createdAt)

    @visibleMilestones = new Roadmaps.Milestones()

    @roadmap = new Roadmaps.GanttChart(@visibleMilestones, @options)

    Mousetrap.bind 'R', => this.reset()
    Mousetrap.bind 'P', => this.play()

    super

  render: ->
    @roadmap.render()
    @reset()

  reset: ->
    console.log('reset')
    @commitId = @commits.first().id
    @updateRoadmap()
    clearInterval(@player) if @player
    @todayLine = @roadmap.roadmap.selectAll('.roadmap-today')
      .data([])
    @todayLine.exit().remove()

  play: ->
    console.log('play')
    @reset()

    @todayLine = @roadmap.roadmap.selectAll('.roadmap-today')
      .data([1])

    interval = 150
    weeks = (@options.end - @options.start) / Duration.WEEK
    playTime = interval * weeks
    @todayLine.enter()
      .append('div')
        .attr('class', 'roadmap-today')
        .attr('style', "left: #{@roadmap.x(@options.start)}px;")

    @todayLine.transition()
      .duration(playTime)
      .ease('linear')
      .attr('style', "left: #{@roadmap.x(@options.end)}px;")

    # play
    today = @options.start
    @player = setInterval =>
      today = 1.week().after(today)
      if today > @options.end
        clearInterval(@player)
      else
        @showLastCommitBefore today
    , interval
    @

  showLastCommitBefore: (date)->
    i = _.findLastIndex @commits, (commit)-> commit.createdAt < date
    commit = @commits[i]
    unless @commitId is (commit && commit.id)
      @commitId = commit && commit.id
      @updateRoadmap()

  updateRoadmap: ->
    milestones = @milestones[@commitId]
    @visibleMilestones.reset milestones, parse: true
