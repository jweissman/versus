module Versus
  module Aristocracy
    def king
      # TODO making this inherited from the last king?
      Person.find_by(profession: {name: 'King'}, living?: true)
    end

    def king?
      king == self
    end

    def queen
      king.partner if king
    end

    def princes
      if king
        king.children.select { |child| child.gender == 'male' }
      else
        []
      end
    end

    def princesses
      if king
        king.children.select { |child| child.gender == 'female' }
      else
        []
      end
    end

    def royal_family
      if king
        [king, queen].compact + princes + princesses
      else
        []
      end
    end

    def noble?(person)
      royal_family.any? do |royalty|
        person == royalty ||
          person.partner == royalty ||
          person.related_to?(royalty) ||
          person.parents.any? { |parent| noble?(parent) }
      end
    end
  end
end
