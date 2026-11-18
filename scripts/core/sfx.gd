extends Node
## Autoload "Sfx": DARTSTORM's whole soundtrack, generated in code. There are
## zero audio files and nothing to licence (DECISIONS D-005).
##
## * Sound effects are synthesised at startup and played on pooled voices
##   routed to the "SFX" bus.
## * Two music loops (menu and match) are rendered on a worker thread so startup
##   doesn't stall, then played on the "Music" bus. play_music() before a loop
##   is ready simply starts it as soon as it is.
## * quit_game() is the only way the game should quit (it stops sounds first so
##   nothing leaks at exit).

const MIX_RATE := 22050
const FLAT_VOICES := 12
const SPATIAL_VOICES := 16
const MIN_REPEAT_MSEC := 22
## How long quit_game() waits for stopped sounds to be released. A stopped sound
## is only freed after the audio thread has done a couple of mixing passes, and
## the headless (dummy) audio driver mixes in ~46 ms chunks. 0.15 s leaked about
## one run in four; 0.4 s is invisible to a player clicking Quit.
const QUIT_DRAIN_SECONDS := 0.4
const SFX_BUS := &"SFX"
const MUSIC_BUS := &"Music"
const MUSIC_FADE_SECONDS := 0.6
## How much quieter the music gets while the game is paused.
const MUSIC_DUCK_DB := -9.0

enum Wave { SINE, SQUARE, SAW, TRIANGLE, PULSE }


## A music loop being rendered on a worker thread.
class MusicJob extends RefCounted:
	var id: StringName
	var style: Dictionary
	var samples: PackedFloat32Array
	var done: bool = false
	var task_id: int = -1
	var waited: bool = false


var _streams: Dictionary = {}
var _flat: Array[AudioStreamPlayer] = []
var _spatial: Array[AudioStreamPlayer3D] = []
var _flat_index := 0
var _spatial_index := 0
var _last_played: Dictionary = {}
var _spin: AudioStreamPlayer
var _quitting: bool = false

var _music: AudioStreamPlayer
var _music_streams: Dictionary = {}
var _music_jobs: Array[MusicJob] = []
var _wanted_music: StringName = &""
var _current_music: StringName = &""
var _music_tween: Tween
var _ducked: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The window's close button goes through quit_game() too.
	get_tree().auto_accept_quit = false
	_build_bank()
	for i in FLAT_VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = SFX_BUS
		add_child(voice)
		_flat.append(voice)
	for i in SPATIAL_VOICES:
		var voice3d := AudioStreamPlayer3D.new()
		voice3d.unit_size = 7.0
		voice3d.max_distance = 70.0
		voice3d.bus = SFX_BUS
		add_child(voice3d)
		_spatial.append(voice3d)
	_spin = AudioStreamPlayer.new()
	_spin.stream = _streams[&"spin"]
	_spin.volume_db = -9.0
	_spin.bus = SFX_BUS
	add_child(_spin)
	_music = AudioStreamPlayer.new()
	_music.bus = MUSIC_BUS
	add_child(_music)
	_start_music_job(&"menu", _menu_style())
	_start_music_job(&"match", _match_style())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()


func _exit_tree() -> void:
	stop_all()
	_wait_for_music_jobs()


func _process(_delta: float) -> void:
	for job in _music_jobs:
		if job.done and not job.waited:
			WorkerThreadPool.wait_for_task_completion(job.task_id)
			job.waited = true
			_music_streams[job.id] = _make_stream(job.samples, true)
			job.samples = PackedFloat32Array()
			if _wanted_music == job.id:
				_switch_music(job.id)


# --- Effects ----------------------------------------------------------------

## Plays a non-positional sound (the player's own actions and UI).
func play(id: StringName, pitch: float = 1.0, volume_db: float = 0.0, jitter: float = 0.0) -> void:
	if not _can_play(id):
		return
	var voice := _flat[_flat_index]
	_flat_index = (_flat_index + 1) % _flat.size()
	voice.stream = _streams[id]
	voice.pitch_scale = maxf(pitch + randf_range(-jitter, jitter), 0.05)
	voice.volume_db = volume_db
	voice.play()


