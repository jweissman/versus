module Versus
  class Engine
    include Configuration

    attr_reader :universe
    def initialize(klass: Universe)
      @year = 0
      @narrative = []

      @universe = klass.create(name: "anonyverse")

      seed_professions
      populate_universe
    end

    def seed_professions
      base_professions = %w[ king queen knight bard priest cleric farmer smith ]
      base_professions.each do |profession|
        Profession.create(name: profession.capitalize)
      end
    end

    def populate_universe
      # pick random region...
      eden = @universe.regions.sample
      puts "--- Awakening people in #{eden.name}..."

      eden_gen = config.eden_generation_count.times.map do
        generate_person(region: eden)
      end

      # found first city...
      first_town = eden.create_town(name: Markov.generate(:place_name))

      Event.create(
        kind: "Town Founding",
        year: 0,
        description: "The firstborn founded the city of #{first_town.name} in #{eden.name}",
        people: eden_gen
      )

      first_town.people = eden_gen

      # eden_gen.each do |person|
      #   person.town = first_town
      #   # first_town.people << person
      # end

      first_king = eden_gen.select { |p| p.gender == 'male' && p.age > 20 && p.age < 40 }.sample
      first_king.profession = Profession.find_by(name: 'King')
      first_king.find_partner(year: 0)

      eden_gen.each do |person|
        print '.'
        person.recompute_title!
      end

      eden.associated_historical_figure_name = first_king.forename
      eden.adjective = Markov.generate(:adjective)

      Event.create(
        kind: "Region Discovery",
        year: 0,
        description: "#{first_king.describe} discovered #{eden.name}",
        people: [first_king]
      )

      # first_king.profession
      # @universe.towns.each(&:populate)
    end

    def generate_person(region:)
      gender = rand > 0.5 ? 'male' : 'female'
      forename = Markov.generate(:"#{gender}_name")
      surname = Markov.generate(:name)
      age = config.initial_age_distribution.to_a.sample

      person = Person.create(
        forename: forename,
        surname: surname,
        age: age,
        gender: gender
      )

      person.create_event(
        kind: "Awakening",
        year: 0,
        description: "#{person.describe} awoke at the beginning of mortal time in #{region.name}"
      )

      person
    end

    def step(max_year: config.years_of_history)
      print '.'
      if should_halt?(max_year)
        halt!
      end
      dramatize
      @year += 1
      @universe.evolve(year: @year)
    end

    def should_halt?(max_year)
      population.zero? || @year > max_year
    end

    def drive!
      puts "---> Begin drive"
      t0 = Time.now
      while running?
        step
      end
      elapsed = Time.now - t0
      puts "---> Drive complete (#{elapsed} elapsed)"
      describe_history
    end

    def halt!
      @halted = true
    end

    private

    def describe_history
      0.upto(@year) do |y|
        annual_events = @universe.events.where(year: y)
        puts "--- YEAR #{y} ---"
        #if annual_events.any?
        annual_events.each do |event|
          puts event.description
        end
        #end
      end
    end

    def dramatize
      puts
      puts "  YEAR #@year"
      puts "  -----------------------"
      puts
      puts "   - The population of the universe is #{population}."
      puts
      puts

      if @year % 20 == 0
        draw_family_tree
        show_demographics
      end

      annual_events = @universe.events.where(year: @year)
      # binding.pry

      annual_events.sort_by(&:kind).each do |event|
        # p [ event: event ]
        puts "  - #{event.description} [#{event.kind}]"
      end
    end

    def running?
      !halted?
    end

    def halted?
      @halted ||= false
    end

    def population
      @universe.people.living.count
    end

    def draw_family_tree
      protagonists = [@universe.people.living.sample].compact

      protagonists.each do |protagonist|
        puts "--- Biography of #{protagonist.name} --- "
        protagonist.events.sort_by(&:year).each do |e|
          puts "In year #{e.year}, #{e.description}"
        end

        # puts "--- Writing family tree for #{protagonist.name}..."
        tree = FamilyTree.new

        protag_family = protagonist.family + protagonist.partners
        # family += protagonist.partners.flat_map(&:family) if protagonist.partners

        # binding.pry
        last_gen_graph = nil
        protag_family.group_by(&:generation).each do |generation,people|
          last_gen_graph = tree.add_generation(generation, people, previous_subgraph: last_gen_graph)
        end

        tree.render(
          title: "year-#@year-#{protagonist.forename.downcase}-#{protagonist.surname.downcase}"
        )
      end
    end

    def show_demographics
      age_groups = {
        '0-24' => 0..24,
        '25-44' => 25..44,
        '45-64' => 45..64,
        '65-100' => 65..100,
        '100+' => 101..1_000
      }

      rows = age_groups.map do |group_name, age_range|
        group_count = @universe.people.living.where(age: age_range).count
        [ group_name, group_count ]
      end

      table = TTY::Table.new(header: %w[ group pop ], rows: rows)
      puts
      puts table.render(:unicode, padding:[0,1])
      puts
    end
  end
end
