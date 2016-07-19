module Versus
  module Configuration
    class Settings < OpenStruct
    end

    def config
      Versus.config
    end
  end

  def self.config
    @config ||= Configuration::Settings.new
  end

  def self.configure
    yield config
  end
end

# default prod config
Versus.configure do |versus|
  # versus.people_per_town = 5..10
  # versus.towns_per_region = 2..3
  versus.regions_per_continent = 1..2

  versus.max_person_age = 80
  versus.mortality_rate = 0.005

  versus.initial_age_distribution = 18..50
  versus.eden_generation_count = 30

  versus.years_of_history = 300
end
