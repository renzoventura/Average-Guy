extends KinematicBody2D

enum States {CHASE, ATTACK, HURT, STOP, IDLE}
enum SoundEffects {ATTACK, HURT, DEATH, BIGSTEP}

const levels = [0,1,2]
const list_of_speed = [10, 5, 5]
const list_of_max_speed = [650, 450, 150]
const list_of_scales = [1.0, 1.5, 5]
const number_of_lives = [0, 1, 4]

const JUMP_SPEED = 1800;
const GRAVITY = 700;
const MAX_FALL_SPEED = 3000
const ACCELERATION = 5
const HURT_JUMP_SPEED = -30
const ATTACK_RANGE = 100
const HURT_SPEED = 1000

var SPEED = 5;
var MAX_SPEED = 600
var motion = Vector2(0,0)
var motion_up = Vector2(0,-1)
var current_speed = 10;
var life
var rng = RandomNumberGenerator.new()
var damage_direction = 1
var player
var state = null
var direction
var scale_value

var attack_sfx = load("res://Assets/sfx/enemy_attack.wav")
var hurt_sfx = load("res://Assets/sfx/enemy_hurt.wav")
var death_sfx = load("res://Assets/sfx/enemy_death.wav")
var big_step_sfx = load("res://Assets/sfx/big_step.wav")

onready var hurt_timer = $HurtTimer
onready var death_timer = $DeathTimer
onready var attack_timer = $AttackTimer
onready var enemy_sfx = $EnemySFX

var level

func init_boss():
	level = levels[-1]

func _ready():
	set_physics_process(true)
	if(level == null):
		rng.randomize()
		level= rng.randi_range(0, 1)
	set_params(level)
	state = States.CHASE
	modulate = Color(1,1,1)

func set_params(value):
	scale_value = list_of_scales[value]
	scale = Vector2(scale_value, scale_value)
	life = number_of_lives[value]
	SPEED = list_of_speed[value]
	MAX_SPEED = list_of_max_speed[value]

func _physics_process(delta):
	update_text()
	apply_gravity()
	if state == States.STOP:
		stop()
	elif state == States.IDLE:
		detect_if_within_attacking_range()
	else:
		animate()
		get_direction()
		if state == States.CHASE:
			disableAtttackCollision()
			if player != null:
				detect_if_within_attacking_range()
				chase_player(delta)
		if state == States.ATTACK:
			attack()
		if state == States.HURT:
			damaged()
		flip_node()
		move_and_slide(motion)

func stop():
	pass

func change_state(new_state):
	if new_state == state:
		return
	if new_state == States.ATTACK:
		pass
	if new_state == States.CHASE:
		pass
	if new_state == States.HURT:
		pass
	if new_state == States.IDLE:
		pass
	state = new_state

func get_direction():
	player = get_tree().get_root().find_node("Player", true, false)
	direction = (player.global_position - global_position)

func chase_player(delta):
	var enemyDirection = 1
	if(global_position > player.global_position):
		enemyDirection = -1
	if(current_speed <= MAX_SPEED):
		current_speed += SPEED
	motion.x = current_speed * enemyDirection

func detect_if_within_attacking_range():
	var distance_to_player = global_position.distance_to(player.global_position)
	if(distance_to_player < (ATTACK_RANGE * scale.x)):
		change_state(States.ATTACK)
	else: 
		change_state(States.CHASE)

func _on_VisibilityNotifier2D_screen_entered():
	set_physics_process(true)

func damaged():
	motion.x = 0
	if(hurt_timer.is_stopped()):
		hurt_timer.start()
	if(state != States.STOP):
		$Sprite/AnimationPlayer.play("Hurt")

func hurt(var is_facing_right):
	die()
	if(hurt_timer.is_stopped() and state != States.STOP and state != States.HURT and life > 0):
		life -= 1
		if(scale.x != list_of_scales[-1]):
			$Sprite/AnimationPlayer.stop()
			if(is_facing_right):
				damage_direction = 1
			else: 
				damage_direction = -1
			motion.x = HURT_SPEED * damage_direction
			motion.y = HURT_JUMP_SPEED
			change_state(States.HURT)
		else:
			$StaggerAnimation.play("Stagger")

func apply_gravity():
	if is_on_floor() and motion.y > 0: 
		motion.y = 0
	elif is_on_ceiling():
		motion.y = 1
	else:
		if(motion.y < MAX_FALL_SPEED):
			motion.y += GRAVITY

func animate():
	if motion.x != 0:
		$Sprite/AnimationPlayer.play("Walk")

func die():
	if(life <= 0 and state != States.STOP):
		get_tree().call_group("GameState", "updateKills")
		change_state(States.STOP)
		death_timer.start()
		play_sound(SoundEffects.DEATH)
		$Sprite/AnimationPlayer.play("Dead")

func attack():
	clear_motion_x()
	if(attack_timer.is_stopped()):
		attack_timer.start()
	$Sprite/AnimationPlayer.play("Attack")

func applyAttackCollision():
	$Weapon/WeaponArea/WeaponAttackShape.disabled = false
	
func disableAtttackCollision():
	$Weapon/WeaponArea/WeaponAttackShape.disabled = true
	
func clear_motion_x():
	motion.x = 0

func _on_DeathTimer_timeout():
	queue_free()

func update_text():
	$Label.text = States.keys()[state]

func _on_HurtTimer_timeout():
	if(state != States.STOP):
		change_state(States.IDLE)
	else: 
		change_state(States.STOP)

func _on_AttackTimer_timeout():
	if(state != States.STOP):
		change_state(States.IDLE)
		flip_node()
	else: 
		change_state(States.STOP)

func flip_node():
	$Sprite.flip_h = global_position > player.global_position
	$Weapon.rotation = direction.angle()

func _on_WeaponArea_body_entered(body):
	body.hurt($Sprite.flip_h, self)

func play_sound(sfx):
	if (sfx == SoundEffects.ATTACK):
		enemy_sfx.stream = attack_sfx
	elif (sfx == SoundEffects.HURT):
		enemy_sfx.stream = hurt_sfx
	elif (sfx == SoundEffects.DEATH):
		enemy_sfx.stream = death_sfx
	elif(sfx == SoundEffects.BIGSTEP):
		enemy_sfx.stream = big_step_sfx
	enemy_sfx.play()

func play_attack_sfx():
	play_sound(SoundEffects.ATTACK)
	shake_camera()
	
func play_hurt_sfx():
	play_sound(SoundEffects.HURT)

func stagger(isLeft):
	if (life >= 1):
		hurt(isLeft)
	else:
		change_state(States.HURT)
		if(isLeft):
			motion.x = -20000
		else:
			motion.x = 20000

func shake_camera():
	if (scale.x == list_of_scales[-1] and scale.y == list_of_scales[-1]):
		get_tree().call_group("Player", "shake_camera")

func play_big_step_sfx():
	if (scale.x == list_of_scales[-1] and scale.y == list_of_scales[-1]):
		play_sound(SoundEffects.BIGSTEP)

func shake_and_step():
	play_big_step_sfx()
	shake_camera()

func disable():
	change_state(States.STOP)