## Plays a sound positioned in the 3D world (bots, impacts, pickups).
func play_at(id: StringName, at: Vector3, pitch: float = 1.0, volume_db: float = 0.0, jitter: float = 0.0) -> void:
	if not _can_play(id):
		return
	var voice := _spatial[_spatial_index]
	_spatial_index = (_spatial_index + 1) % _spatial.size()
	voice.stream = _streams[id]
	voice.global_position = at
	voice.pitch_scale = maxf(pitch + randf_range(-jitter, jitter), 0.05)
	voice.volume_db = volume_db
	voice.play()


## Drives the Chainstorm barrel whine. ratio 0 stops it, 1 is full speed.
func set_spin(ratio: float) -> void:
	if ratio <= 0.01:
		if _spin.playing:
			_spin.stop()
		return
	_spin.pitch_scale = lerpf(0.45, 1.7, clampf(ratio, 0.0, 1.0))
	_spin.volume_db = lerpf(-20.0, -8.0, clampf(ratio, 0.0, 1.0))
	if not _spin.playing:
		_spin.play()


func has_sound(id: StringName) -> bool:
	return _streams.has(id)


func stop_all() -> void:
	for voice in _flat:
		voice.stop()
	for voice3d in _spatial:
		voice3d.stop()
	if _spin != null:
		_spin.stop()
	if _music != null:
		_music.stop()


## The one way the game should quit: silence everything, give the audio thread
## a moment (real time, not frames: headless runs frames far faster) to release
## the stopped sounds, then exit. Quitting while a sound is still fading out
## leaks its playback object, and Godot warns about it at exit.
## Safe to call more than once: only the first call counts.
func quit_game(exit_code: int = 0) -> void:
	if _quitting:
		return
	_quitting = true
	stop_all()
	_wait_for_music_jobs()
	await get_tree().create_timer(QUIT_DRAIN_SECONDS, true, false, true).timeout
	get_tree().quit(exit_code)


# --- Music ------------------------------------------------------------------

## Starts (or crossfades to) a music loop: &"menu" or &"match".
func play_music(id: StringName) -> void:
	_wanted_music = id
	if _music_streams.has(id):
		_switch_music(id)


func stop_music() -> void:
	_wanted_music = &""
	_current_music = &""
	_fade_music_to(-50.0, MUSIC_FADE_SECONDS, true)


## Pause screens make the music quieter rather than stopping it.
func duck_music(ducked: bool) -> void:
	if _ducked == ducked:
		return
	_ducked = ducked
	if _music.playing:
		_fade_music_to(MUSIC_DUCK_DB if ducked else 0.0, 0.25, false)


func is_music_ready(id: StringName) -> bool:
	return _music_streams.has(id)


func current_music() -> StringName:
	return _current_music


func music_length(id: StringName) -> float:
	var stream := _music_streams.get(id) as AudioStreamWAV
	return stream.get_length() if stream != null else 0.0


func _switch_music(id: StringName) -> void:
	if _current_music == id and _music.playing:
		return
	_current_music = id
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music.stream = _music_streams[id]
	_music.volume_db = -30.0
	_music.play()
	_fade_music_to(MUSIC_DUCK_DB if _ducked else 0.0, MUSIC_FADE_SECONDS, false)


func _fade_music_to(volume_db: float, seconds: float, stop_after: bool) -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", volume_db, seconds)
	if stop_after:
		_music_tween.tween_callback(_music.stop)


func _start_music_job(id: StringName, style: Dictionary) -> void:
	var job := MusicJob.new()
	job.id = id
	job.style = style
	job.task_id = WorkerThreadPool.add_task(Sfx._render_job.bind(job), false, "DARTSTORM music %s" % id)
	_music_jobs.append(job)


func _wait_for_music_jobs() -> void:
	for job in _music_jobs:
		if not job.waited and job.task_id >= 0:
			WorkerThreadPool.wait_for_task_completion(job.task_id)
			job.waited = true


static func _render_job(job: MusicJob) -> void:
	job.samples = _render_track(job.style)
	job.done = true


