require "active_support/concern"

module Houston
  module Roadmaps
    module ProjectExt
      extend ActiveSupport::Concern

      included do
        has_many :goals
      end

    end
  end
end
