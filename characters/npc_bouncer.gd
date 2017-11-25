extends RigidBody2D

const MAX_HEALTH = 1000
var health = 1000
const BOUNCING_BASELINE = 500
var velocity = Vector2()
const GRAVITY = Vector2(0, 1000.0)
const MAX_FLOOR_ANGLE = deg2rad(5)
const VELOCITY_CONTROL_THRESHOLD = 1000
const VELOCITY_EXPLODE_THRESHOLD = 1300

var tween
var last_total_velocity = Vector2(0, 0)

signal spawn(object)

func _ready():
	contact_monitor = true
	contacts_reported = 5
	mode = MODE_CHARACTER

	tween = Tween.new()
	add_child(tween)

func _integrate_forces(state):
	var total_velocity = state.get_linear_velocity().length()
	
	if total_velocity > VELOCITY_CONTROL_THRESHOLD:
		mode = MODE_RIGID
	
	if state.get_contact_count() > 0 and last_total_velocity > VELOCITY_EXPLODE_THRESHOLD:
		despawn()
		return
	
	for i in range (state.get_contact_count()):
		if not state.get_contact_collider_object(i):
			continue
		var collider = state.get_contact_collider_object(i)
		var shouldJump = collider.has_method('get_cell_size') or collider is StaticBody2D
		if (state.get_contact_local_normal(i).dot(Vector2(0, -1)) >= cos(MAX_FLOOR_ANGLE) and shouldJump):
			var velocity_x = get_linear_velocity().x
			set_linear_velocity(Vector2(velocity_x, -BOUNCING_BASELINE))
	
	last_total_velocity = total_velocity

func hit_by_firebolt():
	take_damage(250)

func take_damage(num):
	health = health - num
	if health <= 0:
		despawn()

func despawn():
	spawn_explosion()
	disable_physics()
	
	tween.interpolate_property(self, "scale", Vector2(1, 1), Vector2(0.1, 0.1), 0.5, Tween.TRANS_BACK, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")
	queue_free()

func spawn_explosion():
	var explosion = preload("res://effects/explosion/explosion.tscn").instance()
	explosion.global_position = global_position
	emit_signal("spawn", explosion)

func disable_physics():
	linear_velocity = Vector2(0, 0)
	mode = MODE_STATIC
	$collision.disabled = true
	set_process(false)
	set_physics_process(false)