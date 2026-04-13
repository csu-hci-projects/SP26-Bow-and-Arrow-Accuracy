@tool
class_name BowString
extends Area3D

@export var mesh_instance: MeshInstance3D:
	set(v): mesh_instance = v; _rebuild()

@export var top_tip: Node3D:
	set(v): top_tip = v; _rebuild()
@export var bottom_tip: Node3D:
	set(v): bottom_tip = v; _rebuild()
@export var target: Node3D:
	set(v): target = v; _rebuild()
@export var radius: float = 0.01:
	set(v): radius = v; _rebuild()

@export var max_pull: float = 1.5

var _array_mesh: ArrayMesh
var _arrays: Array

signal pull(distance: float)
signal release(power: float)

func _ready() -> void:
	_rebuild()

func _process(_delta: float) -> void:
	if top_tip and bottom_tip and is_inside_tree():
		_update_vertices()
		
	if target:
		pull.emit(clamp(get_pull_distance() / max_pull, 0, 1))

func _rebuild() -> void:
	if not top_tip or not bottom_tip or not is_inside_tree():
		return

	_array_mesh = ArrayMesh.new()
	_arrays = []
	_arrays.resize(Mesh.ARRAY_MAX)

	# 3 rings x 4 verts = 12 verts, indices never change
	var uvs  := PackedVector2Array()
	var idxs := PackedInt32Array()
	uvs.resize(12)
	for i in range(12):
		uvs[i] = Vector2(float(i % 4) / 4.0, float(i / 4) / 2.0)
	for ring in range(2):       # 2 segments between 3 rings
		var base := ring * 4
		for i in range(4):
			var i1 := (i + 1) % 4
			idxs.append_array([base+i, base+i1, base+4+i, base+i1, base+4+i1, base+4+i])

	_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	_arrays[Mesh.ARRAY_VERTEX].resize(12)
	_arrays[Mesh.ARRAY_TEX_UV] = uvs
	_arrays[Mesh.ARRAY_INDEX]  = idxs

	_array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)
	mesh_instance.mesh = _array_mesh
	_update_vertices()

func _update_vertices() -> void:
	var top  := to_local(top_tip.global_position)
	var bot  := to_local(bottom_tip.global_position)
	var pull := Vector3.ZERO
	
	if target:
		pull = to_local(target.global_position)
	else:
		pull = to_local((top_tip.global_position + bottom_tip.global_position) / 2)

	var verts := PackedVector3Array()
	verts.resize(12)
	_fill_ring(verts, 0, top,  (pull - top).normalized())
	_fill_ring(verts, 4, pull, (bot  - top).normalized())
	_fill_ring(verts, 8, bot,  (bot  - pull).normalized())

	_arrays[Mesh.ARRAY_VERTEX] = verts
	_array_mesh.clear_surfaces()
	_array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)

func _fill_ring(verts: PackedVector3Array, offset: int, center: Vector3, forward: Vector3) -> void:
	var up    := _stable_perpendicular(forward)
	var right := forward.cross(up).normalized()
	var corners := [right, up, -right, -up]
	for i in range(4):
		verts[offset + i] = center + corners[i] * radius

func _stable_perpendicular(v: Vector3) -> Vector3:
	if abs(v.x) <= abs(v.y) and abs(v.x) <= abs(v.z):
		return v.cross(Vector3.RIGHT).normalized()
	elif abs(v.y) <= abs(v.z):
		return v.cross(Vector3.UP).normalized()
	else:
		return v.cross(Vector3.BACK).normalized()


func on_grabbed(_target: Node3D):
	target = _target


func on_released(_target: Node3D):
	release.emit(clamp(get_pull_distance() / max_pull, 0, 1))
	target = null


func get_pull_distance() -> float:
	var mid_point = to_local((top_tip.global_position + bottom_tip.global_position) / 2)
	var target_point = to_local(target.global_position)
	return target_point.distance_to(mid_point)
