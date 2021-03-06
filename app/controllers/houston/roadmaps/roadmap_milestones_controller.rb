module Houston
  module Roadmaps
    class RoadmapMilestonesController < RoadmapsController
      layout "houston/roadmaps/application"
      before_action :find_roadmap


      def index
        authorize! :read, Roadmap
        render json: Houston::Roadmaps::RoadmapMilestonePresenter.new(@roadmap.milestones)
      end


      def update
        authorize! :update, @roadmap

        @roadmap.commits.create!(
          user: current_user,
          roadmap: @roadmap,
          message: params[:message],
          milestone_changes: params.fetch(:roadmap, {}).values)

        head :ok
      rescue ActiveRecord::RecordInvalid
        render json: $!.record.errors, status: 422
      end


    private

      def find_roadmap
        @roadmap = Roadmap.preload(:commits).find params[:id]
      end

    end
  end
end