## Upbeat match loop: 140 BPM, C-G-Am-F, pulse-wave lead, punchy drums.
static func _match_style() -> Dictionary:
	return {
		"bpm": 140.0,
		"chords": [[48, 52, 55], [43, 47, 50], [45, 48, 52], [41, 45, 48], [48, 52, 55], [43, 47, 50], [41, 45, 48], [43, 47, 50]],
		"bass_steps": [0, 2, 4, 6, 8, 10, 12, 14],
		"bass_offsets": [0, 0, 12, 0, 0, 12, 0, 7],
		"stabs": true,
		"pad": false,
		"kick_steps": [0, 8, 10],
		"snare_steps": [4, 12],
		"hat_steps": [0, 2, 4, 6, 8, 10, 12, 14],
		"lead_wave": Wave.PULSE,
		"lead_volume": 0.12,
		"melody": [
			[[0, 2, 76], [2, 2, 79], [4, 2, 81], [6, 2, 79], [8, 4, 76], [12, 4, 72]],
			[[0, 2, 74], [2, 2, 76], [4, 4, 79], [8, 2, 74], [10, 2, 71], [12, 4, 74]],
			[[0, 2, 72], [2, 2, 76], [4, 4, 81], [8, 2, 79], [10, 2, 76], [12, 4, 69]],
			[[0, 2, 69], [2, 2, 72], [4, 4, 77], [8, 2, 76], [10, 2, 72], [12, 4, 74]],
			[[0, 2, 76], [2, 2, 79], [4, 2, 81], [6, 2, 79], [8, 4, 76], [12, 4, 72]],
			[[0, 2, 74], [2, 2, 76], [4, 4, 79], [8, 2, 74], [10, 2, 71], [12, 4, 74]],
			[[0, 2, 69], [2, 2, 72], [4, 4, 77], [8, 2, 76], [10, 2, 72], [12, 4, 74]],
			[[0, 2, 79], [2, 2, 81], [4, 2, 79], [6, 2, 76], [8, 4, 74], [12, 4, 67]],
		],
	}


## Relaxed menu loop: 108 BPM, soft pads and a gentle triangle-wave tune.
static func _menu_style() -> Dictionary:
	return {
		"bpm": 108.0,
		"chords": [[48, 52, 55], [45, 48, 52], [41, 45, 48], [43, 47, 50]],
		"bass_steps": [0, 6, 8, 14],
		"bass_offsets": [0, 7, 0, 7],
		"stabs": false,
		"pad": true,
		"kick_steps": [0, 8],
		"snare_steps": [],
		"hat_steps": [4, 12],
		"lead_wave": Wave.TRIANGLE,
		"lead_volume": 0.15,
		"melody": [
			[[0, 4, 72], [4, 4, 76], [8, 8, 79]],
			[[0, 4, 76], [4, 4, 72], [8, 8, 69]],
			[[0, 4, 69], [4, 4, 72], [8, 8, 77]],
			[[0, 4, 74], [4, 4, 71], [8, 8, 67]],
		],
	}


static func _render_track(style: Dictionary) -> PackedFloat32Array:
	var step := 60.0 / float(style["bpm"]) / 4.0
	var chords: Array = style["chords"]
	var bars := chords.size()
	var length := int(round(bars * 16 * step * MIX_RATE))
	var out := PackedFloat32Array()
	out.resize(length)
	for bar in bars:
		var chord: Array = chords[bar]
		var bar_start := bar * 16
		var root: int = chord[0]
		# Bass.
		var bass_steps: Array = style["bass_steps"]
		var bass_offsets: Array = style["bass_offsets"]
		var bass_len := step * (16.0 / float(bass_steps.size())) * 0.85
		for i in bass_steps.size():
			_add_note(out, (bar_start + int(bass_steps[i])) * step, _midi(root - 12 + int(bass_offsets[i])),
					bass_len, Wave.TRIANGLE, 0.34, 0.004, 1.3)
		# Off-beat chord stabs or a soft sustained pad.
		for midi: int in chord:
			if style["stabs"]:
				for s in [2, 6, 10, 14]:
					_add_note(out, (bar_start + s) * step, _midi(midi + 12), step * 0.9, Wave.SQUARE, 0.035, 0.003, 2.0)
			if style["pad"]:
				_add_note(out, bar_start * step, _midi(midi + 12), step * 16.0, Wave.TRIANGLE, 0.05, 0.25, 0.6)
		# Lead melody.
		var melody: Array = style["melody"]
		for note: Array in melody[bar % melody.size()]:
			_add_note(out, (bar_start + int(note[0])) * step, _midi(int(note[2])), int(note[1]) * step * 0.92,
					style["lead_wave"], float(style["lead_volume"]), 0.006, 1.1, true)
		# Drums.
		for s: int in style["kick_steps"]:
			_add_kick(out, (bar_start + s) * step)
		for s: int in style["snare_steps"]:
			_add_noise_hit(out, (bar_start + s) * step, 0.14, 0.26, 3500.0, false)
			_add_note(out, (bar_start + s) * step, 190.0, 0.08, Wave.SINE, 0.18, 0.002, 2.0)
		for s: int in style["hat_steps"]:
			_add_noise_hit(out, (bar_start + s) * step, 0.035, 0.07, 0.0, true)
	# Gentle soft-clip so stacked notes never crackle.
	for i in length:
		out[i] = tanh(out[i] * 1.2) * 0.8
	return out


