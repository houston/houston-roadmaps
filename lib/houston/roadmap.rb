require "houston/roadmap/engine"

module Houston
  module Roadmap
    extend self
    
    
    def menu_items_for(context={})
      projects = context[:projects]
      ability = context[:ability]
      user = context[:user]
      
      projects = projects.select { |project| ability.can?(:read, project.milestones.build) }
      return [] if projects.empty?
      
      menu_items = []
      menu_items << MenuItem.new("All", Engine.routes.url_helpers.project_roadmaps_path)
      menu_items << MenuItemDivider.new
      menu_items.concat projects.map { |project| ProjectMenuItem.new(project, Engine.routes.url_helpers.project_roadmap_path(project)) }
      menu_items
    end
    
    
  end
end
