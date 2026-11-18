# frozen_string_literal: true

require_relative 'rigid_body_2d'

module Rubidium
  # Manages a collection of 2D rigid bodies and steps them through
  # per-frame physics updates, with JSON save/load support.
  class Scene2D
    attr_accessor :rigid_bodies

    def self.load(file_path)
      SceneLoader.load(file_path)
    end

    def initialize(rigid_bodies = [])
      @rigid_bodies = rigid_bodies
    end

    # Loads rigid bodies from a JSON scene file into this scene.
    def load(file_path)
      loaded = SceneLoader.load(file_path)
      @rigid_bodies = loaded.rigid_bodies
      self
    end

    # Saves this scene and all of its objects to a JSON file.
    def save(file_path)
      SceneSaver.save(self, file_path)
    end

    # Advances every rigid body in the scene by +time_step+ seconds.
    def update(time_step)
      @rigid_bodies.each do |body|
        body.update(time_step)
      end
    end
    alias Update update
  end
end
