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

> **Note:** the gem is published as `rubidium_physics` because `rubidium` is taken on rubygems.org.
> The require path stays `rubidium` (namespace `Rubidium`) — use `require 'rubidium'` or `require 'rubidium_physics'`; both work.

### From a local path (development)

```ruby
# Gemfile
gem 'rubidium_physics', path: '../Rubidium'
```

### From git

```ruby
# Gemfile
gem 'rubidium_physics', git: 'https://github.com/FlyMilk1/Rubidium.git'
```

### From rubygems.org (once published)

```bash
gem install rubidium_physics
```

```ruby
# Gemfile
gem 'rubidium_physics'
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
