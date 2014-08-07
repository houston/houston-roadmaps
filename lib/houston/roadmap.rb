require "houston/roadmap/engine"

module Houston
  module Roadmap
    extend self
    
    
    def menu_items_for(context={})
      projects = context[:projects]
      ability = context[:ability]
      user = context[:user]
      
      projects = projects.select { |project| ability.can?(:read, project) }
      return [] if projects.empty?
      
      menu_items = []
      menu_items.concat projects.map { |project| ProjectMenuItem.new(project, Engine.routes.url_helpers.project_roadmap_path(project)) }
      menu_items
    end
    
    
  end
end
