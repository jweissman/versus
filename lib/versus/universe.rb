module Versus
  # TODO rename to Universe?
  class Universe < Model
    attr_accessor :name

    has_many :worlds
    has_many :towns, through: :worlds
    has_many :regions, through: :worlds

    has_many :people, through: :worlds
    has_many :events, through: :people

    after_create :make_world

    def make_world
      create_world(name: Markov.generate(:city))
    end

    def evolve(year:)
      people.each do |person|
        person.evolve(year)
      end

      towns.each do |town|
        # ...check if we should found new towns...
        if town.people.good_colonist.count > 50
          # found new town within region
          # if town.region.towns.count < 5
          colonist_count = (20..30).to_a.sample
          colonists = town.people.good_colonist.sample(colonist_count)
          new_town = town.region.create_town(name: Markov.generate(:place_name))

          colonists.each do |colonist|
            colonist.update(town: new_town)
          end
          Event.create(
            kind: "Town Founding",
            year: year,
            description: "Colonists set out from #{town.name} and founded the city of #{new_town.name} in #{new_town.region.name}",
            people: colonists
          )
          # else
          #   # explore new region...
          # end
        end
      end
    end
  end
end
