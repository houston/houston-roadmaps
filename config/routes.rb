Houston::Roadmap::Engine.routes.draw do
  
  get "by_project/:slug", :to => "project_roadmap#show", :as => :project_roadmap
  put "by_project/:slug/order", :to => "project_roadmap#update_order"
  
  post "milestones", :to => "milestones#create"
  get "milestones/:id", :to => "milestones#show", :as => :milestone
  put "milestones/:id", :to => "milestones#update"

  post "milestones/:id/tickets/:ticket_id", :to => "milestones#add_ticket", constraints: {id: /\d+/, ticket_id: /\d+/}
  delete "milestones/:id/tickets/:ticket_id", :to => "milestones#remove_ticket", constraints: {id: /\d+/, ticket_id: /\d+/}
  
end
