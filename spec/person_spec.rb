require 'spec_helper'

describe Person do
  let(:town) { Town.create }

  context 'genealogy' do
    let(:mother) do
      town.create_person(forename: "Alice", gender: 'female')
    end

    let(:father) do
      town.create_person(forename: "Bob", gender: 'male')
    end

    before do
      mother.partner_with(father)
    end

    subject(:person) do
      mother.make_baby(year: 0)
    end

    let!(:sibling) do
      mother.make_baby(year: 0)
    end

    it 'should know about parents' do
      expect(father.partner).to eq(mother)
      expect(mother.partner).to eq(father)

      expect(person.parents).to include(mother)
      expect(person.parents).to include(father)

      expect(father.children).to include(person)
      expect(mother.children).to include(person)
    end

    it 'should know about partners' do
      expect(town.people.single).to include(person)
      expect(town.people.single).to include(sibling)
      expect(town.people.single).not_to include(mother)
      expect(town.people.single).not_to include(father)
    end

    it 'should know about siblings' do
      expect(person.siblings).to eq([sibling])
      expect(sibling.siblings).to eq([person])
    end
  end
end
