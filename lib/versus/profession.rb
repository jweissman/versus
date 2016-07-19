module Versus
  class Profession < Model
    attr_accessor :name
    has_many :people
  end
end
