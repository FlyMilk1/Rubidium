# frozen_string_literal: true
module Rubidium

  # Minimal Hash-backed set for environments without Ruby's stdlib Set.
  class HashSet
    def initialize
      @store = {}
    end

    def add(value)
      @store[value] = true
      self
    end

    def include?(value)
      @store.key?(value)
    end

    def each(&block)
      return enum_for(:each) unless block

      @store.each_key(&block)
    end

    def to_a
      @store.keys
    end

    def size
      @store.size
    end

    def empty?
      @store.empty?
    end

    def any?(&block)
      return !@store.empty? unless block

      @store.each_key.any?(&block)
    end

    def clear
      @store.clear
      self
    end

    def delete(value)
      @store.delete(value)
      self
    end

    def length
      @store.length
    end
  end
end
