Houston::Roadmap::Engine.routes.draw do

  get "", :to => "project_roadmap#index", :as => :project_roadmaps
  get "dashboard", :to => "project_roadmap#dashboard"
  get "by_project/:slug", :to => "project_roadmap#show", :as => :project_roadmap
  get "by_project/:slug/history", :to => "project_roadmap#history", :as => :project_roadmap_history
  put "by_project/:slug", :to => "project_roadmap#update"

  post "milestones", :to => "milestones#create"
  get "milestones/:id", :to => "milestones#show", :as => :milestone
  put "milestones/:id", :to => "milestones#update"
  put "milestones/:id/ticket_order", :to => "milestones#update_order"

  post "milestones/:id/tickets", :to => "milestones#create_ticket", constraints: {id: /\d+/}
  post "milestones/:id/tickets/:ticket_id", :to => "milestones#add_ticket", constraints: {id: /\d+/, ticket_id: /\d+/}
  delete "milestones/:id/tickets/:ticket_id", :to => "milestones#remove_ticket", constraints: {id: /\d+/, ticket_id: /\d+/}

  namespace "api" do
    namespace "v1" do
      get "milestones/current", to: "roadmap#current"
    end
  end

end
