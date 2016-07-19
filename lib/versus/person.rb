module Versus
  class Person < Model
    include Configuration
    include Genealogy
    include Aristocracy

    attr_accessor :title, :forename, :surname, :age
    attr_accessor :alive, :gender
    attr_accessor :generation

    # attr_accessor :birth_year, :death_year

    attr_accessor :in_region_move_attempts

    belongs_to :town

    # has_and_belongs_to_many :events
    has_many :event_participations
    has_many :events, through: :event_participations

    belongs_to :profession

    has_many :relationships
    has_many :relations, through: :relationships

    before_create do
      self.alive = true
      self.generation ||= 0
      self.age ||= age_distribution.to_a.sample
      self.in_region_move_attempts ||= 0
    end

    after_create do
      self.title ||= compute_title
    end

    def name
      if title
        "#{title} #{forename} #{surname}"
      else
        "#{forename} #{surname}"
      end
    end

    def describe
      if living?
        "#{self.name} (#{self.age}#{self.sex})"
      else
        "#{self.name} (#{self.sex})"
      # else
      #   "#{self.name} (#{self.birth_year} - #{self.death_year})"
      end
    end

    # def self.birth_year
    # end

    def recompute_title!
      self.title = compute_title
    end

    def compute_title
      case self
      when king then "King"
      when queen then "Queen"
      else
        if princes.include?(self)
          "Prince"
        elsif princesses.include?(self)
          "Princess"
        elsif noble?(self)
          if gender == 'male'
            "Lord"
          else
            "Lady"
          end
        elsif gender == 'female'
          if has_living_partner?
            "Mrs"
          else
            "Ms"
          end
        else
          "Mr"
        end
      end
    end


    def age_distribution
      config.initial_age_distribution
    end

    def living?
      !!alive
    end

    def self.living
      where(living?: true)
    end

    def self.single
      where(has_living_partner?: false)
    end

    def self.of_reproductive_age
      where(age: 18..60)
    end

    def self.good_partner_for(person)
      living.single.where(
        gender: person.opposite_gender,
        age: [18,(person.age-6)].max..[50,(person.age+6)].min
      )
    end

    def self.good_colonist
      living.single.where(age: 18..35)
    end

    def has_living_partner?
      relationships.romantic.where(relation: { living?: true }).any?
    end

    def of_repro_age?
      age >= 18 && age <= 50
    end

    def sex
      gender.chars.first
    end

    def partners
      return [] unless relationships.romantic.any?
      relationships.romantic.map(&:relation)
    end

    def partner
      partners.detect(&:living?)
    end

    def partner_with(new_partner)
      Relationship.create(person: self, relation: new_partner, romantic: true)
      Relationship.create(person: new_partner, relation: self, romantic: true)

      # recompute_title!
      # new_partner.recompute_title!
    end

    def make_baby(year:)
      # partner = partners.detect(&:living?)
      father_surname = self.gender == 'male' ? self.surname : partner.surname
      baby_gender = rand > 0.5 ? 'male' : 'female'
      baby_forename = Markov.generate(:"#{baby_gender}_name")

      baby = town.create_person(
        forename: baby_forename,
        surname: father_surname,
        gender: baby_gender,
        age: 0,
        generation: self.generation+1
      )

      Relationship.create(person: partner, relation: baby, parental: true)
      Relationship.create(person: self, relation: baby, parental: true)

      baby.recompute_title!

      # binding.pry
      description = "#{baby.describe} was born to parents #{partner.describe} and #{self.describe} in #{town.name}"

      # binding.pry
      Event.create(
        kind: "Birth",
        description: description,
        year: year,
        people: [self,baby,partner]
      )

      baby
    end

    def opposite_gender
      gender == 'male' ? 'female' : 'male'
    end

    def potential_partners
      town.people.good_partner_for(self)
    end

    # try to find someone of repro age, without a romantic relationship, within +/- 5 yr
    def candidate_partner
      t0 = Time.now
      partner_pool = potential_partners
      elapsed = Time.now - t0
      chosen_candidate = partner_pool.detect do |c|
        !related_to?(c)
      end

      elapsed = Time.now - t0
      if elapsed > 0.5
        puts "--- Choose candidate took #{elapsed} (#{partner_pool.count} potential partners)"
      end
      chosen_candidate
    end

    def max_age
      config.max_person_age
    end

    def find_partner(year:)
      new_partner = candidate_partner
      if new_partner
        partner_with(new_partner)
        if noble?(self) || noble?(new_partner)
          Person.all.each(&:recompute_title!)
          # recompute_title!
          # new_partner.recompute_title!
        end
        Event.create(kind: "Partnership", description: "#{self.describe} and #{new_partner.describe} became partners in #{town.name}", year: year, people: [self,new_partner])
      end
      new_partner
    end

    def die!(year:)
      create_event(kind: "Death", description: "#{self.describe} died in #{town.name} in #{region.name}", year: year)

      if self.king?
        king_profession = Profession.find_by(name: "King")

        male_kids = self.children.select do |child|
          child.gender == 'male' && child.living?
        end

        oldest_male_child = male_kids.sort_by(&:age).last
        new_king = if oldest_male_child
                     oldest_male_child
                   else
                     # could try to select a related male heir (brother, cousin, nephew)?...
                     # for now just random male...
                     Person.where(gender: 'male', age: 18..40).sample
                   end
        new_king.update(profession: king_profession)

        create_event(kind: "Coronation", description: "#{new_king.describe} was made King after the death of #{self.describe}", year: year)
        Person.all.each(&:recompute_title!)
      end
      update(alive: false) # :(
    end

    def evolve(year)
      return unless living?
      update(age: age + 1)
      # print '.'
      epsilon = 0.1
      # return unless rand < epsilon

      if age > max_age || rand < config.mortality_rate
        die!(year: year)
      end

      if of_repro_age? && rand < epsilon
        if has_living_partner?
          make_baby(year: year) if children.count(&:living?) < 3
        else
          found_partner = find_partner(year: year)
          if !found_partner && region.towns.count > 1
            new_town = (region.towns.all - [self.town]).sample
            create_event(kind: "Move to Another Town", description: "#{self.describe} looked for a partner in #{self.town.name} but found no one, so they moved to #{new_town.name}", year: year)
            update(town: new_town, in_region_move_attempts: self.in_region_move_attempts+1)
          end
        end
      end
            # new_partner = candidate_partner
            # if new_partner
            #   partner_with(new_partner)
            #   create_event(kind: "Partnership", description: "#{self.describe} and #{new_partner.describe} became partners in #{town.name}", year: year)
            # else
            #   # TODO permit new town founding/region exploration...
            #   # if rand < epsilon
            #   #   if self.in_region_move_attempts < 3
            #   #     new_town = (region.towns.all - [self.town]).sample
            #   #     create_event(kind: "Move to Another Town", description: "#{self.describe} looked for a partner in #{self.town.name} but found no one, so they moved to #{new_town.name}", year: year)
            #   #     update(town: new_town, in_region_move_attempts: self.in_region_move_attempts+1)
            #   #   else
            #   #     new_region = (continent.regions.all - [self.region]).sample
            #   #     create_event(
            #   #       kind: "Move to Another Region",
            #   #       year: year,
            #   #       description: "#{self.describe} looked for a partner all over #{self.region.name} but found no one, and so moved to #{new_region.name}")
            #   #     new_town = new_region.towns.sample
            #   #     update(town: new_town, in_region_move_attempts: 0)
            #   #   end
            #   # end
            # end
      # end
    end

    def region; town.region end
    def continent; region.continent end
  end
end
