module Versus
  class Event < Model
    attr_accessor :kind, :description, :year

    has_many :event_participations
    has_many :people, through: :event_participations
    # has_and_belongs_to_many :people
  end
end