static func _midi(note: int) -> float:
	return 440.0 * pow(2.0, float(note - 69) / 12.0)


## Adds one note into a looping buffer (notes past the end wrap to the start).
static func _add_note(out: PackedFloat32Array, start: float, freq: float, seconds: float, wave: Wave,
		volume: float, attack: float, decay_power: float, vibrato: bool = false) -> void:
	var length := out.size()
	var first := int(start * MIX_RATE)
	var count := int(seconds * MIX_RATE)
	var attack_samples := maxf(attack * MIX_RATE, 1.0)
	var phase := 0.0
	for i in count:
		var t := float(i) / float(count)
		var f := freq
		if vibrato and i > MIX_RATE * 0.12:
			f *= 1.0 + 0.004 * sin(float(i) / MIX_RATE * TAU * 5.5)
		phase = fmod(phase + f / MIX_RATE, 1.0)
		var envelope := pow(1.0 - t, decay_power) * minf(float(i) / attack_samples, 1.0)
		var index := (first + i) % length
		out[index] += _oscillate(wave, phase) * envelope * volume


static func _add_kick(out: PackedFloat32Array, start: float) -> void:
	var length := out.size()
	var first := int(start * MIX_RATE)
	var count := int(0.18 * MIX_RATE)
	var phase := 0.0
	for i in count:
		var t := float(i) / float(count)
		phase = fmod(phase + lerpf(120.0, 42.0, sqrt(t)) / MIX_RATE, 1.0)
		out[(first + i) % length] += sin(phase * TAU) * pow(1.0 - t, 1.8) * 0.62


static func _add_noise_hit(out: PackedFloat32Array, start: float, seconds: float, volume: float,
		cutoff: float, highpass: bool) -> void:
	var length := out.size()
	var first := int(start * MIX_RATE)
	var count := int(seconds * MIX_RATE)
	var low := 0.0
	var alpha := _lowpass_alpha(cutoff if cutoff > 0.0 else 2500.0)
	for i in count:
		var t := float(i) / float(count)
		var white := randf() * 2.0 - 1.0
		low += alpha * (white - low)
		var sample := white - low if highpass else low * 1.6
		out[(first + i) % length] += sample * pow(1.0 - t, 2.0) * volume


static func _oscillate(wave: Wave, phase: float) -> float:
	match wave:
		Wave.SQUARE:
			return 1.0 if phase < 0.5 else -1.0
		Wave.PULSE:
			return 1.0 if phase < 0.25 else -0.6
		Wave.SAW:
			return phase * 2.0 - 1.0
		Wave.TRIANGLE:
			return 1.0 - 4.0 * absf(phase - 0.5)
	return sin(phase * TAU)


static func _lowpass_alpha(cutoff: float) -> float:
	var rc := 1.0 / (TAU * maxf(cutoff, 20.0))
	var dt := 1.0 / MIX_RATE
	return dt / (rc + dt)


# --- Sound effect bank ------------------------------------------------------

func _can_play(id: StringName) -> bool:
	if not _streams.has(id):
		push_warning("Sfx: unknown sound '%s'" % id)
		return false
	var now := Time.get_ticks_msec()
	var last: int = _last_played.get(id, -1000)
	if now - last < MIN_REPEAT_MSEC:
		return false
	_last_played[id] = now
	return true


