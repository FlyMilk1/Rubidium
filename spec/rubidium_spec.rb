# frozen_string_literal: true

RSpec.describe Rubidium::Vector2 do
  describe 'arithmetic' do
    it 'adds, subtracts, multiplies and divides immutably' do
      v = described_class.new(3, 4)
      expect(v + Rubidium::Vector2.new(1, 2)).to eq(Rubidium::Vector2.new(4, 6))
      expect(v - Rubidium::Vector2.new(1, 2)).to eq(Rubidium::Vector2.new(2, 2))
      expect(v * Rubidium::Vector2.new(1, 2)).to eq(Rubidium::Vector2.new(3, 8))
      expect(v / Rubidium::Vector2.new(1, 2)).to eq(Rubidium::Vector2.new(3, 2))
      expect(v).to eq(Rubidium::Vector2.new(3, 4)) # original untouched
    end

    it 'mutates in place with scalar helpers' do
      v = Rubidium::Vector2.new(5, 10)
      v.add_with_scalar(2)
      v.multiply_with_scalar(2)
      v.subtract_with_scalar(4)
      v.divide_with_scalar(2)
      expect(v).to eq(Rubidium::Vector2.new(5, 10))
    end

    it 'adds a collection of vectors in place' do
      v = Rubidium::Vector2.new(10, 10)
      v.add([Rubidium::Vector2.new(1, 1), Rubidium::Vector2.new(2, 2)])
      expect(v).to eq(Rubidium::Vector2.new(13, 13))
    end

    it 'subtracts, multiplies and divides a collection of vectors in place' do
      v = Rubidium::Vector2.new(10, 10)
      v.subtract([Rubidium::Vector2.new(1, 1), Rubidium::Vector2.new(2, 2)])
      expect(v).to eq(Rubidium::Vector2.new(7, 7))
      v.multiply([Rubidium::Vector2.new(2, 2)])
      expect(v).to eq(Rubidium::Vector2.new(14, 14))
      v.divide([Rubidium::Vector2.new(2, 2)])
      expect(v).to eq(Rubidium::Vector2.new(7, 7))
    end

    it 'still mutates with a single-vector argument' do
      v = Rubidium::Vector2.new(10, 10)
      v.subtract(Rubidium::Vector2.new(3, 4))
      v.multiply(Rubidium::Vector2.new(2, 2))
      v.divide(Rubidium::Vector2.new(2, 2))
      expect(v).to eq(Rubidium::Vector2.new(7, 6))
    end

    it 'computes dot product, magnitude, and normalized vector' do
      a = Rubidium::Vector2.new(3, 4)
      b = Rubidium::Vector2.new(-2, 5)
      expect(a.dot(b)).to eq(14)
      expect(a.magnitude).to be_within(1e-9).of(5.0)

      unit = a.normalize
      expect(unit.x).to be_within(1e-9).of(0.6)
      expect(unit.y).to be_within(1e-9).of(0.8)
      expect(unit.magnitude).to be_within(1e-9).of(1.0)

      zero = Rubidium::Vector2.new(0, 0).normalize
      expect(zero).to eq(Rubidium::Vector2.new(0.0, 0.0))
    end
  end
end

