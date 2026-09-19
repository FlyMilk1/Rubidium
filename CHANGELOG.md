# Changelog

## [Unreleased]

## [0.1.1] - 2026-09-19

### Fixed

- `Vector2#subtract` / `#multiply` / `#divide` now accept a collection of vectors without raising (`#add` already did).
- `RigidBody2d#narrow_collision_check` now detects circle-vs-rectangle collisions correctly when the rectangle is not at the world origin, in both argument orders.
- `RigidBody2d#get_collided_objects` no longer raises when broad-phase candidates exist (called `#map`/`#select` on a `HashSet`).

## [0.1.0] - 2026-09-19

### Added

- Initial gem packaging: `rubidium` gem, all classes namespaced under `Rubidium`.
