module Versus
  class Town < Model
    include Configuration

    attr_accessor :name
    has_many :people
    belongs_to :region
  end
end
