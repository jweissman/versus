module Versus
  module Genealogy
    def children
      relationships.parental.map(&:relation)
    end

    def grandchildren
      children.flat_map(&:children)
    end

    def parents
      Relationship.where(relation: self, parental: true).map(&:person)
    end

    def siblings
      parents.flat_map(&:children).uniq - [self]
    end

    def grandparents
      @grandparents ||= parents.flat_map(&:parents)
    end

    def greatgrandparents
      grandparents.flat_map(&:parents)
    end

    def aunts_and_uncles
      parents.flat_map(&:siblings) + parents.flat_map(&:aunts_and_uncles)
    end

    def nieces_and_nephews
      siblings.flat_map(&:children)
    end

    def family(extended: true)
      immediate = [self] + siblings + ancestors + descendants
      if extended
        immediate + aunts_and_uncles + nieces_and_nephews
      else
        immediate
      end
    end

    def ancestors(depth: 4)
      if depth == 0
        parents
      else
        parents + parents.flat_map { |parent| parent.ancestors(depth: depth-1) } #(&:ancestors)
      end
    end

    def descendants(depth: 4)
      if depth == 0
        children
      else
        children + children.flat_map { |child| child.descendants(depth: depth-1) } # (&:descendants)
      end
    end

    def siblings_with?(person)
      !(parents & person.parents).empty?
    end

    def related_to?(person)
      my_relations = self.ancestors
      their_relations = person.ancestors
      shared_relations = my_relations & their_relations
      !shared_relations.empty?
    end

    # my relationship to person
    # def infer_relation_to(person)
    #   if siblings_with?(person)
    #     "siblings"
    #   elsif parents.include?(person)
    #     "child"
    #   elsif person.parents.include?(self)
    #     "parent"
    #   end
    # end
  end
end
