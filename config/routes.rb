Houston::Roadmap::Engine.routes.draw do
  
  get "", :to => "project_roadmap#index", :as => :project_roadmaps
  get "dashboard", :to => "project_roadmap#dashboard"
  get "by_project/:slug", :to => "project_roadmap#show", :as => :project_roadmap
  
  post "milestones", :to => "milestones#create"
  get "milestones/:id", :to => "milestones#show", :as => :milestone
  put "milestones/:id", :to => "milestones#update"

  post "milestones/:id/tickets/:ticket_id", :to => "milestones#add_ticket", constraints: {id: /\d+/, ticket_id: /\d+/}
  delete "milestones/:id/tickets/:ticket_id", :to => "milestones#remove_ticket", constraints: {id: /\d+/, ticket_id: /\d+/}
  
end
