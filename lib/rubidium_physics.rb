# frozen_string_literal: true

# The published gem is named "rubidium_physics" (plain "rubidium" is taken
# on rubygems.org), but the library entry point and Rubidium namespace stay
# as-is. Provide a same-name require so Bundler.require and
# `require 'rubidium_physics'` work as consumers expect.
require 'rubidium'
