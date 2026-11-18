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
end

RSpec.describe Rubidium::Scene2D do
  it 'initializes with an empty rigid_bodies list by default' do
    scene = described_class.new
    expect(scene.rigid_bodies).to eq([])
  end

  it 'calls update on every rigid body in update / Update' do
    b1 = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(0, 0), 0.0)
    b1.add_linear_force(Rubidium::Vector2.new(0, -10.0))
    b2 = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(5, 0), 0.0)
    b2.add_linear_force(Rubidium::Vector2.new(2.0, 0))

    scene = described_class.new([b1, b2])
    scene.Update(0.5)

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

    ball = Rubidium::RigidBody2d.new(2.5, Rubidium::Vector2.new(1.5, 4.0), 0.25, 0.1, false)
    ball.velocity = Rubidium::Vector2.new(3.0, -1.0)
    ball.acceleration = Rubidium::Vector2.new(0.0, -9.8)
    ball.angular_velocity = 0.5
    ball.angular_acceleration = 0.02
    ball.collider = Rubidium::Collision::CircleCollider.new(0.75)

    plain = Rubidium::RigidBody2d.new(1.0, Rubidium::Vector2.new(5, 5), 0.0)

    scene = described_class.new([ground, ball, plain])

    Tempfile.create(['scene', '.json']) do |file|
      scene.save(file.path)
      loaded = described_class.load(file.path)

      expect(loaded).to be_a(described_class)
      expect(loaded.rigid_bodies.size).to eq(3)

      loaded_ground, loaded_ball, loaded_plain = loaded.rigid_bodies

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
      expect(loaded_ball.collider).to be_a(Rubidium::Collision::CircleCollider)
      expect(loaded_ball.collider.radius).to eq(0.75)

      expect(loaded_plain.collider).to be_nil

      # Verify static body stays put and dynamic body updates after loading
      loaded.update(0.1)
      expect(loaded_ground.position).to eq(Rubidium::Vector2.new(0, -10))
      expect(loaded_ball.position.x).to be_within(1e-9).of(1.8)

      # Verify instance-level load replaces rigid_bodies
      empty_scene = described_class.new
      empty_scene.load(file.path)
      expect(empty_scene.rigid_bodies.size).to eq(3)
    end
  end
end
