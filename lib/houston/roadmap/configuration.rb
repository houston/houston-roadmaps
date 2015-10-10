module Houston::Roadmap
  class Configuration
    attr_reader :markers

    def initialize
      @markers = []
    end

    def date(date_string, description)
      @markers.push(date: Date.parse(date_string), description: description)
    end

  end
end
