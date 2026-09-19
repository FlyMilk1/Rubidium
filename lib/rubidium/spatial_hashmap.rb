# frozen_string_literal: true
module Rubidium
  require_relative 'hash_set'
  require_relative 'rigid_body_2d'
  require_relative 'collider'
  class SpatialHashmap
    def initialize(cell_size)
      @map = {}
      @cell_size = cell_size
    end

    def build_hashmap(objects)
      @map.clear
      objects.each do |obj|
        next unless obj.collider

        cells = get_cells(obj.position.x, obj.position.y, obj.collider)
        next unless cells

        cells.each do |cell_key|
          @map[cell_key] ||= []
          @map[cell_key] << obj
        end
      end
    end

    def get_broad_collided_objects(object)
      neighbors = HashSet.new
      cells = get_cells(object.position.x, object.position.y, object.collider)
      return neighbors unless cells

      cells.each do |cell_key|
        cell_objects = @map[cell_key]
        next unless cell_objects

        cell_objects.each do |other|
          next if other.equal?(object)

          neighbors.add(other)
        end
      end
      neighbors
    end
    private

    def get_cell_key(cell_x, cell_y)
      # Pack two 32-bit coords into one integer to avoid string allocations.
      (cell_x << 32) ^ (cell_y & 0xffffffff)
    end

    def get_cells(x, y, collider)
      cells = nil
      if collider.respond_to?(:radius)
        r = collider.radius
        min_cx = ((x - r) / @cell_size).floor
        max_cx = ((x + r) / @cell_size).floor
        min_cy = ((y - r) / @cell_size).floor
        max_cy = ((y + r) / @cell_size).floor
        min_cx.upto(max_cx) do |cx|
          min_cy.upto(max_cy) do |cy|
            cells ||= []
            cells << get_cell_key(cx, cy)
          end
        end
      elsif collider.respond_to?(:width) && collider.respond_to?(:height)
        w = collider.width / 2
        h = collider.height / 2
        min_cx = ((x - w) / @cell_size).floor
        max_cx = ((x + w) / @cell_size).floor
        min_cy = ((y - h) / @cell_size).floor
        max_cy = ((y + h) / @cell_size).floor
        min_cx.upto(max_cx) do |cx|
          min_cy.upto(max_cy) do |cy|
            cells ||= []
            cells << get_cell_key(cx, cy)
          end
        end
      end
      cells
    end

  end

end
