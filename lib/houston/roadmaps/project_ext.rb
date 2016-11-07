require "active_support/concern"

module Houston
  module Roadmaps
    module ProjectExt
      extend ActiveSupport::Concern

      module ClassMethods
        def goals
          Milestone.where(project_id: unscope(:order, :select).select(:id))
        end
      end

    end
  end
end
