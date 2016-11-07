require "active_support/concern"

module Houston
  module Roadmaps
    module TeamExt
      extend ActiveSupport::Concern

      included do
        has_and_belongs_to_many :roadmaps
      end

      module ClassMethods
        def roadmaps
          Roadmap.joins(:roadmaps_teams).where("roadmaps_teams.team_id" => unscope(:order, :select).pluck(:id))
        end
      end

    end
  end
end
