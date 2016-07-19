require 'spec_helper'
require 'versus'

describe Versus do
  it "should have a VERSION constant" do
    expect(subject.const_get('VERSION')).to_not be_empty
  end
end

describe Engine do
  subject(:engine) { Engine.new }

  context '#drive' do
    # let(:steps) { 1_000 }
    it 'should step continuously' do
      # engine.step
      # expect(Person.count).to be > 0

      expect { engine.drive! }.not_to raise_error
      expect(engine.universe.people.living.count).to be > 0
    end
  end
end
