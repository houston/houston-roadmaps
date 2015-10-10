$.fn.extend

  pluck: (attr)->
    _.map @, (el)-> $(el).attr('data-id')