RSpec.describe Rubidium::RigidBody2d do
  it 'constructs with mass, position and rotation' do
    body = described_class.new(2.0, Rubidium::Vector2.new(1, 2), 0.5)
    expect(body.mass).to eq(2.0)
    expect(body.position).to eq(Rubidium::Vector2.new(1, 2))
    expect(body.rotation).to eq(0.5)
    expect(body.velocity).to eq(Rubidium::Vector2.new(0, 0))
  end

  it 'integrates a single time step from an applied force' do
    body = described_class.new(1.0, Rubidium::Vector2.new(0, 0), 0.0)
    body.add_linear_force(Rubidium::Vector2.new(0, -9.8))
    body.update(0.1)
    expect(body.velocity.y).to be_within(1e-9).of(-0.98)
    expect(body.position.y).to be_within(1e-9).of(-0.098)
  end

  it 'does not move static bodies' do
    body = described_class.new(Float::INFINITY, Rubidium::Vector2.new(0, 0), 0.0, 0.0, true)
    body.add_linear_force(Rubidium::Vector2.new(0, -9.8))
    body.update(0.1)
    expect(body.position).to eq(Rubidium::Vector2.new(0, 0))
  end

  it 'checks circle-vs-rectangle away from the origin, in both argument orders' do
    rect = described_class.new(Float::INFINITY, Rubidium::Vector2.new(100, 100), 0.0, 0.0, true)
    rect.collider = Rubidium::Collision::RectangleCollider.new(20, 1)

    hitting = described_class.new(1.0, Rubidium::Vector2.new(100, 100.4), 0.0)
    hitting.collider = Rubidium::Collision::CircleCollider.new(0.5)

    expect(rect.narrow_collision_check(hitting)).to be(true)   # rect-side call
    expect(hitting.narrow_collision_check(rect)).to be(true)   # circle-side call

    far = described_class.new(1.0, Rubidium::Vector2.new(100, 150), 0.0)
    far.collider = Rubidium::Collision::CircleCollider.new(0.5)
    expect(rect.narrow_collision_check(far)).to be(false)
    expect(far.narrow_collision_check(rect)).to be(false)
  end

  it 'checks circle-vs-circle collisions' do
    a = described_class.new(1.0, Rubidium::Vector2.new(0, 0), 0.0)
    a.collider = Rubidium::Collision::CircleCollider.new(1.0)
    b = described_class.new(1.0, Rubidium::Vector2.new(1.5, 0), 0.0)
    b.collider = Rubidium::Collision::CircleCollider.new(1.0)
    c = described_class.new(1.0, Rubidium::Vector2.new(3.0, 0), 0.0)
    c.collider = Rubidium::Collision::CircleCollider.new(1.0)

    expect(a.narrow_collision_check(b)).to be(true)
    expect(a.narrow_collision_check(c)).to be(false)
  end

  describe 'bounciness' do
    it 'defaults to 0.0 as a Float and accepts an initial value in initialize' do
      default_body = described_class.new(1.0, Rubidium::Vector2.new(0, 0), 0.0)
      expect(default_body.bounciness).to eq(0.0)
      expect(default_body.bounciness).to be_a(Float)

      bouncy_body = described_class.new(1.0, Rubidium::Vector2.new(0, 0), 0.0, 0.0, false, 0.75)
      expect(bouncy_body.bounciness).to eq(0.75)
      expect(bouncy_body.bounciness).to be_a(Float)
    end

    it 'coerces integers to Float, clamps to 0.0..1.0, and rejects NaN or non-numeric values' do
      body = described_class.new(1.0, Rubidium::Vector2.new(0, 0), 0.0)

      body.bounciness = 1
      expect(body.bounciness).to eq(1.0)
      expect(body.bounciness).to be_a(Float)

      body.bounciness = 0
      expect(body.bounciness).to eq(0.0)
      expect(body.bounciness).to be_a(Float)

      body.bounciness = -0.5
      expect(body.bounciness).to eq(0.0)

      body.bounciness = 2.5
      expect(body.bounciness).to eq(1.0)

      expect { body.bounciness = Float::NAN }.to raise_error(ArgumentError)
      expect { body.bounciness = 'not_a_number' }.to raise_error(ArgumentError)
      expect { body.bounciness = nil }.to raise_error(TypeError)
    end
  end

  describe 'analytic collision manifolds and normals' do
    it 'computes circle-vs-circle normal from self to other and exact penetration' do
      a = described_class.new(1.0, Rubidium::Vector2.new(0.0, 0.0), 0.0)
      a.collider = Rubidium::Collision::CircleCollider.new(1.0)
      b = described_class.new(1.0, Rubidium::Vector2.new(1.2, 0.9), 0.0)
      b.collider = Rubidium::Collision::CircleCollider.new(1.0)

      manifold = a.collision_manifold(b)
      expect(manifold).not_to be_nil
      expect(manifold.normal.x).to be_within(1e-9).of(0.8)
      expect(manifold.normal.y).to be_within(1e-9).of(0.6)
      expect(manifold.penetration).to be_within(1e-9).of(0.5)

      reverse = b.collision_manifold(a)
      expect(reverse.normal.x).to be_within(1e-9).of(-0.8)
      expect(reverse.normal.y).to be_within(1e-9).of(-0.6)
      expect(reverse.penetration).to be_within(1e-9).of(0.5)
    end

    it 'provides a deterministic unit normal fallback for coincident circles' do
      a = described_class.new(1.0, Rubidium::Vector2.new(3.0, 4.0), 0.0)
      a.collider = Rubidium::Collision::CircleCollider.new(1.5)
      b = described_class.new(1.0, Rubidium::Vector2.new(3.0, 4.0), 0.0)
      b.collider = Rubidium::Collision::CircleCollider.new(1.0)

      manifold = a.collision_manifold(b)
      expect(manifold.normal.magnitude).to be_within(1e-9).of(1.0)
      expect(manifold.penetration).to be_within(1e-9).of(2.5)
    end

    it 'computes rectangle-vs-rectangle MTV normals for horizontal, vertical, and odd-sized boxes' do
      box_a = described_class.new(1.0, Rubidium::Vector2.new(0.0, 0.0), 0.0)
      box_a.collider = Rubidium::Collision::RectangleCollider.new(20, 1)

      # Vertical overlap is smaller than horizontal overlap
      box_b = described_class.new(1.0, Rubidium::Vector2.new(2.0, 0.75), 0.0)
      box_b.collider = Rubidium::Collision::RectangleCollider.new(1, 1)

      manifold = box_a.collision_manifold(box_b)
      expect(manifold.normal).to eq(Rubidium::Vector2.new(0.0, 1.0))
      expect(manifold.penetration).to be_within(1e-9).of(0.25)
      expect(box_b.collision_manifold(box_a).normal).to eq(Rubidium::Vector2.new(0.0, -1.0))

      # Horizontal overlap is smaller than vertical overlap
      wall = described_class.new(Float::INFINITY, Rubidium::Vector2.new(10.0, 0.0), 0.0, 0.0, true)
      wall.collider = Rubidium::Collision::RectangleCollider.new(2, 10)
      mover = described_class.new(1.0, Rubidium::Vector2.new(8.7, 0.5), 0.0)
      mover.collider = Rubidium::Collision::RectangleCollider.new(1, 2)

      side_manifold = mover.collision_manifold(wall)
      expect(side_manifold.normal).to eq(Rubidium::Vector2.new(1.0, 0.0))
      expect(side_manifold.penetration).to be_within(1e-9).of(0.2)
    end

    it 'computes circle-vs-rectangle normals for flat faces, corners, and interior centers' do
      rect = described_class.new(Float::INFINITY, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, true)
      rect.collider = Rubidium::Collision::RectangleCollider.new(4, 2)

      # Flat top face hit
      top_circle = described_class.new(1.0, Rubidium::Vector2.new(0.5, 1.3), 0.0)
      top_circle.collider = Rubidium::Collision::CircleCollider.new(0.5)
      m_top = rect.collision_manifold(top_circle)
      expect(m_top.normal).to eq(Rubidium::Vector2.new(0.0, 1.0))
      expect(m_top.penetration).to be_within(1e-9).of(0.2)
      expect(top_circle.collision_manifold(rect).normal).to eq(Rubidium::Vector2.new(0.0, -1.0))

      # Corner hit at (2 + 0.3, 1 + 0.4) -> distance 0.5 from corner (2, 1)
      corner_circle = described_class.new(1.0, Rubidium::Vector2.new(2.3, 1.4), 0.0)
      corner_circle.collider = Rubidium::Collision::CircleCollider.new(1.0)
      m_corner = rect.collision_manifold(corner_circle)
      expect(m_corner.normal.x).to be_within(1e-9).of(0.6)
      expect(m_corner.normal.y).to be_within(1e-9).of(0.8)
      expect(m_corner.penetration).to be_within(1e-9).of(0.5)

      # Circle center strictly inside odd-height rectangle (20x1)
      odd_rect = described_class.new(Float::INFINITY, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, true)
      odd_rect.collider = Rubidium::Collision::RectangleCollider.new(20, 1)
      inside_circle = described_class.new(1.0, Rubidium::Vector2.new(0.0, 0.4), 0.0)
      inside_circle.collider = Rubidium::Collision::CircleCollider.new(0.5)
      m_inside = odd_rect.collision_manifold(inside_circle)
      expect(m_inside.normal).to eq(Rubidium::Vector2.new(0.0, 1.0))
      expect(m_inside.penetration).to be_within(1e-9).of(0.6)
    end

    it 'returns nil for separated bodies or bodies without colliders' do
      a = described_class.new(1.0, Rubidium::Vector2.new(0.0, 0.0), 0.0)
      b = described_class.new(1.0, Rubidium::Vector2.new(0.0, 0.0), 0.0)
      expect(a.collision_manifold(b)).to be_nil

      a.collider = Rubidium::Collision::CircleCollider.new(1.0)
      expect(a.collision_manifold(b)).to be_nil

      b.collider = Rubidium::Collision::CircleCollider.new(1.0)
      b.position = Rubidium::Vector2.new(2.5, 0.0)
      expect(a.collision_manifold(b)).to be_nil
    end
  end
