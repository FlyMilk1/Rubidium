# frozen_string_literal: true

require_relative 'rigid_body_2d'

module Rubidium
  # Manages a dictionary of 2D rigid bodies keyed by ID and steps them through
  # per-frame physics updates, with JSON save/load support.
  class Scene2D
    attr_accessor :rigid_bodies

    def self.load(file_path)
      SceneLoader.load(file_path)
    end

    def initialize(rigid_bodies = {})
      @rigid_bodies = {}
      @next_id = 1

      if rigid_bodies.is_a?(Hash)
        @rigid_bodies = rigid_bodies.dup
        max_id = @rigid_bodies.keys.select { |k| k.is_a?(Integer) }.max
        @next_id = (max_id || 0) + 1
      else
        rigid_bodies.each { |body| create_rigidbody(body) }
      end
    end

    # Adds a rigid body to the scene and returns its assigned ID.
    def create_rigidbody(rigid_body)
      id = @next_id
      @next_id += 1
      @rigid_bodies[id] = rigid_body
      id
    end

    # Returns the rigid body associated with +id+, or nil if not found.
    def get_rigidbody(id)
      @rigid_bodies[id]
    end

    # Loads rigid bodies from a JSON scene file into this scene.
    def load(file_path)
      loaded = SceneLoader.load(file_path)
      @rigid_bodies = loaded.rigid_bodies
      max_id = @rigid_bodies.keys.select { |k| k.is_a?(Integer) }.max
      @next_id = (max_id || 0) + 1
      self
    end

    # Saves this scene and all of its objects to a JSON file.
    def save(file_path)
      SceneSaver.save(self, file_path)
    end

    # Advances every rigid body in the scene by +time_step+ seconds.
    def update(time_step)
      @rigid_bodies.each_value do |body|
        body.update(time_step)
      end
    end
  end
end