func _build_bank() -> void:
	# Blaster launches: a tone for the "pop" plus a breathy "fwip" of air.
	_register(&"pop", _mix([_tone(0.10, 520.0, 160.0, Wave.SINE, 0.6), _noise(0.06, 6000.0, 1500.0, 0.28, 1.5)]))
	_register(&"spray", _mix([_tone(0.07, 640.0, 240.0, Wave.TRIANGLE, 0.45), _noise(0.05, 7000.0, 2000.0, 0.22, 1.5)]))
	_register(&"chain", _mix([_tone(0.055, 420.0, 180.0, Wave.SQUARE, 0.24), _noise(0.04, 5000.0, 1500.0, 0.24, 1.5)]))
	_register(&"thump", _mix([_tone(0.2, 220.0, 60.0, Wave.SINE, 0.8), _noise(0.12, 2500.0, 400.0, 0.38, 1.4)]))
	_register(&"zip", _mix([_tone(0.16, 1400.0, 300.0, Wave.SAW, 0.3), _noise(0.08, 8000.0, 2000.0, 0.2, 1.5)]))
	# Elemental launches and reactions.
	_register(&"whoosh", _mix([_tone(0.18, 700.0, 260.0, Wave.SINE, 0.5), _noise(0.15, 4500.0, 900.0, 0.35, 1.4)]))
	_register(&"splash", _mix([_tone(0.14, 380.0, 120.0, Wave.SINE, 0.65), _noise(0.10, 3200.0, 700.0, 0.45, 1.6)]))
	_register(&"zap", _mix([_tone(0.12, 1800.0, 350.0, Wave.SAW, 0.45), _noise(0.08, 8500.0, 3000.0, 0.3, 1.3)]))
	_register(&"freeze", _mix([_tone(0.22, 1200.0, 1600.0, Wave.TRIANGLE, 0.4), _noise(0.10, 6000.0, 2200.0, 0.25, 1.8)]))
	_register(&"sparkle", _mix([_tone(0.09, 880.0, 1400.0, Wave.SQUARE, 0.25), _noise(0.06, 9000.0, 4000.0, 0.22, 1.2)]))
	_register(&"steam", _noise(0.25, 3000.0, 800.0, 0.3, 1.2, 0.05))

	# Impacts and scoring.
	_register(&"hit", _mix([_noise(0.09, 2200.0, 300.0, 0.6, 1.6), _tone(0.07, 180.0, 90.0, Wave.SINE, 0.35)]))
	_register(&"hit_confirm", _tone(0.06, 1500.0, 1100.0, Wave.TRIANGLE, 0.45))
	_register(&"tag", _mix([_melody([523.0, 659.0, 784.0, 1047.0], 0.07, Wave.SQUARE, 0.26), _tone(0.06, 300.0, 900.0, Wave.SINE, 0.4)]))
	_register(&"tagged", _tone(0.45, 440.0, 110.0, Wave.SAW, 0.32, 0.0, 0.01, 1.2))
	_register(&"ricochet", _mix([_tone(0.22, 500.0, 1500.0, Wave.SINE, 0.45), _tone(0.12, 1800.0, 2600.0, Wave.SINE, 0.15)]))
	_register(&"ding", _mix([_tone(0.5, 1320.0, 1320.0, Wave.SINE, 0.4), _tone(0.5, 1980.0, 1980.0, Wave.SINE, 0.2)]))
	_register(&"boing", _tone(0.3, 160.0, 520.0, Wave.SINE, 0.6))
	_register(&"zombie_moan", _mix([_tone(0.55, 130.0, 95.0, Wave.SAW, 0.42, 0.12, 0.05, 1.2), _tone(0.55, 90.0, 70.0, Wave.TRIANGLE, 0.48, 0.05, 0.04, 1.1)]))
	_register(&"infect", _mix([_noise(0.18, 2800.0, 500.0, 0.52, 1.5), _tone(0.14, 340.0, 110.0, Wave.SQUARE, 0.38), _tone(0.18, 480.0, 190.0, Wave.SINE, 0.35)]))
	_register(&"shield_hit", _mix([_tone(0.12, 1400.0, 900.0, Wave.TRIANGLE, 0.4), _tone(0.08, 2200.0, 1800.0, Wave.SINE, 0.25), _noise(0.04, 8000.0, 4000.0, 0.2, 1.5)]))
	_register(&"shield_pop", _mix([_tone(0.18, 400.0, 120.0, Wave.SINE, 0.7), _noise(0.20, 5000.0, 1000.0, 0.45, 1.8), _tone(0.15, 800.0, 1600.0, Wave.TRIANGLE, 0.3)]))
	_register(&"shield_pickup", _melody([659.0, 880.0, 1174.0, 1568.0], 0.05, Wave.TRIANGLE, 0.35))
	_register(&"ice_slide", _mix([_noise(0.35, 3800.0, 1200.0, 0.38, 1.3), _tone(0.3, 300.0, 550.0, Wave.SINE, 0.25)]))
	_register(&"lava_sizzle", _mix([_noise(0.28, 4200.0, 1100.0, 0.45, 1.4, 0.04), _tone(0.18, 260.0, 140.0, Wave.TRIANGLE, 0.3)]))
	_register(&"siren", _sequence([_tone(0.22, 650.0, 880.0, Wave.SAW, 0.35), _tone(0.22, 880.0, 650.0, Wave.SAW, 0.35)]))
	# Handling.
	_register(&"reload", _sequence([_tone(0.03, 900.0, 700.0, Wave.SQUARE, 0.3, 0.5), _silence(0.08), _tone(0.04, 1200.0, 900.0, Wave.SQUARE, 0.3, 0.5)]))
	_register(&"dry", _tone(0.03, 300.0, 250.0, Wave.SQUARE, 0.25, 0.6))
	_register(&"ammo", _tone(0.05, 700.0, 1100.0, Wave.TRIANGLE, 0.35))
	_register(&"swap", _tone(0.05, 300.0, 500.0, Wave.TRIANGLE, 0.3))
	# Match flow, announcer and UI.
	_register(&"beep", _tone(0.12, 660.0, 660.0, Wave.SQUARE, 0.28, 0.0, 0.004, 1.0))
	_register(&"go", _tone(0.4, 990.0, 990.0, Wave.SQUARE, 0.28, 0.0, 0.004, 1.0))
	_register(&"ui_click", _tone(0.04, 800.0, 600.0, Wave.TRIANGLE, 0.4))
	_register(&"level_up", _melody([660.0, 880.0, 1320.0], 0.08, Wave.TRIANGLE, 0.4))
	_register(&"win", _melody([523.0, 659.0, 784.0, 1047.0, 1319.0], 0.11, Wave.SQUARE, 0.28))
	_register(&"lose", _melody([392.0, 330.0, 262.0], 0.16, Wave.TRIANGLE, 0.4))
	_register(&"announce", _melody([784.0, 1047.0, 1568.0], 0.06, Wave.SQUARE, 0.24))
	_register(&"streak", _melody([523.0, 659.0, 784.0, 1047.0, 1319.0, 1568.0], 0.045, Wave.TRIANGLE, 0.36))
	_register(&"shutdown", _melody([784.0, 587.0, 392.0], 0.08, Wave.SQUARE, 0.26))
	_register(&"powerup", _mix([_melody([523.0, 784.0, 1047.0, 1568.0], 0.06, Wave.TRIANGLE, 0.32), _noise(0.45, 500.0, 6000.0, 0.14, 1.0, 0.2)]))
	_register(&"cheer", _crowd(1.6))
	_register(&"connect", _melody([660.0, 990.0], 0.07, Wave.TRIANGLE, 0.35))
	_register(&"disconnect", _melody([990.0, 660.0], 0.07, Wave.TRIANGLE, 0.35))
	# Backyard life.
	_register(&"woof", _sequence([
		_mix([_tone(0.09, 330.0, 220.0, Wave.SAW, 0.32), _noise(0.09, 1400.0, 600.0, 0.3, 1.2)]),
		_silence(0.07),
		_mix([_tone(0.11, 300.0, 200.0, Wave.SAW, 0.32), _noise(0.11, 1300.0, 500.0, 0.3, 1.2)]),
	]))
	_register(&"chirp", _sequence([_tone(0.07, 2800.0, 4200.0, Wave.SINE, 0.25), _silence(0.04), _tone(0.06, 3200.0, 4600.0, Wave.SINE, 0.2)]))
	_register(&"spin", _spin_loop(), true)


