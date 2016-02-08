require "active_support/concern"

module Houston
  module Roadmaps
    module ProjectExt
      extend ActiveSupport::Concern

      included do
        has_and_belongs_to_many :roadmaps
      end

      module ClassMethods
        def goals
          Milestone.where(project_id: unscope(:order, :select).select(:id))
        end
      end

    end
  end
end
