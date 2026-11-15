class_name Hitbox
extends Area3D
## A generous dart-catching volume around an Actor. Darts ray-cast against this
## (layer HITBOX) rather than the tight movement capsule, so hits feel fair.

var actor: Actor
