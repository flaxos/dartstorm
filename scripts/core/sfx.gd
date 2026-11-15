extends Node
## Autoload "Sfx": a tiny procedural sound bank. Every sound is synthesised at
## startup, so the game ships with zero audio files and nothing to licence.
## Replace an entry in _build_bank() with a real AudioStream later if you like.

const MIX_RATE := 22050
const FLAT_VOICES := 12
const SPATIAL_VOICES := 16
const MIN_REPEAT_MSEC := 22

enum Wave { SINE, SQUARE, SAW, TRIANGLE }

var _streams: Dictionary = {}
var _flat: Array[AudioStreamPlayer] = []
var _spatial: Array[AudioStreamPlayer3D] = []
var _flat_index := 0
var _spatial_index := 0
var _last_played: Dictionary = {}
var _spin: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_bank()
	for i in FLAT_VOICES:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_flat.append(voice)
	for i in SPATIAL_VOICES:
		var voice3d := AudioStreamPlayer3D.new()
		voice3d.unit_size = 7.0
		voice3d.max_distance = 70.0
		add_child(voice3d)
		_spatial.append(voice3d)
	_spin = AudioStreamPlayer.new()
	_spin.stream = _streams[&"spin"]
	_spin.volume_db = -9.0
	add_child(_spin)


func _exit_tree() -> void:
	# Stop every voice so no playback objects outlive the engine at quit.
	for voice in _flat:
		voice.stop()
	for voice3d in _spatial:
		voice3d.stop()
	_spin.stop()


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


# --- Synthesis -------------------------------------------------------------

func _build_bank() -> void:
	# Blaster launches
	_register(&"pop", _mix(_tone(0.10, 520.0, 160.0, Wave.SINE, 0.7), _tone(0.05, 2000.0, 800.0, Wave.SINE, 0.3, 0.9)))
	_register(&"spray", _mix(_tone(0.07, 640.0, 240.0, Wave.TRIANGLE, 0.55), _tone(0.04, 3000.0, 1000.0, Wave.SINE, 0.25, 1.0)))
	_register(&"chain", _mix(_tone(0.055, 420.0, 180.0, Wave.SQUARE, 0.32), _tone(0.04, 2500.0, 900.0, Wave.SINE, 0.3, 1.0)))
	_register(&"thump", _mix(_tone(0.2, 220.0, 60.0, Wave.SINE, 0.8), _tone(0.08, 1500.0, 400.0, Wave.SINE, 0.4, 1.0)))
	_register(&"zip", _mix(_tone(0.16, 1400.0, 300.0, Wave.SAW, 0.35), _tone(0.05, 2400.0, 900.0, Wave.SINE, 0.25, 1.0)))
	# Impacts and scoring
	_register(&"hit", _tone(0.07, 330.0, 140.0, Wave.SINE, 0.6, 0.25))
	_register(&"hit_confirm", _tone(0.06, 1500.0, 1100.0, Wave.TRIANGLE, 0.45))
	_register(&"tag", _melody([523.0, 659.0, 784.0, 1047.0], 0.07, Wave.SQUARE, 0.28))
	_register(&"tagged", _tone(0.45, 440.0, 110.0, Wave.SAW, 0.35, 0.0, 0.01, 1.2))
	_register(&"ricochet", _tone(0.22, 500.0, 1500.0, Wave.SINE, 0.5))
	_register(&"ding", _mix(_tone(0.5, 1320.0, 1320.0, Wave.SINE, 0.4), _tone(0.5, 1980.0, 1980.0, Wave.SINE, 0.2)))
	_register(&"boing", _tone(0.3, 160.0, 520.0, Wave.SINE, 0.6))
	# Handling
	_register(&"reload", _sequence([_tone(0.03, 900.0, 700.0, Wave.SQUARE, 0.3, 0.5), _silence(0.08), _tone(0.04, 1200.0, 900.0, Wave.SQUARE, 0.3, 0.5)]))
	_register(&"dry", _tone(0.03, 300.0, 250.0, Wave.SQUARE, 0.25, 0.6))
	_register(&"ammo", _tone(0.05, 700.0, 1100.0, Wave.TRIANGLE, 0.35))
	_register(&"swap", _tone(0.05, 300.0, 500.0, Wave.TRIANGLE, 0.3))
	# Match flow and UI
	_register(&"beep", _tone(0.12, 660.0, 660.0, Wave.SQUARE, 0.28, 0.0, 0.004, 1.0))
	_register(&"go", _tone(0.4, 990.0, 990.0, Wave.SQUARE, 0.28, 0.0, 0.004, 1.0))
	_register(&"ui_click", _tone(0.04, 800.0, 600.0, Wave.TRIANGLE, 0.4))
	_register(&"level_up", _melody([660.0, 880.0, 1320.0], 0.08, Wave.TRIANGLE, 0.4))
	_register(&"win", _melody([523.0, 659.0, 784.0, 1047.0, 1319.0], 0.11, Wave.SQUARE, 0.28))
	_register(&"lose", _melody([392.0, 330.0, 262.0], 0.16, Wave.TRIANGLE, 0.4))
	_register(&"spin", _spin_loop(), true)


func _register(id: StringName, samples: PackedFloat32Array, loop: bool = false) -> void:
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
	_streams[id] = stream


## A single swept tone with a fast attack and a power-curve decay.
func _tone(seconds: float, f_start: float, f_end: float, wave: Wave, volume: float = 0.6,
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
		var sample := 0.0
		match wave:
			Wave.SINE:
				sample = sin(phase * TAU)
			Wave.SQUARE:
				sample = 1.0 if phase < 0.5 else -1.0
			Wave.SAW:
				sample = phase * 2.0 - 1.0
			Wave.TRIANGLE:
				sample = 1.0 - 4.0 * absf(phase - 0.5)
		if noise > 0.0:
			sample = lerpf(sample, randf() * 2.0 - 1.0, noise)
		var envelope := pow(1.0 - t, decay_power) * minf(float(i) / attack_samples, 1.0)
		out[i] = sample * envelope * volume
	return out


func _silence(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * MIX_RATE))
	return out


func _sequence(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for part: PackedFloat32Array in parts:
		out.append_array(part)
	return out


func _melody(notes: Array, note_seconds: float, wave: Wave, volume: float) -> PackedFloat32Array:
	var parts: Array = []
	for i in notes.size():
		var freq: float = notes[i]
		var length := note_seconds * (2.5 if i == notes.size() - 1 else 1.0)
		parts.append(_tone(length, freq, freq, wave, volume, 0.0, 0.004, 1.0))
	return _sequence(parts)


func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(maxi(a.size(), b.size()))
	for i in out.size():
		var sample := 0.0
		if i < a.size():
			sample += a[i]
		if i < b.size():
			sample += b[i]
		out[i] = sample
	return out


## Seamless loop for the Chainstorm motor: a buzzy saw chopped by six "barrels".
func _spin_loop() -> PackedFloat32Array:
	var seconds := 0.5
	var count := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	for i in count:
		var t := float(i) / float(MIX_RATE)
		var saw := fmod(t * 80.0, 1.0) * 2.0 - 1.0
		var hum := sin(t * 160.0 * TAU) * 0.5
		var chop := 0.65 + 0.35 * sin(t * 12.0 * TAU)
		out[i] = (saw * 0.35 + hum * 0.3) * chop
	return out
