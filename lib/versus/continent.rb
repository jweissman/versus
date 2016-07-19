module Versus
  class Continent < Model
    include Configuration
    attr_accessor :name

    has_many :regions
    has_many :people, through: :regions
    has_many :towns, through: :regions
    after_create :civilize
    belongs_to :world

    def civilize
      region_count.times do
        create_region(
          # adjective: Markov.generate(:adjective),
          natural_feature: Markov.generate(:landform) #natural_features.sample
          # associated_historical_figure_name: Markov.generate(:name)
        )
      end
    end

    private
    def region_count
      config.regions_per_continent.to_a.sample
    end

    def natural_features
      %w[ plains hill vale lake ]
    end
  end
end
