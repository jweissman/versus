module Versus
  class FamilyTree
    def initialize
      @graph = GraphViz.new(:G, type: :digraph, splines: :ortho)
      @people = []
      @partnerships = []
      @parents = []
    end

    def add_generation(gen_num, people, previous_subgraph:)
      @graph.add_graph(rank: gen_num) do |subgraph|
        people.each do |person|
          add_person(person, subgraph: subgraph, previous_subgraph: previous_subgraph)
        end
      end
    end

    def add_person(person, subgraph:, previous_subgraph:)
      return if @people.include?(person)

      draw_person_node(person, subgraph: subgraph)

      if person.relationships.romantic.any?
        person.partners.each do |partner|
          unless @people.include?(partner)
            add_partner_relation(person, partner, subgraph: subgraph)
          end
        end
      end

      if person.parents.any?
        add_parental_relation(
          parents: person.parents,
          child: person,
          subgraph: subgraph,
          parent_subgraph: previous_subgraph
        )
      end

      @people.push(person)
    end

    def render(title:)
      @graph.output(png: "data/#{title}.png")
    end

    private
    def add_parental_relation(parents:,child:,subgraph:,parent_subgraph:)
      a,b = *parents

      parent_partnership_name = partnership_name_for(a,b)
      children_point = parent_partnership_name + "Children"
      child_point = child.name.gsub(' ','').downcase + "Child"

      parent_subgraph ||= @graph
      unless @parents.include?(parent_partnership_name)
        parent_subgraph.add_nodes(children_point, shape: :point) #, width: 0, height: 0)
        parent_subgraph.add_edges(parent_partnership_name, children_point, dir: 'none')

        @parents.push(parent_partnership_name)
      end

      # children and child points needs to be intermediate subgraph???
      subgraph.add_graph(rank: :same) do |intermediate_graph|
        intermediate_graph.add_edges(children_point, child_point, dir: :none)
        subgraph.add_nodes(child_point, shape: :point) #, width: 0, height: 0)
      end

      subgraph.add_edges(child_point, child.name, dir: :none)
    end

    def add_partner_relation(a,b,subgraph:)
      partnership_name = partnership_name_for(a,b)
      unless @partnerships.include?(partnership_name)
        # subgraph.add_graph(rank: 'same') do |partner_graph|
          subgraph.add_nodes(partnership_name, shape: 'point')
          subgraph.add_edges(a.name,partnership_name, dir: 'none')
          subgraph.add_edges(b.name,partnership_name, dir: 'none')
          # partner_graph.add_edges(b.name,partnership_name, dir: 'none')
        # end

        @partnerships << partnership_name
      end
    end

    def draw_person_node(person, subgraph:)
      subgraph.add_nodes(
        person.name,
        label: person.describe,
        fillcolor: color_for_gender(person.gender),
        shape: 'box',
        style: 'filled',
        group: person.surname
      )
    end

    def partnership_name_for(a,b)
      mother = [a,b].detect { |p| p.gender =='female' }
      father = [a,b].detect { |p| p.gender == 'male' }
      mother.name.gsub(' ','') + "And" + father.name.gsub(' ','') + "Partnership"
    end

    def color_for_gender(gender)
      gender == 'male' ? 'lightblue' : 'pink'
    end
  end
end
