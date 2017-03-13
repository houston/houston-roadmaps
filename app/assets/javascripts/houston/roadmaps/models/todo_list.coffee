class @TodoList extends Backbone.Model
  urlRoot: '/todolists'

class @TodoLists extends Backbone.Collection
  model: TodoList
