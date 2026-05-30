import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._internal();
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _lastKey;
  int _lastPlayMs = 0;
  int _currentPriority = 99;

  static const Set<String> _successKeys = {
    'doc_good','doc_captured','face_good','face_captured','success_all',
  };
  static const Map<String,int> _priority = {
    'not_aadhaar':1,'not_pan':1,'not_passbook':1,'not_voter':1,'not_license':1,
    'no_face':1,'doc_good':1,'face_good':1,'doc_captured':1,'face_captured':1,
    'partial':2,'occlusion':2,'mask':2,'multiple_faces':2,'blink_prompt':2,
    'blur':3,'very_blur':3,'low_light':3,'glare':3,'too_bright':3,'eyes_closed':3,'face_blur':3,'hold_still':3,
    'tilt':4,'too_far':4,'too_close':4,'face_too_far':4,'face_too_close':4,
    'look_straight':4,'face_left':4,'face_right':4,'face_up':4,'face_down':4,
    'bad_background':4,'uneven_light':4,'glasses':4,
  };

  Future<void> preloadAll() async {
    await _player.setReleaseMode(ReleaseMode.stop);
    _player.onPlayerComplete.listen((_) { _isPlaying = false; _currentPriority = 99; });
  }

  Future<void> play(String key) async {
    if (key.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final isSuccess = _successKeys.contains(key);
    final pri = _priority[key] ?? 5;
    if (!isSuccess) {
      if (key == _lastKey && now - _lastPlayMs < 3000) return;
      if (now - _lastPlayMs < 2000) return;
      if (_isPlaying && pri >= _currentPriority) return;
    }
    try {
      if (_isPlaying) await _player.stop();
      _isPlaying = true; _currentPriority = pri; _lastKey = key; _lastPlayMs = now;
      await _player.play(AssetSource('audio/$key.mp3'));
    } catch (_) { _isPlaying = false; _currentPriority = 99; }
  }

  Future<void> stop() async { await _player.stop(); _isPlaying = false; _currentPriority = 99; }
  Future<void> dispose() async => _player.dispose();
}