require "active_support/concern"

module Houston
  module Roadmaps
    module MilestoneExt
      extend ActiveSupport::Concern

      included do
        has_and_belongs_to_many :roadmaps, join_table: "roadmap_milestones"
      end

    end
  end
end
