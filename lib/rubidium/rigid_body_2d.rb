# frozen_string_literal: true
module Rubidium

  require_relative 'vector2'
  require_relative 'collider'
  require_relative 'collision_resolver'

  class RigidBody2d
    attr_accessor :mass, :velocity, :acceleration, :angular_velocity, :angular_acceleration, :position, :rotation, :drag, :static, :collider
    attr_reader :bounciness

    def initialize(mass, position, rotation, drag = 0.0, static = false, bounciness = 0.0)
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
      self.bounciness = bounciness
    end

    def bounciness=(value)
      float_val = Float(value)
      raise ArgumentError, 'bounciness cannot be NaN' if float_val.nan?

      @bounciness = float_val.clamp(0.0, 1.0)
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

    def collision_manifold(other)
      Collision::Resolver.compute_manifold(self, other)
    end

    def narrow_collision_check(other)
      !collision_manifold(other).nil?
    end

    def resolve_collision(other)
      Collision::Resolver.resolve(self, other)
    end

    def resolve_collisions(spatial_hashmap)
      candidates = spatial_hashmap.get_broad_collided_objects(self)
      candidates.select { |obj| resolve_collision(obj) }
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
