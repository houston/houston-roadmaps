class @Roadmaps.Roadmap extends Backbone.Model
  urlRoot: "/roadmaps"

  milestones: ->
    @_milestones ||= new Roadmaps.Milestones(@get("milestones"), parse: true)

  viewport: ->
    new Roadmaps.Viewport
      start: @milestones().start()
      end: @milestones().end()



class @Roadmaps.Roadmaps extends Backbone.Collection
  model: window.Roadmaps.Roadmap

