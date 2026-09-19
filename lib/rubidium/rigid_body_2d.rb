# frozen_string_literal: true
module Rubidium

  require_relative 'vector2'
  require_relative 'collider'

  class RigidBody2d
    attr_accessor :mass, :velocity, :acceleration, :angular_velocity, :angular_acceleration, :position, :rotation, :drag, :collider

    def initialize(mass, position, rotation, drag = 0.0, static = false)
      @mass = mass
      @velocity = Vector2.new(0, 0)
      @acceleration = Vector2.new(0, 0)
      @angular_velocity = 0.0
      @angular_acceleration = 0.0
      @position = position
      @rotation = rotation
      @drag = drag
      @static = static
      @collider = nil
    end

    def update(time_step)
      if @static
        return
      end
      @velocity.x += @acceleration.x * time_step
      @velocity.y += @acceleration.y * time_step
      @position.x += @velocity.x * time_step
      @position.y += @velocity.y * time_step
      @angular_velocity += @angular_acceleration * time_step
      @rotation += @angular_velocity * time_step

      #deceleration with drag
      @velocity.multiply_with_scalar 1 - @drag * time_step

    end

    def add_linear_force(force)
      @acceleration.x += force.x / @mass
      @acceleration.y += force.y / @mass
    end

    def narrow_collision_check(other)
      if collider.respond_to?(:radius) && other.collider.respond_to?(:radius)
        distance = Math.sqrt((position.x - other.position.x)**2 + (position.y - other.position.y)**2)
        return distance < (collider.radius + other.collider.radius)
      elsif (collider.respond_to?(:radius) && other.collider.respond_to?(:width)) || (collider.respond_to?(:width) && other.collider.respond_to?(:radius))
        circle = collider.respond_to?(:radius) ? collider : other.collider
        rect = collider.respond_to?(:width) ? collider : other.collider
        closest_x = [[position.x, rect.width / 2].min, -rect.width / 2].max
        closest_y = [[position.y, rect.height / 2].min, -rect.height / 2].max
        distance_x = position.x - closest_x
        distance_y = position.y - closest_y
        distance_squared = distance_x**2 + distance_y**2
        return distance_squared < (circle.radius**2)
      elsif collider.respond_to?(:width) && other.collider.respond_to?(:width)
        return (position.x - other.position.x).abs < (collider.width / 2 + other.collider.width / 2) &&
               (position.y - other.position.y).abs < (collider.height / 2 + other.collider.height / 2)
      else
        return false
      end
    end

    def get_collided_objects(spatial_hashmap)
      candidates = spatial_hashmap.get_broad_collided_objects(self)
      if candidates.any?
        puts "Broad collision detected for #{object_id}: #{candidates.map(&:object_id).join(', ')}"
      end

      narrow = candidates.select { |obj| narrow_collision_check(obj) }
      if narrow.any?
        puts "Narrow collision detected for #{object_id}: #{narrow.map(&:object_id).join(', ')}"
      end

      narrow
    end
  end
end
