# frozen_string_literal: true

require 'oj'
require_relative 'vector2'
require_relative 'collider'
require_relative 'rigid_body_2d'

module Rubidium
  # Serializes a physics scene and all of its objects to JSON using Oj.
  class SceneSaver
    def self.save(scene, file_path)
      Oj.to_file(file_path, serialize_scene(scene), mode: :strict)
    end

    def self.to_json(scene)
      Oj.dump(serialize_scene(scene), mode: :strict)
    end

    def self.serialize_scene(scene)
      case scene
      when Scene2D
        {
          'type' => 'Scene2D',
          'rigid_bodies' => scene.rigid_bodies.map { |body| serialize_rigid_body_2d(body) }
        }
      else
        raise ArgumentError, "Unsupported scene type: #{scene.class}"
      end
    end
    private_class_method :serialize_scene

    def self.serialize_rigid_body_2d(body)
      {
        'type' => 'RigidBody2d',
        'mass' => serialize_number(body.mass),
        'position' => serialize_vector2(body.position),
        'rotation' => serialize_number(body.rotation),
        'velocity' => serialize_vector2(body.velocity),
        'acceleration' => serialize_vector2(body.acceleration),
        'angular_velocity' => serialize_number(body.angular_velocity),
        'angular_acceleration' => serialize_number(body.angular_acceleration),
        'drag' => serialize_number(body.drag),
        'static' => body.static ? true : false,
        'collider' => serialize_collider(body.collider)
      }
    end
    private_class_method :serialize_rigid_body_2d

    def self.serialize_vector2(vec)
      {
        'x' => serialize_number(vec.x),
        'y' => serialize_number(vec.y)
      }
    end
    private_class_method :serialize_vector2

    def self.serialize_collider(collider)
      case collider
      when nil
        nil
      when Collision::CircleCollider
        {
          'type' => 'CircleCollider',
          'radius' => serialize_number(collider.radius)
        }
      when Collision::RectangleCollider
        {
          'type' => 'RectangleCollider',
          'width' => serialize_number(collider.width),
          'height' => serialize_number(collider.height)
        }
      else
        raise ArgumentError, "Unsupported collider type: #{collider.class}"
      end
    end
    private_class_method :serialize_collider

    def self.serialize_number(value)
      return value unless value.is_a?(Float)
      return 'Infinity' if value == Float::INFINITY
      return '-Infinity' if value == -Float::INFINITY
      return 'NaN' if value.nan?

      value
    end
    private_class_method :serialize_number
  end
end