end

RSpec.describe Rubidium::SpatialHashmap do
  let(:ground) do
    body = Rubidium::RigidBody2d.new(Float::INFINITY, Rubidium::Vector2.new(0, 0), 0.0, 0.0, true)
    body.collider = Rubidium::Collision::RectangleCollider.new(20, 1)
    body
  end

  let(:ball) do
    body = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0, 0.4), 0.0)
    body.collider = Rubidium::Collision::CircleCollider.new(0.5)
    body
  end

  it 'finds broad-phase candidates for overlapping bodies as a Set' do
    grid = described_class.new(1.0)
    grid.build_hashmap([ground, ball])
    candidates = grid.get_broad_collided_objects(ball)
    expect(candidates).to be_a(Set)
    expect(candidates).to eq(Set[ground])
  end

  it 'accepts overlapping bodies in the narrow phase' do
    expect(ball.narrow_collision_check(ground)).to be(true)
  end

  it 'rejects separated bodies in the narrow phase' do
    far = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0, 50), 0.0)
    far.collider = Rubidium::Collision::CircleCollider.new(0.5)
    expect(far.narrow_collision_check(ground)).to be(false)
  end

  it 'reports collisions through the combined get_collided_objects API' do
    grid = described_class.new(1.0)
    grid.build_hashmap([ground, ball])
    collided = nil
    expect do
      collided = ball.get_collided_objects(grid)
    end.to output(/Broad collision detected/).to_stdout
    expect(collided).to eq([ground])
  end

  it 'indexes odd-integer rectangle half-extents accurately in broad phase' do
    floor = Rubidium::RigidBody2d.new(Float::INFINITY, Rubidium::Vector2.new(0, 0), 0.0, 0.0, true)
    floor.collider = Rubidium::Collision::RectangleCollider.new(20, 1)

    ball_on_edge = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0, 0.8), 0.0)
    ball_on_edge.collider = Rubidium::Collision::CircleCollider.new(0.5)

    grid = described_class.new(0.4)
    grid.build_hashmap([floor, ball_on_edge])
    expect(grid.get_broad_collided_objects(ball_on_edge)).to include(floor)
    expect(ball_on_edge.narrow_collision_check(floor)).to be(true)
  end
