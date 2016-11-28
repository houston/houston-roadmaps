module Houston
  module Roadmaps
    module Api
      module V1
        class RoadmapController < ApplicationController
          before_filter :api_authenticate!
          skip_before_filter :verify_authenticity_token


          def current
            roadmaps = current_user.teams.roadmaps
            milestones = RoadmapMilestone.current.joins(:roadmap).merge(roadmaps).includes(milestone: :tickets).map(&:milestone)
            render json: Houston::Roadmaps::MilestoneApiPresenter.new(milestones)
          end


        end
      end
    end
  end
end