func _register(id: StringName, samples: PackedFloat32Array, loop: bool = false) -> void:
	_streams[id] = _make_stream(samples, loop)


static func _make_stream(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream


## A single swept tone with a fast attack and a power-curve decay.
static func _tone(seconds: float, f_start: float, f_end: float, wave: Wave, volume: float = 0.6,
		noise: float = 0.0, attack: float = 0.004, decay_power: float = 2.0) -> PackedFloat32Array:
	var count := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	var attack_samples := maxf(attack * MIX_RATE, 1.0)
	for i in count:
		var t := float(i) / float(count)
		var freq := f_start * pow(f_end / f_start, t)
		phase = fmod(phase + freq / MIX_RATE, 1.0)
		var sample := _oscillate(wave, phase)
		if noise > 0.0:
			sample = lerpf(sample, randf() * 2.0 - 1.0, noise)
		var envelope := pow(1.0 - t, decay_power) * minf(float(i) / attack_samples, 1.0)
		out[i] = sample * envelope * volume
	return out


## Low-passed noise whose brightness sweeps from cutoff_start to cutoff_end:
## the "fwip" of air and the "thwap" of foam.
static func _noise(seconds: float, cutoff_start: float, cutoff_end: float, volume: float,
		decay_power: float = 2.0, attack: float = 0.002) -> PackedFloat32Array:
	var count := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var low := 0.0
	var attack_samples := maxf(attack * MIX_RATE, 1.0)
	for i in count:
		var t := float(i) / float(count)
		low += _lowpass_alpha(lerpf(cutoff_start, cutoff_end, t)) * ((randf() * 2.0 - 1.0) - low)
		var envelope := pow(1.0 - t, decay_power) * minf(float(i) / attack_samples, 1.0)
		out[i] = low * 1.8 * envelope * volume
	return out


## A little crowd cheer for the podium: swelling, wobbling noise.
static func _crowd(seconds: float) -> PackedFloat32Array:
	var count := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var low := 0.0
	var alpha := _lowpass_alpha(2600.0)
	for i in count:
		var t := float(i) / float(count)
		low += alpha * ((randf() * 2.0 - 1.0) - low)
		var swell := minf(t * 4.0, 1.0) * pow(1.0 - t, 1.2)
		var wobble := 0.7 + 0.3 * sin(t * 37.0) * sin(t * 11.0)
		out[i] = low * 2.2 * swell * wobble * 0.5
	return out


static func _silence(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * MIX_RATE))
	return out


