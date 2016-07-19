module Versus
  class Relationship < Model
    attr_accessor :romantic, :parental
    belongs_to :person
    belongs_to :relation, class_name: "Person"

    def self.romantic
      where(romantic: true)
    end

    def self.parental
      where(parental: true)
    end

    def is_romantic?
      !!romantic
    end

    def is_parental?
      !!parental
    end
  end
end