end

RSpec.describe Rubidium::Scene2D do
  it 'initializes with an empty rigid_bodies dictionary by default' do
    scene = described_class.new
    expect(scene.rigid_bodies).to eq({})
  end

  it 'creates and retrieves rigid bodies by ID with create_rigidbody and get_rigidbody' do
    scene = described_class.new
    b1 = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0, 0), 0.0)
    b2 = Rubidium::RigidBody2d.new(2.0, Rubidium::Vector2.new(3, 4), 0.5)

    id1 = scene.create_rigidbody(b1)
    id2 = scene.create_rigidbody(b2)

    expect(id1).not_to eq(id2)
    expect(scene.rigid_bodies).to eq({ id1 => b1, id2 => b2 })
    expect(scene.get_rigidbody(id1)).to equal(b1)
    expect(scene.get_rigidbody(id2)).to equal(b2)
    expect(scene.get_rigidbody(9999)).to be_nil
  end

  it 'calls update on every rigid body in update' do
    b1 = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0, 0), 0.0)
    b1.add_linear_force(Rubidium::Vector2.new(0, -10.0))
    b2 = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(5, 0), 0.0)
    b2.add_linear_force(Rubidium::Vector2.new(2.0, 0))

    scene = described_class.new([b1, b2])
    scene.update(0.5)

    expect(b1.velocity.y).to be_within(1e-9).of(-5.0)
    expect(b1.position.y).to be_within(1e-9).of(-2.5)
    expect(b2.velocity.x).to be_within(1e-9).of(1.0)
    expect(b2.position.x).to be_within(1e-9).of(5.5)

    scene.update(0.5)
    expect(b1.velocity.y).to be_within(1e-9).of(-10.0)
  end

  it 'saves and loads a scene with all rigid bodies, colliders, and infinity mass via Oj' do
    require 'tempfile'

    ground = Rubidium::RigidBody2d.new(Float::INFINITY, Rubidium::Vector2.new(0, -10), 0.0, 0.0, true)
    ground.collider = Rubidium::Collision::RectangleCollider.new(20, 2)

    ball = Rubidium::RigidBody2d.new(2.5, Rubidium::Vector2.new(1.5, 4.0), 0.25, 0.1, false, 0.65)
    ball.velocity = Rubidium::Vector2.new(3.0, -1.0)
    ball.acceleration = Rubidium::Vector2.new(0.0, -9.8)
    ball.angular_velocity = 0.5
    ball.angular_acceleration = 0.02
    ball.collider = Rubidium::Collision::CircleCollider.new(0.75)

    plain = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(5, 5), 0.0)

    scene = described_class.new
    ground_id = scene.create_rigidbody(ground)
    ball_id = scene.create_rigidbody(ball)
    plain_id = scene.create_rigidbody(plain)

    Tempfile.create(['scene', '.json']) do |file|
      scene.save(file.path)
      loaded = described_class.load(file.path)

      expect(loaded).to be_a(described_class)
      expect(loaded.rigid_bodies.size).to eq(3)

      loaded_ground = loaded.get_rigidbody(ground_id)
      loaded_ball = loaded.get_rigidbody(ball_id)
      loaded_plain = loaded.get_rigidbody(plain_id)

      expect(loaded_ground.mass).to eq(Float::INFINITY)
      expect(loaded_ground.static).to be(true)
      expect(loaded_ground.position).to eq(Rubidium::Vector2.new(0, -10))
      expect(loaded_ground.collider).to be_a(Rubidium::Collision::RectangleCollider)
      expect(loaded_ground.collider.width).to eq(20)
      expect(loaded_ground.collider.height).to eq(2)

      expect(loaded_ball.mass).to eq(2.5)
      expect(loaded_ball.static).to be(false)
      expect(loaded_ball.position).to eq(Rubidium::Vector2.new(1.5, 4.0))
      expect(loaded_ball.rotation).to eq(0.25)
      expect(loaded_ball.drag).to eq(0.1)
      expect(loaded_ball.velocity).to eq(Rubidium::Vector2.new(3.0, -1.0))
      expect(loaded_ball.acceleration).to eq(Rubidium::Vector2.new(0.0, -9.8))
      expect(loaded_ball.angular_velocity).to eq(0.5)
      expect(loaded_ball.angular_acceleration).to eq(0.02)
      expect(loaded_ball.bounciness).to eq(0.65)
      expect(loaded_ball.collider).to be_a(Rubidium::Collision::CircleCollider)
      expect(loaded_ball.collider.radius).to eq(0.75)

      expect(loaded_plain.collider).to be_nil

      # Verify static body stays put and dynamic body updates after loading
      loaded.update(0.1)
      expect(loaded_ground.position).to eq(Rubidium::Vector2.new(0, -10))
      expect(loaded_ball.position.x).to be_within(1e-9).of(1.8)

      # Verify instance-level load replaces rigid_bodies and advances next_id
      empty_scene = described_class.new
      empty_scene.load(file.path)
      expect(empty_scene.rigid_bodies.size).to eq(3)
      extra = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0, 0), 0.0)
      extra_id = empty_scene.create_rigidbody(extra)
      expect([ground_id, ball_id, plain_id]).not_to include(extra_id)
      expect(empty_scene.get_rigidbody(extra_id)).to equal(extra)
    end
  end

  it 'defaults missing bounciness in legacy JSON scenes to 0.0' do
    legacy_json = {
      'type' => 'Scene2D',
      'rigid_bodies' => {
        '1' => {
          'type' => 'RigidBody2d',
          'mass' => 1.0,
          'position' => { 'x' => 0, 'y' => 0 },
          'rotation' => 0.0,
          'static' => false,
          'collider' => nil
        }
      }
    }
    scene = Rubidium::SceneLoader.from_json(Oj.dump(legacy_json, mode: :strict))
    expect(scene.get_rigidbody(1).bounciness).to eq(0.0)
  end

  describe 'collision blocking and bounciness' do
    it 'blocks a zero-bounciness circle against a static floor and keeps it supported under gravity' do
      floor = Rubidium::RigidBody2d.new(Float::INFINITY, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, true)
      floor.collider = Rubidium::Collision::RectangleCollider.new(20.0, 2.0)

      ball = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0.0, 1.3), 0.0, 0.0, false, 0.0)
      ball.collider = Rubidium::Collision::CircleCollider.new(0.5)
      ball.velocity = Rubidium::Vector2.new(2.0, -5.0)
      ball.add_linear_force(Rubidium::Vector2.new(0.0, -9.8))

      scene = described_class.new([floor, ball])
      scene.resolve_collisions

      # Floor top is y=1.0, ball radius is 0.5 -> resting center at y=1.5
      expect(ball.position.y).to be_within(1e-9).of(1.5)
      expect(ball.velocity.y).to be_within(1e-9).of(0.0)
      expect(ball.velocity.x).to be_within(1e-9).of(2.0)

      60.times { scene.update(1.0 / 60.0) }
      expect(ball.position.y).to be_within(1e-6).of(1.5)
      expect(floor.position).to eq(Rubidium::Vector2.new(0.0, 0.0))
    end

    it 'blocks a zero-bounciness rectangle against a static wall while preserving tangential velocity' do
      wall = Rubidium::RigidBody2d.new(Float::INFINITY, Rubidium::Vector2.new(5.0, 0.0), 0.0, 0.0, true)
      wall.collider = Rubidium::Collision::RectangleCollider.new(2.0, 20.0)

      box = Rubidium::RigidBody2d.new(2.0, Rubidium::Vector2.new(3.8, 1.0), 0.0, 0.0, false, 0.0)
      box.collider = Rubidium::Collision::RectangleCollider.new(1.0, 2.0)
      box.velocity = Rubidium::Vector2.new(4.0, 3.0)

      box.resolve_collision(wall)
      expect(box.position.x).to be_within(1e-9).of(3.5)
      expect(box.velocity.x).to be_within(1e-9).of(0.0)
      expect(box.velocity.y).to be_within(1e-9).of(3.0)
    end

    it 'never moves static bodies even if their mass is finite' do
      static_block = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, true, 0.5)
      static_block.collider = Rubidium::Collision::RectangleCollider.new(4.0, 2.0)

      mover = Rubidium::RigidBody2d.new(10.0, Rubidium::Vector2.new(0.0, 1.4), 0.0, 0.0, false, 0.5)
      mover.collider = Rubidium::Collision::CircleCollider.new(0.5)
      mover.velocity = Rubidium::Vector2.new(0.0, -4.0)

      mover.resolve_collision(static_block)
      expect(static_block.position).to eq(Rubidium::Vector2.new(0.0, 0.0))
      expect(static_block.velocity).to eq(Rubidium::Vector2.new(0.0, 0.0))
      expect(mover.position.y).to be_within(1e-9).of(1.5)
      expect(mover.velocity.y).to be_within(1e-9).of(2.0)
    end

    it 'bounces circles off static surfaces by bounciness * velocity' do
      floor = Rubidium::RigidBody2d.new(Float::INFINITY, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, true)
      floor.collider = Rubidium::Collision::RectangleCollider.new(20.0, 2.0)

      ball_half = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0.0, 1.4), 0.0, 0.0, false, 0.5)
      ball_half.collider = Rubidium::Collision::CircleCollider.new(0.5)
      ball_half.velocity = Rubidium::Vector2.new(3.0, -10.0)

      ball_half.resolve_collision(floor)
      expect(ball_half.position.y).to be_within(1e-9).of(1.5)
      expect(ball_half.velocity.y).to be_within(1e-9).of(5.0)
      expect(ball_half.velocity.x).to be_within(1e-9).of(3.0)

      ball_elastic = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0.0, 1.4), 0.0, 0.0, false, 1.0)
      ball_elastic.collider = Rubidium::Collision::CircleCollider.new(0.5)
      ball_elastic.velocity = Rubidium::Vector2.new(-2.0, -8.0)

      ball_elastic.resolve_collision(floor)
      expect(ball_elastic.position.y).to be_within(1e-9).of(1.5)
      expect(ball_elastic.velocity.y).to be_within(1e-9).of(8.0)
      expect(ball_elastic.velocity.x).to be_within(1e-9).of(-2.0)
    end

    it 'bounces rectangles off static rectangles by bounciness * velocity' do
      floor = Rubidium::RigidBody2d.new(Float::INFINITY, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, true)
      floor.collider = Rubidium::Collision::RectangleCollider.new(20.0, 2.0)

      box = Rubidium::RigidBody2d.new(2.0, Rubidium::Vector2.new(0.0, 1.8), 0.0, 0.0, false, 0.7)
      box.collider = Rubidium::Collision::RectangleCollider.new(2.0, 2.0)
      box.velocity = Rubidium::Vector2.new(1.5, -10.0)

      box.resolve_collision(floor)
      expect(box.position.y).to be_within(1e-9).of(2.0)
      expect(box.velocity.y).to be_within(1e-9).of(7.0)
      expect(box.velocity.x).to be_within(1e-9).of(1.5)
    end

    it 'bounces a circle off a rectangle corner along the analytic diagonal normal' do
      block = Rubidium::RigidBody2d.new(Float::INFINITY, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, true)
      block.collider = Rubidium::Collision::RectangleCollider.new(4.0, 2.0)

      # Corner at (2.0, 1.0); circle center at (2.3, 1.4) gives normal (0.6, 0.8)
      ball = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(2.3, 1.4), 0.0, 0.0, false, 0.5)
      ball.collider = Rubidium::Collision::CircleCollider.new(1.0)
      # Velocity purely inward along -normal: (-6, -8) -> speed 10 along -n
      ball.velocity = Rubidium::Vector2.new(-6.0, -8.0)

      ball.resolve_collision(block)
      # Pushed out along (0.6, 0.8) by 0.5 to (2.6, 1.8)
      expect(ball.position.x).to be_within(1e-9).of(2.6)
      expect(ball.position.y).to be_within(1e-9).of(1.8)
      # Outgoing velocity = +0.5 * 10 * (0.6, 0.8) = (3.0, 4.0)
      expect(ball.velocity.x).to be_within(1e-9).of(3.0)
      expect(ball.velocity.y).to be_within(1e-9).of(4.0)
    end

    it 'resolves dynamic-vs-dynamic equal-mass circle collisions for elastic, partial, and inelastic bounciness' do
      # Elastic (1.0): velocities swap
      a1 = Rubidium::RigidBody2d.new(2.0, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, false, 1.0)
      a1.collider = Rubidium::Collision::CircleCollider.new(1.0)
      a1.velocity = Rubidium::Vector2.new(6.0, 0.0)

      b1 = Rubidium::RigidBody2d.new(2.0, Rubidium::Vector2.new(1.5, 0.0), 0.0, 0.0, false, 1.0)
      b1.collider = Rubidium::Collision::CircleCollider.new(1.0)
      b1.velocity = Rubidium::Vector2.new(-2.0, 0.0)

      a1.resolve_collision(b1)
      expect(a1.position.x).to be_within(1e-9).of(-0.25)
      expect(b1.position.x).to be_within(1e-9).of(1.75)
      expect(a1.velocity.x).to be_within(1e-9).of(-2.0)
      expect(b1.velocity.x).to be_within(1e-9).of(6.0)

      # Partial (0.5): separation speed = 0.5 * approach speed, momentum conserved
      a2 = Rubidium::RigidBody2d.new(2.0, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, false, 0.5)
      a2.collider = Rubidium::Collision::CircleCollider.new(1.0)
      a2.velocity = Rubidium::Vector2.new(4.0, 0.0)

      b2 = Rubidium::RigidBody2d.new(2.0, Rubidium::Vector2.new(1.5, 0.0), 0.0, 0.0, false, 0.5)
      b2.collider = Rubidium::Collision::CircleCollider.new(1.0)
      b2.velocity = Rubidium::Vector2.new(0.0, 0.0)

      a2.resolve_collision(b2)
      expect(b2.velocity.x - a2.velocity.x).to be_within(1e-9).of(2.0)
      expect(a2.velocity.x + b2.velocity.x).to be_within(1e-9).of(4.0)

      # Inelastic (0.0): bodies match normal velocity
      a3 = Rubidium::RigidBody2d.new(2.0, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, false, 0.0)
      a3.collider = Rubidium::Collision::CircleCollider.new(1.0)
      a3.velocity = Rubidium::Vector2.new(4.0, 0.0)

      b3 = Rubidium::RigidBody2d.new(2.0, Rubidium::Vector2.new(1.5, 0.0), 0.0, 0.0, false, 0.0)
      b3.collider = Rubidium::Collision::CircleCollider.new(1.0)
      b3.velocity = Rubidium::Vector2.new(0.0, 0.0)

      a3.resolve_collision(b3)
      expect(a3.velocity.x).to be_within(1e-9).of(2.0)
      expect(b3.velocity.x).to be_within(1e-9).of(2.0)
    end

    it 'conserves momentum and weights displacement by inverse mass for unequal masses' do
      light = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, false, 1.0)
      light.collider = Rubidium::Collision::CircleCollider.new(1.0)
      light.velocity = Rubidium::Vector2.new(5.0, 0.0)

      heavy = Rubidium::RigidBody2d.new(3.0, Rubidium::Vector2.new(1.6, 0.0), 0.0, 0.0, false, 1.0)
      heavy.collider = Rubidium::Collision::CircleCollider.new(1.0)
      heavy.velocity = Rubidium::Vector2.new(-3.0, 0.0)

      initial_momentum = light.mass * light.velocity.x + heavy.mass * heavy.velocity.x
      light.resolve_collision(heavy)

      # Overlap 0.4 -> light moves -0.3, heavy moves +0.1
      expect(light.position.x).to be_within(1e-9).of(-0.3)
      expect(heavy.position.x).to be_within(1e-9).of(1.7)
      final_momentum = light.mass * light.velocity.x + heavy.mass * heavy.velocity.x
      expect(final_momentum).to be_within(1e-9).of(initial_momentum)
      expect(heavy.velocity.x - light.velocity.x).to be_within(1e-9).of(8.0)
    end

    it 'conserves 2D momentum and kinetic energy in a glancing elastic collision' do
      a = Rubidium::RigidBody2d.new(1.5, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, false, 1.0)
      a.collider = Rubidium::Collision::CircleCollider.new(1.0)
      a.velocity = Rubidium::Vector2.new(4.0, 3.0)

      b = Rubidium::RigidBody2d.new(2.5, Rubidium::Vector2.new(1.2, 0.9), 0.0, 0.0, false, 1.0)
      b.collider = Rubidium::Collision::CircleCollider.new(1.0)
      b.velocity = Rubidium::Vector2.new(-1.0, 2.0)

      px_before = a.mass * a.velocity.x + b.mass * b.velocity.x
      py_before = a.mass * a.velocity.y + b.mass * b.velocity.y
      ke_before = 0.5 * a.mass * (a.velocity.magnitude**2) + 0.5 * b.mass * (b.velocity.magnitude**2)

      a.resolve_collision(b)

      px_after = a.mass * a.velocity.x + b.mass * b.velocity.x
      py_after = a.mass * a.velocity.y + b.mass * b.velocity.y
      ke_after = 0.5 * a.mass * (a.velocity.magnitude**2) + 0.5 * b.mass * (b.velocity.magnitude**2)

      expect(px_after).to be_within(1e-9).of(px_before)
      expect(py_after).to be_within(1e-9).of(py_before)
      expect(ke_after).to be_within(1e-9).of(ke_before)
    end

    it 'separates overlapping bodies without flipping velocity if they are already moving apart' do
      floor = Rubidium::RigidBody2d.new(Float::INFINITY, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, true)
      floor.collider = Rubidium::Collision::RectangleCollider.new(10.0, 2.0)

      ball = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0.0, 1.2), 0.0, 0.0, false, 1.0)
      ball.collider = Rubidium::Collision::CircleCollider.new(0.5)
      ball.velocity = Rubidium::Vector2.new(0.0, 5.0)

      ball.resolve_collision(floor)
      expect(ball.position.y).to be_within(1e-9).of(1.5)
      expect(ball.velocity.y).to be_within(1e-9).of(5.0)
    end

    it 'supports standalone RigidBody2d#resolve_collisions with a SpatialHashmap' do
      wall = Rubidium::RigidBody2d.new(Float::INFINITY, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, true)
      wall.collider = Rubidium::Collision::RectangleCollider.new(10.0, 2.0)

      ball = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0.0, 1.4), 0.0, 0.0, false, 0.5)
      ball.collider = Rubidium::Collision::CircleCollider.new(0.5)
      ball.velocity = Rubidium::Vector2.new(0.0, -6.0)

      grid = Rubidium::SpatialHashmap.new(2.0)
      grid.build_hashmap([wall, ball])

      resolved = ball.resolve_collisions(grid)
      expect(resolved).to eq([wall])
      expect(ball.position.y).to be_within(1e-9).of(1.5)
      expect(ball.velocity.y).to be_within(1e-9).of(3.0)
    end

    it 'bounces a falling ball repeatedly upward across Scene2D#update ticks' do
      floor = Rubidium::RigidBody2d.new(Float::INFINITY, Rubidium::Vector2.new(0.0, 0.0), 0.0, 0.0, true)
      floor.collider = Rubidium::Collision::RectangleCollider.new(20.0, 2.0)

      ball = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0.0, 3.0), 0.0, 0.0, false, 0.8)
      ball.collider = Rubidium::Collision::CircleCollider.new(0.5)
      ball.add_linear_force(Rubidium::Vector2.new(0.0, -9.8))

      scene = described_class.new([floor, ball])
      dt = 1.0 / 60.0
      bounced_upward = false

      120.times do
        scene.update(dt)
        expect(ball.position.y).to be >= 1.5 - 1e-9
        bounced_upward = true if ball.velocity.y > 1.0
      end

      expect(bounced_upward).to be(true)
    end

    it 'blocks a chain of dynamic boxes pressed against a static wall without overlap' do
      wall = Rubidium::RigidBody2d.new(Float::INFINITY, Rubidium::Vector2.new(5.0, 0.0), 0.0, 0.0, true)
      wall.collider = Rubidium::Collision::RectangleCollider.new(2.0, 10.0)

      middle = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(3.6, 0.0), 0.0, 0.0, false, 0.0)
      middle.collider = Rubidium::Collision::RectangleCollider.new(2.0, 2.0)

      pusher = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(1.7, 0.0), 0.0, 0.0, false, 0.0)
      pusher.collider = Rubidium::Collision::RectangleCollider.new(2.0, 2.0)
      pusher.velocity = Rubidium::Vector2.new(5.0, 0.0)

      scene = described_class.new([wall, middle, pusher])
      scene.resolve_collisions

      expect(wall.position.x).to eq(5.0)
      expect(middle.position.x).to be_within(1e-6).of(3.0)
      expect(pusher.position.x).to be_within(1e-6).of(1.0)
      expect(middle.velocity.x).to be_within(1e-6).of(0.0)
      expect(pusher.velocity.x).to be_within(1e-6).of(0.0)
    end
  end
end
