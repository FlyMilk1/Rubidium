# frozen_string_literal: true

require 'oj'
require_relative 'vector2'
require_relative 'collider'
require_relative 'rigid_body_2d'

module Rubidium
  # Deserializes a physics scene and all of its objects from JSON using Oj.
  class SceneLoader
    def self.load(file_path)
      data = Oj.load_file(file_path, mode: :strict)
      deserialize_scene(data)
    end

    def self.from_json(json_string)
      data = Oj.load(json_string, mode: :strict)
      deserialize_scene(data)
    end

    def self.deserialize_scene(data)
      case data['type']
      when 'Scene2D'
        raw_bodies = data['rigid_bodies']
        if raw_bodies.is_a?(Hash)
          bodies = {}
          raw_bodies.each do |id, entry|
            key = id.is_a?(String) && id.match?(/\A-?\d+\z/) ? id.to_i : id
            bodies[key] = deserialize_rigid_body_2d(entry)
          end
          Scene2D.new(bodies)
        else
          bodies = (raw_bodies || []).map { |entry| deserialize_rigid_body_2d(entry) }
          Scene2D.new(bodies)
        end
      else
        raise ArgumentError, "Unsupported scene type: #{data['type'].inspect}"
      end
    end
    private_class_method :deserialize_scene

    def self.deserialize_rigid_body_2d(data)
      body = RigidBody2d.new(
        deserialize_number(data['mass']),
        deserialize_vector2(data['position']),
        deserialize_number(data['rotation']),
        deserialize_number(data['drag'] || 0.0),
        data['static'] ? true : false,
        deserialize_number(data['bounciness'] || 0.0)
      )
      body.velocity = deserialize_vector2(data['velocity']) if data['velocity']
      body.acceleration = deserialize_vector2(data['acceleration']) if data['acceleration']
      body.angular_velocity = deserialize_number(data['angular_velocity']) if data.key?('angular_velocity')
      body.angular_acceleration = deserialize_number(data['angular_acceleration']) if data.key?('angular_acceleration')
      body.collider = deserialize_collider(data['collider'])
      body
    end
    private_class_method :deserialize_rigid_body_2d

    def self.deserialize_vector2(data)
      Vector2.new(deserialize_number(data['x']), deserialize_number(data['y']))
    end
    private_class_method :deserialize_vector2

    def self.deserialize_collider(data)
      return nil if data.nil?

      case data['type']
      when 'CircleCollider'
        Collision::CircleCollider.new(deserialize_number(data['radius']))
      when 'RectangleCollider'
        Collision::RectangleCollider.new(
          deserialize_number(data['width']),
          deserialize_number(data['height'])
        )
      else
        raise ArgumentError, "Unsupported collider type: #{data['type'].inspect}"
      end
    end
    private_class_method :deserialize_collider

    def self.deserialize_number(value)
      case value
      when 'Infinity' then Float::INFINITY
      when '-Infinity' then -Float::INFINITY
      when 'NaN' then Float::NAN
      else value
      end
    end
    private_class_method :deserialize_number
  end
end
