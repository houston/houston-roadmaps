Houston.config.add_navigation_renderer :roadmap do
  if can?(:read, Milestone)
    render_nav_link "Roadmap", Houston::Roadmap::Engine.routes.url_helpers.project_roadmaps_path, icon: "fa-road"
  end
end


Houston.config.add_project_feature :roadmap do
  name "Roadmap"
  icon "fa-road"
  path { |project| Houston::Roadmap::Engine.routes.url_helpers.project_roadmap_path(project) }
  ability { |ability, project| ability.can?(:read, project.milestones.build) }
end
