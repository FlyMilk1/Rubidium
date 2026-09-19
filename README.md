# Rubidium

A pure-Ruby 2D physics library: vectors, rigid bodies, colliders, and a
spatial hashmap for broad-phase collision detection. No runtime dependencies.

## What's inside

- `Rubidium::Vector2` — 2D vector arithmetic (immutable `+`, `-`, `*`, `/` and
  in-place `add`, `subtract`, `multiply`, `divide`, plus `*_with_scalar`)
- `Rubidium::RigidBody2d` — position, velocity, acceleration, rotation,
  angular velocity, drag, linear forces, and `update(time_step)` integration
- `Rubidium::Collision::CircleCollider` / `Rubidium::Collision::RectangleCollider`
- `Rubidium::SpatialHashmap` — broad-phase collision lookup by grid cell
- `Rubidium::HashSet` — minimal hash-backed set used internally

## Installation

### From a local path (development)

```ruby
# Gemfile
gem 'rubidium', path: '../Rubidium'
```

### From git

```ruby
# Gemfile
gem 'rubidium', git: 'https://github.com/you/rubidium.git'
```

### From rubygems.org (once published)

```bash
gem install rubidium
```

```ruby
# Gemfile
gem 'rubidium'
```

## Usage

```ruby
require 'rubidium'

# A static ground rectangle
ground = Rubidium::RigidBody2d.new(Float::INFINITY, Rubidium::Vector2.new(0, 0), 0.0, 0.0, true)
ground.collider = Rubidium::Collision::RectangleCollider.new(20, 1)

# A ball overlapping the ground, pushed downward by a force
ball = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0, 0.4), 0.0)
ball.collider = Rubidium::Collision::CircleCollider.new(0.5)
ball.add_linear_force(Rubidium::Vector2.new(0, -9.8))

# Broad-phase spatial hash
grid = Rubidium::SpatialHashmap.new(1.0)
grid.build_hashmap([ground, ball])

# Integrate one time step
ball.update(1.0 / 60.0)

# Broad phase (grid cells) then narrow phase (per-collider check)
candidates = grid.get_broad_collided_objects(ball)
colliding = candidates.to_a.select { |other| ball.narrow_collision_check(other) }
puts "colliding with #{colliding.size} object(s)"
```

## Development

```bash
bundle install
bundle exec rspec
```

## License

MIT — see [LICENSE](LICENSE).
