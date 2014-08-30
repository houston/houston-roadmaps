Houston.config.add_navigation_renderer :roadmap do
  projects = followed_projects.select { |project| can?(:read, project.milestones.build) }
  unless projects.empty?
    menu_items = []
    menu_items << MenuItem.new("All", Houston::Roadmap::Engine.routes.url_helpers.project_roadmaps_path)
    menu_items << MenuItemDivider.new
    menu_items.concat projects.map { |project| ProjectMenuItem.new(project, Houston::Roadmap::Engine.routes.url_helpers.project_roadmap_path(project)) }
    menu_items
    
    render_nav_menu "Roadmap", icon: "fa-road", items: menu_items
  end
end
