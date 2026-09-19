# frozen_string_literal: true

require_relative 'lib/rubidium/version'

Gem::Specification.new do |spec|
  spec.name    = 'rubidium_physics'  # 'rubidium' is taken on rubygems.org
  spec.version = Rubidium::VERSION
  spec.authors = ['FlyMilk1']
  spec.email   = ['j.yontcheff@gmail.com']

  spec.summary     = 'A pure-Ruby 2D physics library: vectors, rigid bodies, colliders and broad-phase collision detection'
  spec.description = 'Rubidium provides 2D vector math (Vector2), rigid bodies with drag and linear forces, circle/rectangle colliders, and a spatial hashmap for broad-phase collision queries. No external dependencies.'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 2.6'

  spec.files         = Dir['lib/**/*.rb'] + %w[README.md LICENSE CHANGELOG.md]
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rspec', '~> 3.0'
end
