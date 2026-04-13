extends MeshInstance3D

## Trajectory arc tube mesh.
## Drop this node where the bow string lives; call fire() or set launch params.

@export var radius       : float   = 0.03
@export var rings        : int     = 32    # segments along the arc
@export var sides        : int     = 6     # vertices per cross-section ring
@export var gravity      : float   = 9.8
@export var max_distance : float   = 20.0  # clip arc at this world distance

var _array_mesh : ArrayMesh
var _arrays     : Array
var _launch_pos : Vector3 = Vector3.ZERO
var _launch_vel : Vector3 = Vector3.ZERO  # world-space m/s

# ── public API ────────────────────────────────────────────────────

## Call this from BowString when the player pulls and releases preview.
func update_trajectory(launch_velocity: Vector3) -> void:
	_launch_vel = launch_velocity
	_rebuild()

## Hide the arc (arrow has landed / was fired).
func hide_trajectory(power: float) -> void:
	visible = false

# ── lifecycle ─────────────────────────────────────────────────────

func _ready() -> void:
	# Pre-build mesh topology; vertices filled each update.
	_init_mesh()
	_update_vertices()

# ── mesh construction ──────────────────────────────────────────────

func _init_mesh() -> void:
	_array_mesh = ArrayMesh.new()
	_arrays     = []
	_arrays.resize(Mesh.ARRAY_MAX)

	var uvs  := PackedVector2Array()
	var idxs := PackedInt32Array()
	var vert_count := rings * sides

	uvs.resize(vert_count)
	for ring in rings:
		for s in sides:
			var i := ring * sides + s
			uvs[i] = Vector2(float(s) / sides, float(ring) / (rings - 1))

	# Tube quads between consecutive rings.
	for ring in rings - 1:
		var base := ring * sides
		for s in sides:
			var s1 := (s + 1) % sides
			idxs.append_array([
				base + s,      base + s1,      base + sides + s,
				base + s1,     base + sides + s1, base + sides + s
			])

	_arrays[Mesh.ARRAY_VERTEX]  = PackedVector3Array(); _arrays[Mesh.ARRAY_VERTEX].resize(vert_count)
	_arrays[Mesh.ARRAY_NORMAL]   = PackedVector3Array(); _arrays[Mesh.ARRAY_NORMAL].resize(vert_count)
	_arrays[Mesh.ARRAY_TEX_UV]   = uvs
	_arrays[Mesh.ARRAY_INDEX]    = idxs

func _rebuild() -> void:
	if not is_inside_tree() or _launch_vel.length_squared() < 0.001:
		visible = false
		return
	visible = true

	_update_vertices()
	_array_mesh.clear_surfaces()
	_array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)
	mesh = _array_mesh


func _update_vertices() -> void:
	var verts  := _arrays[Mesh.ARRAY_VERTEX]  as PackedVector3Array
	var norms  := _arrays[Mesh.ARRAY_NORMAL]   as PackedVector3Array

	# Sample the parabolic arc; stop early if it hits y == launch_pos.y (ground).
	var points := _sample_arc()

	for ring in rings:
		var center  : Vector3 = points[ring]
		var forward : Vector3

		if ring == 0:
			forward = (points[1] - points[0]).normalized()
		elif ring == rings - 1:
			forward = (points[rings - 1] - points[rings - 2]).normalized()
		else:
			forward = (points[ring + 1] - points[ring - 1]).normalized()

		_fill_ring(verts, norms, ring * sides, center, forward)

	_arrays[Mesh.ARRAY_VERTEX] = verts
	_arrays[Mesh.ARRAY_NORMAL] = norms

func _sample_arc() -> Array[Vector3]:
	var points: Array[Vector3] = []
	var vy: float = _launch_vel.y
	var horiz_speed: float = Vector3(_launch_vel.x, 0, _launch_vel.z).length()
	var dist_time: float = max_distance / max(horiz_speed, 0.001)
	var flight_time: float = (2.0 * vy / gravity) if vy > 0.001 else dist_time
	var total_time: float = min(flight_time, dist_time)
	for i in rings:
		var t: float = (float(i) / (rings - 1)) * total_time
		var world_p: Vector3 = _launch_vel * t + Vector3(0, -0.5 * gravity * t * t, 0)
		points.append(world_p)
	return points


func _fill_ring(verts: PackedVector3Array, norms: PackedVector3Array, offset: int, center: Vector3, forward: Vector3) -> void:
	var up := _stable_perpendicular(forward)
	var right := forward.cross(up).normalized()
	for i in sides:
		var angle := (float(i) / sides) * TAU
		var dir := right * cos(angle) + up * sin(angle)
		verts[offset + i] = center + dir * radius
		norms[offset + i] = dir


func _stable_perpendicular(v: Vector3) -> Vector3:
	if abs(v.x) <= abs(v.y) and abs(v.x) <= abs(v.z):
		return v.cross(Vector3.RIGHT).normalized()
	elif abs(v.y) <= abs(v.z):
		return v.cross(Vector3.UP).normalized()
	else:
		return v.cross(Vector3.BACK).normalized()
