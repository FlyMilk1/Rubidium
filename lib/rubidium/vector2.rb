# frozen_string_literal: true
module Rubidium

  # Represents a 2D vector with x and y components.
  #
  # Provides operations for vector arithmetic including addition, subtraction,
  # multiplication, and division. Supports both vector-to-vector operations and
  # scalar operations. All non-mutating operations return new Vector2 instances,
  # while mutating operations modify the instance in-place.
  class Vector2
    # @return [Numeric] the x-component of the vector
    attr_accessor :x

    # @return [Numeric] the y-component of the vector
    attr_accessor :y

    # @x class variable for default x value
    @x = 0
    # @y class variable for default y value
    @y = 0

    # Initializes a new Vector2 with the given x and y components.
    #
    # @param x [Numeric] the x-component
    # @param y [Numeric] the y-component
    def initialize(x, y)
      @x = x
      @y = y
    end

    # Returns a string representation of the vector.
    #
    # @return [String] formatted string like "Vector2(x, y)"
    def to_s
      "Vector2(#{@x}, #{@y})"
    end

    # Compares this vector with another for equality.
    #
    # @param other [Vector2] the vector to compare
    # @return [Boolean] true if both x and y components are equal
    def ==(other)
      @x == other.x && @y == other.y
    end

    # Returns a new vector representing the sum of this vector and another.
    #
    # @param other [Vector2] the vector to add
    # @return [Vector2] a new vector with added components
    def +(other)
      Vector2.new(@x + other.x, @y + other.y)
    end

    # Returns a new vector representing the difference of this vector and another.
    #
    # @param other [Vector2] the vector to subtract
    # @return [Vector2] a new vector with subtracted components
    def -(other)
      Vector2.new(@x - other.x, @y - other.y)
    end

    # Returns a new vector with component-wise multiplication.
    #
    # @param other [Vector2] the vector to multiply by
    # @return [Vector2] a new vector with multiplied components
    def *(other)
      Vector2.new(@x * other.x, @y * other.y)
    end

    # Returns a new vector with component-wise division.
    #
    # @param other [Vector2] the vector to divide by
    # @return [Vector2] a new vector with divided components
    def /(other)
      Vector2.new(@x / other.x, @y / other.y)
    end

    # Adds the components of another vector or collection of vectors to this vector in-place.
    #
    # If a collection (anything responding to +each+) is provided, adds all vectors in it.
    # Otherwise, adds a single vector.
    #
    # @param other [Vector2, Array<Vector2>] the vector(s) to add
    # @return [void]
    def add(other)
      if other.respond_to?(:each)
        other.each do |v|
          @x += v.x
          @y += v.y
        end
        return
      end
      @x += other.x
      @y += other.y
    end

    # Subtracts the components of another vector or collection of vectors from this vector in-place.
    #
    # If a collection is provided, subtracts all vectors in it.
    # Otherwise, subtracts a single vector.
    #
    # @param other [Vector2, Array<Vector2>] the vector(s) to subtract
    # @return [void]
    def subtract(other)
      if other.respond_to?(:each)
        other.each do |v|
          @x -= v.x
          @y -= v.y
        end
        return
      end
      @x -= other.x
      @y -= other.y
    end

    # Multiplies the components of another vector or collection of vectors with this vector in-place.
    #
    # If a collection is provided, multiplies by all vectors in it.
    # Otherwise, multiplies by a single vector.
    #
    # @param other [Vector2, Array<Vector2>] the vector(s) to multiply by
    # @return [void]
    def multiply(other)
      if other.respond_to?(:each)
        other.each do |v|
          @x *= v.x
          @y *= v.y
        end
        return
      end
      @x *= other.x
      @y *= other.y
    end

    # Divides the components of this vector by another vector or collection of vectors in-place.
    #
    # If a collection is provided, divides by all vectors in it.
    # Otherwise, divides by a single vector.
    #
    # @param other [Vector2, Array<Vector2>] the vector(s) to divide by
    # @return [void]
    def divide(other)
      if other.respond_to?(:each)
        other.each do |v|
          @x /= v.x
          @y /= v.y
        end
        return
      end
      @x /= other.x
      @y /= other.y
    end

    # Adds a scalar value to both components of this vector in-place.
    #
    # @param scalar [Numeric] the scalar value to add
    # @return [void]
    def add_with_scalar(scalar)
      @x += scalar
      @y += scalar
    end

    # Subtracts a scalar value from both components of this vector in-place.
    #
    # @param scalar [Numeric] the scalar value to subtract
    # @return [void]
    def subtract_with_scalar(scalar)
      @x -= scalar
      @y -= scalar
    end

    # Multiplies both components of this vector by a scalar value in-place.
    #
    # @param scalar [Numeric] the scalar value to multiply by
    # @return [void]
    def multiply_with_scalar(scalar)
      @x *= scalar
      @y *= scalar
    end

    # Divides both components of this vector by a scalar value in-place.
    #
    # @param scalar [Numeric] the scalar value to divide by
    # @return [void]
    def divide_with_scalar(scalar)
      @x /= scalar
      @y /= scalar
    end
  end

end
