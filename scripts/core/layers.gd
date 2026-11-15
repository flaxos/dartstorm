class_name Layers
extends RefCounted
## Physics layer bit values. Keep in sync with [layer_names] in project.godot.

const WORLD := 1      ## Static arena geometry (also what the navmesh is baked from).
const ACTORS := 2     ## Player and bot movement bodies.
const TARGETS := 4    ## Things that react to darts (wobble targets).
const PICKUPS := 8    ## Reserved for pickup bodies.
const HITBOX := 16    ## Forgiving dart hit volumes around actors (Area3D).

## What a live dart can hit.
const DART_MASK := WORLD | TARGETS | HITBOX
