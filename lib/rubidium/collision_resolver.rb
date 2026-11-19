# frozen_string_literal: true

require_relative 'vector2'
require_relative 'collider'

module Rubidium
  module Collision
    # Represents contact geometry for an overlapping pair of colliders.
    #
    # +normal+ is always a unit Vector2 pointing from +body_a+ toward +body_b+,
    # and +penetration+ is a positive Float overlap depth along that normal.
    class Manifold
      attr_reader :body_a, :body_b, :normal, :penetration

      def initialize(body_a, body_b, normal, penetration)
        @body_a = body_a
        @body_b = body_b
        @normal = normal
        @penetration = penetration
      end
    end

    # Computes analytic contact manifolds (normals + penetration depths) for
    # circle and rectangle colliders, and resolves positional overlap and
    # normal velocity impulse using body bounciness.
    class Resolver
      DEFAULT_ITERATIONS = 32
      POSITION_EPSILON = 1e-9

      class << self
        def compute_manifold(body_a, body_b)
          col_a = body_a.collider
          col_b = body_b.collider
          return nil unless col_a && col_b

          a_circle = col_a.respond_to?(:radius)
          b_circle = col_b.respond_to?(:radius)
          a_rect = col_a.respond_to?(:width) && col_a.respond_to?(:height)
          b_rect = col_b.respond_to?(:width) && col_b.respond_to?(:height)

          if a_circle && b_circle
            circle_vs_circle(body_a, body_b)
          elsif a_rect && b_rect
            rect_vs_rect(body_a, body_b)
          elsif (a_rect && b_circle) || (a_circle && b_rect)
            rect_vs_circle(body_a, body_b)
          end
        end

        def resolve(body_a, body_b)
          manifold = compute_manifold(body_a, body_b)
          return nil unless manifold

          resolve_manifold(manifold)
        end

        def resolve_manifold(manifold)
          body_a = manifold.body_a
          body_b = manifold.body_b
          inv_mass_a = inverse_mass(body_a)
          inv_mass_b = inverse_mass(body_b)
          inv_mass_sum = inv_mass_a + inv_mass_b
          return manifold if inv_mass_sum == 0.0

          nx = manifold.normal.x
          ny = manifold.normal.y

          # 100% positional projection weighted by inverse mass so colliding bodies block cleanly.
          pen = manifold.penetration
          ratio_a = inv_mass_a / inv_mass_sum
          ratio_b = inv_mass_b / inv_mass_sum
          if inv_mass_a > 0.0
            body_a.position.x -= nx * pen * ratio_a
            body_a.position.y -= ny * pen * ratio_a
          end
          if inv_mass_b > 0.0
            body_b.position.x += nx * pen * ratio_b
            body_b.position.y += ny * pen * ratio_b
          end

          # Apply restitution impulse only when bodies are approaching along the contact normal.
          rv_x = body_b.velocity.x - body_a.velocity.x
          rv_y = body_b.velocity.y - body_a.velocity.y
          vel_along_normal = rv_x * nx + rv_y * ny

          if vel_along_normal < 0.0
            restitution = [body_a.bounciness, body_b.bounciness].max
            impulse = -(1.0 + restitution) * vel_along_normal / inv_mass_sum

            if inv_mass_a > 0.0
              body_a.velocity.x -= impulse * inv_mass_a * nx
              body_a.velocity.y -= impulse * inv_mass_a * ny
            end
            if inv_mass_b > 0.0
              body_b.velocity.x += impulse * inv_mass_b * nx
              body_b.velocity.y += impulse * inv_mass_b * ny
            end
          end

          manifold
        end

        def resolve_all(bodies, spatial_hashmap: nil, cell_size: nil, iterations: DEFAULT_ITERATIONS)
          require_relative 'spatial_hashmap' unless defined?(Rubidium::SpatialHashmap)

          collidable = bodies.select(&:collider)
          return 0 if collidable.size < 2

          hashmap = spatial_hashmap || SpatialHashmap.new(cell_size || compute_cell_size(collidable))
          body_index = {}
          collidable.each_with_index { |b, i| body_index[b.object_id] = i }

          total_resolved = 0

          iterations.times do
            hashmap.build_hashmap(collidable)

            # Snapshot unordered broad-phase pairs before mutating positions in this pass.
            pairs = []
            collidable.each_with_index do |body, i|
              hashmap.get_broad_collided_objects(body).each do |other|
                j = body_index[other.object_id]
                next unless j && i < j

                pairs << [body, other]
              end
            end

            resolved_this_pass = false
            pairs.each do |body_a, body_b|
              next if inverse_mass(body_a) == 0.0 && inverse_mass(body_b) == 0.0

              manifold = resolve(body_a, body_b)
              next unless manifold

              total_resolved += 1
              resolved_this_pass = true if manifold.penetration > POSITION_EPSILON
            end

            break unless resolved_this_pass
          end

          total_resolved
        end

        private

        def circle_vs_circle(body_a, body_b)
          r_a = body_a.collider.radius.to_f
          r_b = body_b.collider.radius.to_f
          return nil if r_a <= 0.0 || r_b <= 0.0

          dx = body_b.position.x - body_a.position.x
          dy = body_b.position.y - body_a.position.y
          radius_sum = r_a + r_b
          dist_sq = dx * dx + dy * dy
          return nil if dist_sq >= radius_sum * radius_sum

          dist = Math.sqrt(dist_sq)
          if dist > 1e-12
            normal = Vector2.new(dx / dist, dy / dist)
            penetration = radius_sum - dist
          else
            normal = Vector2.new(1.0, 0.0)
            penetration = radius_sum
          end

          Manifold.new(body_a, body_b, normal, penetration)
        end

        def rect_vs_rect(body_a, body_b)
          a_w = body_a.collider.width.to_f
          a_h = body_a.collider.height.to_f
          b_w = body_b.collider.width.to_f
          b_h = body_b.collider.height.to_f
          return nil if a_w <= 0.0 || a_h <= 0.0 || b_w <= 0.0 || b_h <= 0.0

          dx = body_b.position.x - body_a.position.x
          dy = body_b.position.y - body_a.position.y
          overlap_x = (a_w / 2.0 + b_w / 2.0) - dx.abs
          overlap_y = (a_h / 2.0 + b_h / 2.0) - dy.abs
          return nil if overlap_x <= 0.0 || overlap_y <= 0.0

          if overlap_x < overlap_y
            normal = Vector2.new(dx < 0 ? -1.0 : 1.0, 0.0)
            penetration = overlap_x
          else
            normal = Vector2.new(0.0, dy < 0 ? -1.0 : 1.0)
            penetration = overlap_y
          end

          Manifold.new(body_a, body_b, normal, penetration)
        end

        def rect_vs_circle(body_a, body_b)
          a_is_rect = body_a.collider.respond_to?(:width) && body_a.collider.respond_to?(:height)
          rect_body = a_is_rect ? body_a : body_b
          circle_body = a_is_rect ? body_b : body_a

          half_w = rect_body.collider.width.to_f / 2.0
          half_h = rect_body.collider.height.to_f / 2.0
          radius = circle_body.collider.radius.to_f
          return nil if half_w <= 0.0 || half_h <= 0.0 || radius <= 0.0

          dx = circle_body.position.x - rect_body.position.x
          dy = circle_body.position.y - rect_body.position.y
          closest_x = dx.clamp(-half_w, half_w)
          closest_y = dy.clamp(-half_h, half_h)

          diff_x = dx - closest_x
          diff_y = dy - closest_y
          dist_sq = diff_x * diff_x + diff_y * diff_y
          return nil if dist_sq >= radius * radius

          # Compute normal pointing from rect_body toward circle_body.
          if dist_sq > 0.0
            dist = Math.sqrt(dist_sq)
            nx = diff_x / dist
            ny = diff_y / dist
            penetration = radius - dist
          else
            dist_to_x_edge = half_w - dx.abs
            dist_to_y_edge = half_h - dy.abs
            if dist_to_x_edge < dist_to_y_edge
              nx = dx < 0 ? -1.0 : 1.0
              ny = 0.0
              penetration = dist_to_x_edge + radius
            else
              nx = 0.0
              ny = dy < 0 ? -1.0 : 1.0
              penetration = dist_to_y_edge + radius
            end
          end

          normal = a_is_rect ? Vector2.new(nx, ny) : Vector2.new(-nx, -ny)
          Manifold.new(body_a, body_b, normal, penetration)
        end

        def inverse_mass(body)
          if body.static || body.mass.nil? || body.mass <= 0 ||
             (body.mass.respond_to?(:infinite?) && body.mass.infinite?)
            return 0.0
          end

          1.0 / body.mass.to_f
        end

        def compute_cell_size(bodies)
          extents = []
          bodies.each do |body|
            col = body.collider
            if col.respond_to?(:radius)
              r = col.radius.to_f
              extents << 2.0 * r if r > 0.0
            elsif col.respond_to?(:width) && col.respond_to?(:height)
              ext = [col.width.to_f, col.height.to_f].max
              extents << ext if ext > 0.0
            end
          end

          return 1.0 if extents.empty?

          avg_extent = extents.sum / extents.size
          max_extent = extents.max
          [avg_extent, max_extent / 16.0].max
        end
      end
    end
  end
end
