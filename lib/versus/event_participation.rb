module Versus
  class EventParticipation < Model
    # attr_accessor :degree

    belongs_to :person
    belongs_to :event
  end
end
