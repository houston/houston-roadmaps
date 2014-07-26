module Houston
  module Roadmap
    class Engine < ::Rails::Engine
      isolate_namespace Houston::Roadmap
      
      # Enabling assets precompiling under rails 3.1
      if Rails.version >= '3.1'
        initializer :assets do |config|
          Rails.application.config.assets.precompile += %w(
            houston/roadmap/application.js
            houston/roadmap/application.css )
        end
      end
      
    end
  end
end
