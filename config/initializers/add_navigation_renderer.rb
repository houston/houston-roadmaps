Houston.config.add_navigation_renderer :roadmaps do
  if can?(:read, Roadmap)
    render_nav_link "Roadmaps", Houston::Roadmaps::Engine.routes.url_helpers.roadmaps_path, icon: "fa-map"
  end
end


Houston.config.add_project_feature :goals do
  name "Goals"
  icon "fa-flag"
  path { |project| Houston::Roadmaps::Engine.routes.url_helpers.project_goals_path(project) }
  ability { |ability, project| ability.can?(:read, project.milestones.build) }
end
