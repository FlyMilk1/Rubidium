# frozen_string_literal: true
module Rubidium

  module Collision
  class Collider

  end

  class CircleCollider < Collider
    attr_accessor :radius

    def initialize(radius)
      @radius = radius
    end
  end

  class RectangleCollider < Collider
    attr_accessor :width, :height

    def initialize(width, height)
      @width = width
      @height = height
    end
  end
  end
end
