module Houston::Roadmap
  class Configuration
    attr_reader :markers
    
    def initialize
      @markers = []
      
      config = Houston.config.module(:roadmap).config
      instance_eval(&config) if config
    end
    
    def date(date_string, description)
      @markers.push(date: Date.parse(date_string), description: description)
    end
    
  end
end
