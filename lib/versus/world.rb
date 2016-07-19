module Versus
  class World < Model
    attr_accessor :name

    has_many :continents
    after_create :raise_continents
    has_many :people, through: :continents
    has_many :towns, through: :continents
    has_many :regions, through: :continents

    belongs_to :universe

    def raise_continents
      create_continent(name: Markov.generate(:name))
    end
  end
end
