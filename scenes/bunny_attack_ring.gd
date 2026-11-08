extends MeshInstance3D

signal target_hit(body: Node3D)

@export var ray_count := 180
@export var max_range := 8.0
@export var ring_width := 2.0
@export var speed := 12.0
@export var ray_height := 0.5
@export var mesh_height := 0.03
@export var damage := 10
@export var hit_margin := 0.4
@export_flags_3d_physics var wall_mask := 1

var origin := Vector3.ZERO
var dists := PackedFloat32Array()
var colliders := []
var r_out := 0.0
var prev_r_in := 0.0
var active := false
var already_hit := false

func _ready() -> void:
	top_level = true

func start(from: Vector3, source: CollisionObject3D = null) -> void:
	origin = from
	global_position = from
	var space := get_world_3d().direct_space_state
	var ray_origin := from + Vector3.UP * ray_height

	var exclude: Array[RID] = []
	if source:
		exclude.append(source.get_rid())

	dists.resize(ray_count)
	colliders.clear()
	colliders.resize(ray_count)
	for i in ray_count:
		var angle := TAU * float(i) / ray_count
		var to := ray_origin + Vector3(cos(angle), 0, sin(angle)) * max_range
		var q := PhysicsRayQueryParameters3D.create(ray_origin, to, wall_mask)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit:
			dists[i] = ray_origin.distance_to(hit.position)
			colliders[i] = hit.collider
		else:
			dists[i] = max_range
			colliders[i] = null

	r_out = 0.0
	prev_r_in = 0.0
	already_hit = false
	active = true

func _physics_process(delta: float) -> void:
	if not active:
		return

	r_out += speed * delta
	if r_out - ring_width > max_range:
		active = false
		mesh = null
		return

	_rebuild_mesh(maxf(r_out - ring_width, 0.0), r_out)

	if not already_hit:
		var target = get_tree().current_scene.active_animal
		if is_instance_valid(target) and is_hit(target):
			already_hit = true
			target_hit.emit(target)
			print("hit something")
			if target.has_method("take_damage"):
				target.take_damage(damage)

	prev_r_in = maxf(r_out - ring_width, 0.0)

func _is_target(col: Object, target: Node3D) -> bool:
	return is_instance_valid(col) and (col == target or target.is_ancestor_of(col))

func is_hit(target: Node3D) -> bool:
	if not active:
		return false

	var off := Vector2(target.global_position.x - origin.x, target.global_position.z - origin.z)
	var dist := off.length()
	var step := TAU / ray_count
	var center := int(round(wrapf(off.angle(), 0.0, TAU) / step))
	var half := 1
	if dist > hit_margin:
		half = ceili(asin(hit_margin / dist) / step) + 1

	for k in range(-half, half + 1):
		var idx := posmod(center + k, ray_count)
		var wall_d := dists[idx]

		if _is_target(colliders[idx], target):
			if r_out >= wall_d:
				return true
		elif dist <= wall_d + hit_margin:
			if dist >= prev_r_in - hit_margin and dist <= r_out + hit_margin:
				return true
	return false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ring_test"):
		start(global_position)

func _rebuild_mesh(r_in: float, r_o: float) -> void:
	var verts := PackedVector3Array()
	var indices := PackedInt32Array()

	for i in ray_count:
		var j := (i + 1) % ray_count
		# obie sąsiednie krawędzie muszą być "otwarte", inaczej pomijamy kawałek
		if dists[i] <= r_in or dists[j] <= r_in:
			continue
		var a0 := TAU * float(i) / ray_count
		var a1 := TAU * float(j) / ray_count
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var o0 := minf(r_o, dists[i])
		var o1 := minf(r_o, dists[j])

		var base := verts.size()
		verts.append(d0 * r_in + Vector3.UP * mesh_height)
		verts.append(d0 * o0   + Vector3.UP * mesh_height)
		verts.append(d1 * r_in + Vector3.UP * mesh_height)
		verts.append(d1 * o1   + Vector3.UP * mesh_height)
		indices.append_array([base, base + 1, base + 2, base + 2, base + 1, base + 3])

	if verts.is_empty():
		mesh = null
		return

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = m
