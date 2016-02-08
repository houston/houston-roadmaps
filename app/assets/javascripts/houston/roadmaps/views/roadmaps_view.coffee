class Roadmaps.RoadmapsView extends Backbone.View

  initialize: ->
    @roadmaps = @options.roadmaps
    @template = HandlebarsTemplates['houston/roadmaps/roadmaps/index']
    @renderRoadmap = HandlebarsTemplates['houston/roadmaps/roadmaps/show']
    super

  render: ->
    @$el.html @template()
    $ol = @$el.find("#roadmaps")
    @roadmaps.each (roadmap) =>
      $li = $(@renderRoadmap(roadmap.toJSON()))
      $ol.append $li

      $preview = $li.find(".roadmap-preview")
      milestones = roadmap.milestones()
      if milestones.length > 0
        roadmapView = new Roadmaps.GanttChart milestones,
          el: $preview[0]
          viewport: roadmap.viewport()
          showThumbnail: false
          linkMilestones: false
          bandHeight: 8
          bandMargin: 2
        roadmapView.render()
      else
        $preview.html '<span class="roadmap-empty">Click to add milestones to this roadmap</span>'
    @
