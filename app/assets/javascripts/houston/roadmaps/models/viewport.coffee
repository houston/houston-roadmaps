class Roadmaps.Viewport extends Backbone.Model

  domain: -> [@get('start'), @get('end')]
