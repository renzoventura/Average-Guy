extends KinematicBody2D

enum States {IDLE, HURT, SHIELD, DASH, DEAD}
enum SoundEffects {ATTACK, HURT, SHIELD, DEATH, BLOCKED, DASH}
var currentState = States.IDLE
var is_attacking
var is_facing_right
var motion = Vector2(0,0)
var motion_up = Vector2(0,-1)
var SPEED = 800;
var JUMP_SPEED = 2500;
var GRAVITY = 200;
var MAX_FALL_SPEED = 1200
var lives = 5
var KNOCK_BACK_SPEED = 500
var shake_amount = 20

onready var leftAttackArea = $AttackArea
onready var leftAttackAreaCollision = $AttackArea/AttackCollision
onready var rightAttackArea = $AttackArea2
onready var rightAttackAreaCollision = $AttackArea2/AttackCollision
onready var animationPlayer = $Sprite/AnimationPlayer
onready var player_sfx = $PlayerSFX
onready var dash_timer = $DashTimer
onready var death_timer = $DeathTimer
onready var player_sprite = $Sprite

var attack_sfx = load("res://Assets/sfx/player_attack.wav")
var hurt_sfx = load("res://Assets/sfx/player_hurt.wav")
var shield_sfx = load("res://Assets/sfx/shield.wav")
var blocked_sfx = load("res://Assets/sfx/blocked.wav")
var dash_sfx = load("res://Assets/sfx/dash.wav")
signal animate
signal attackAnimate
signal hurtAnimate
signal shieldAnimate
signal dashAnimate
signal deadAnimate
onready var camera = $Camera2D

func _ready():
	BackgroundMusic.play_game_music()
	lives = 5
	is_facing_right = true;
	is_attacking = false;
	currentState = States.IDLE
	update_gui()
	
func _process(delta):
	apply_gravity()
	if currentState == States.IDLE:
		if not is_attacking:
			walk()
			animate()
#			jump()
			attack()
			dash()
			shield()
	elif currentState == States.HURT:
		damaged()
	elif currentState == States.SHIELD:
		use_shield()
	elif currentState == States.DASH:
		dashing()
	elif currentState == States.DEAD:
		dying()
	move_and_slide(motion, motion_up)

func walk():
	if Input.is_action_pressed("left") and not Input.is_action_just_pressed("right"):
		motion.x = -SPEED
		is_facing_right = false
	elif Input.is_action_pressed("right") and not Input.is_action_just_pressed("left"):
		motion.x = SPEED
		is_facing_right = true
	else:
		motion.x = 0
		
func apply_gravity():
	if is_on_floor() and motion.y > 0: 
		motion.y = 0
	elif is_on_ceiling():
		motion.y = 1
	else:
		if(motion.y < MAX_FALL_SPEED):
			motion.y += GRAVITY

func jump():
	if Input.is_action_pressed("jump") and is_on_floor():
		motion.y -= JUMP_SPEED
		
func attack():
	if Input.is_action_just_pressed("attack") and not Input.is_action_just_pressed("shield"):
		is_attacking = true
		if(is_facing_right):
			leftAttackAreaCollision.disabled = false
		else:
			rightAttackAreaCollision.disabled = false
		motion.x = 0
		play_sound(SoundEffects.ATTACK)
		animateAttack()
		yield(get_node("Sprite/AnimationPlayer"), "animation_finished")
		is_attacking = false
		leftAttackAreaCollision.disabled = true
		rightAttackAreaCollision.disabled = true

func _on_AttackArea_body_entered(body):
	body.hurt(is_facing_right)

func _on_AttackArea2_body_entered(body):
	body.hurt(is_facing_right)

func dash():
	if Input.is_action_just_pressed("dash"):
		change_state(States.DASH)
		play_sound(SoundEffects.DASH)
		dash_timer.start()

func animate():
	emit_signal("animate", motion, is_facing_right)

func animateAttack():
	emit_signal("attackAnimate")

func animateHurt():
	emit_signal("hurtAnimate")

func hurt(isLeft, caller):
	if(currentState != States.SHIELD):
		play_sound(SoundEffects.HURT)
		lives = lives - 1
		update_gui()
		if(isLeft):
			motion.x = -KNOCK_BACK_SPEED
		else:
			motion.x = KNOCK_BACK_SPEED
		change_state(States.HURT)
	else: 
		play_sound(SoundEffects.BLOCKED)
		caller.stagger(isLeft)

func checkIfDead():
	if(lives <= 0):
		death_timer.start()
		dash_timer.stop()
		change_state(States.DEAD)

func damaged():
	animateHurt()
	checkIfDead()

func animationFinished():
	change_state(States.IDLE)

func knockBack():
	motion.x = 200
	
func change_state(new_state):
	if new_state == currentState:
		return
	if new_state == States.HURT:
		pass
	if new_state == States.IDLE:
		pass
	if new_state == States.DASH:
		pass
	if new_state == States.DEAD:
		pass
	currentState = new_state

func update_gui():
	get_tree().call_group("GameState", "updateLives", lives)
	
func shield():
	if Input.is_action_just_pressed("shield") and not Input.is_action_just_pressed("attack"):
		motion.x = 0
		play_sound(SoundEffects.SHIELD)
		change_state(States.SHIELD)

func use_shield():
	emit_signal("shieldAnimate")

func play_sound(sfx):
	if (sfx == SoundEffects.ATTACK):
		player_sfx.stream = attack_sfx
	elif (sfx == SoundEffects.HURT):
		player_sfx.stream = hurt_sfx
	elif (sfx == SoundEffects.SHIELD):
		player_sfx.stream = shield_sfx
	elif (sfx == SoundEffects.DEATH):
		pass
	elif(sfx == SoundEffects.BLOCKED):
		player_sfx.stream = blocked_sfx
	elif(sfx == SoundEffects.DASH):
		player_sfx.stream = dash_sfx
	player_sfx.play()

func dashing():
	emit_signal("dashAnimate")
	if(is_facing_right):
		motion.x = 2000
	else: 
		motion.x = -2000
	pass

func _on_DashTimer_timeout():
	change_state(States.IDLE)

func shake_camera():
	camera.set_offset(Vector2(rand_range(-1.0, 1.0) * shake_amount, rand_range(-1.0, 1.0) * shake_amount))

func dying():
	motion.x = 0
	BackgroundMusic.set_pitch(true)
	emit_signal("deadAnimate")
	get_tree().call_group("Enemy", "disable")

func _on_DeathTimer_timeout():
	get_tree().call_group("GameState", "playerDied")

func disable():
	player_sprite.visible = false

