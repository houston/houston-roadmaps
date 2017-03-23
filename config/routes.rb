Houston::Roadmaps::Engine.routes.draw do

  get "roadmaps/dashboard", to: "dashboard#show"
  get "roadmaps/:roadmap_id/dashboard", to: "dashboard#show"

  resources :roadmaps do
    member do
      get "history"
      get "play"
      post "duplicate"

      get "milestones", to: "roadmap_milestones#index"
      put "milestones", to: "roadmap_milestones#update"
    end
  end

  scope "roadmaps/projects/:project_slug" do
    get "goals", to: "project_goals#index", as: :project_goals
  end

  scope "roadmap" do
    post "milestones", :to => "milestones#create"
    get "milestones/:id", :to => "milestones#show", :as => :milestone
    put "milestones/:id", :to => "milestones#update"
    put "milestones/:id/ticket_order", :to => "milestones#update_order"

    post "milestones/:id/tickets", :to => "milestones#create_ticket", constraints: {id: /\d+/}
    post "milestones/:id/tickets/:ticket_id", :to => "milestones#add_ticket", constraints: {id: /\d+/, ticket_id: /\d+/}
    delete "milestones/:id/tickets/:ticket_id", :to => "milestones#remove_ticket", constraints: {id: /\d+/, ticket_id: /\d+/}

    post "milestones/:id/upgrade", :to => "milestones#upgrade", constraints: {id: /\d+/}


    post "goals", :to => "goals#create"
    get "goals/:id", :to => "goals#show", :as => :goal
    put "goals/:id", :to => "goals#update"

    put "goals/:goal_id/todolists/:id", to: "goal_todo_lists#add"
    delete "goals/:goal_id/todolists/:id", to: "goal_todo_lists#remove"
  end

  scope "roadmap" do
    namespace "api" do
      namespace "v1" do
        get "milestones/current", to: "roadmap#current"
      end
    end
  end

end
