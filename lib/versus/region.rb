module Versus
  class Region < Model
    attr_accessor :adjective, :natural_feature, :associated_historical_figure_name

    has_many :towns
    has_many :people, through: :towns
    belongs_to :continent

    def name
      if adjective && associated_historical_figure_name
        "the #{adjective.capitalize} #{natural_feature.capitalize} of #{associated_historical_figure_name}"
      else
        "the #{natural_feature.capitalize}"
      end
    end
  end
end