static func _sequence(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for part: PackedFloat32Array in parts:
		out.append_array(part)
	return out


static func _melody(notes: Array, note_seconds: float, wave: Wave, volume: float) -> PackedFloat32Array:
	var parts: Array = []
	for i in notes.size():
		var freq: float = notes[i]
		var length := note_seconds * (2.5 if i == notes.size() - 1 else 1.0)
		parts.append(_tone(length, freq, freq, wave, volume, 0.0, 0.004, 1.0))
	return _sequence(parts)


static func _mix(layers: Array) -> PackedFloat32Array:
	var size := 0
	for layer: PackedFloat32Array in layers:
		size = maxi(size, layer.size())
	var out := PackedFloat32Array()
	out.resize(size)
	for layer: PackedFloat32Array in layers:
		for i in layer.size():
			out[i] += layer[i]
	return out


## Seamless loop for the Chainstorm motor: a buzzy saw chopped by six "barrels".
static func _spin_loop() -> PackedFloat32Array:
	var count := int(0.5 * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	for i in count:
		var t := float(i) / float(MIX_RATE)
		var saw := fmod(t * 80.0, 1.0) * 2.0 - 1.0
		var hum := sin(t * 160.0 * TAU) * 0.5
		var chop := 0.65 + 0.35 * sin(t * 12.0 * TAU)
		out[i] = (saw * 0.35 + hum * 0.3) * chop
	return out
