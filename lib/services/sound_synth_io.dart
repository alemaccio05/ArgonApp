import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

// --- Definizioni FFI per Windows (winmm.dll) ---
typedef _PlaySoundNative = Int32 Function(
  Pointer<Uint8> pszSound,
  IntPtr hmod,
  Uint32 fdwSound,
);
typedef _PlaySoundDart = int Function(
  Pointer<Uint8> pszSound,
  int hmod,
  int fdwSound,
);

// --- Definizioni FFI per Android NDK (libaaudio.so) ---
typedef _AAudioCreateBuilderNative = Int32 Function(
  Pointer<Pointer<Void>> builder,
);
typedef _AAudioCreateBuilderDart = int Function(
  Pointer<Pointer<Void>> builder,
);

typedef _AAudioBuilderSetIntNative = Void Function(
  Pointer<Void> builder,
  Int32 value,
);
typedef _AAudioBuilderSetIntDart = void Function(
  Pointer<Void> builder,
  int value,
);

typedef _AAudioBuilderOpenStreamNative = Int32 Function(
  Pointer<Void> builder,
  Pointer<Pointer<Void>> stream,
);
typedef _AAudioBuilderOpenStreamDart = int Function(
  Pointer<Void> builder,
  Pointer<Pointer<Void>> stream,
);

typedef _AAudioStreamActionNative = Int32 Function(Pointer<Void> stream);
typedef _AAudioStreamActionDart = int Function(Pointer<Void> stream);

typedef _AAudioStreamWriteNative = Int32 Function(
  Pointer<Void> stream,
  Pointer<Int16> buffer,
  Int32 numFrames,
  Int64 timeoutNanoseconds,
);
typedef _AAudioStreamWriteDart = int Function(
  Pointer<Void> stream,
  Pointer<Int16> buffer,
  int numFrames,
  int timeoutNanoseconds,
);

/// Sintetizzatore procedurale di effetti sonori a 44.1kHz 16-bit in memoria.
/// - Su Android (es. Pixel 3a): riproduce i buffer PCM in tempo reale tramite `libaaudio.so`
///   in un Isolate dedicato a bassa latenza.
/// - Su Windows: riproduce i buffer WAV tramite `winmm.dll` (`PlaySoundW`).
class NativeSoundSynth {
  static const int _sampleRate = 44100;
  static const int _sndAsync = 0x0001;
  static const int _sndNoDefault = 0x0002;
  static const int _sndMemory = 0x0004;
  static const int _flags = _sndAsync | _sndNoDefault | _sndMemory;

  _PlaySoundDart? _playSoundWin;
  SendPort? _androidAudioPort;
  bool _initialized = false;

  // Buffer PCM 16-bit (usati su Android AAudio)
  late final Int16List _aimTickPcm;
  late final Int16List _launchPcm;
  final List<Int16List> _padStickPcms = [];
  late final Int16List _wallBouncePcm;
  late final Int16List _bumperPcm;
  final List<Int16List> _sealPcms = [];
  late final Int16List _shieldPcm;
  late final Int16List _victoryPcm;
  late final Int16List _crashPcm;

  // Buffer WAV in memoria nativa (usati su Windows PlaySoundW)
  Pointer<Uint8>? _aimTickWav;
  Pointer<Uint8>? _launchWav;
  final List<Pointer<Uint8>> _padStickWavs = [];
  Pointer<Uint8>? _wallBounceWav;
  Pointer<Uint8>? _bumperWav;
  final List<Pointer<Uint8>> _sealWavs = [];
  Pointer<Uint8>? _shieldWav;
  Pointer<Uint8>? _victoryWav;
  Pointer<Uint8>? _crashWav;

  void init() {
    if (_initialized) return;
    _initialized = true;

    // 1. Genera i 9 timbri sonori ben distinti tra loro
    // A) Tick di mira: tocco legnoso breve e acuto (Marimba tick)
    _aimTickPcm = _synthSweepPcm(
      durationSec: 0.024,
      startFreq: 1120,
      endFreq: 740,
      volume: 0.20,
    );

    // B) Lancio fionda: "whoosh" elastico ascendente
    _launchPcm = _synthSweepPcm(
      durationSec: 0.135,
      startFreq: 165,
      endFreq: 690,
      volume: 0.38,
      triangleMix: 0.55,
    );

    // C) Incollaggio piattaforma verde (scala pentatonica ascendente: doppio plop morbido)
    // D) Raccolta Gemma Scudo (arpeggio cristallino a 4 note)
    const pentatonic = [1.0, 1.122, 1.26, 1.498, 1.682, 2.0, 2.245, 2.52];
    for (final mult in pentatonic) {
      _padStickPcms.add(
        _synthArpeggioPcm(
          notesHz: [280.0 * mult, 420.0 * mult],
          noteDurationSec: 0.042,
          volume: 0.28,
        ),
      );
      _sealPcms.add(
        _synthArpeggioPcm(
          notesHz: [
            523.25 * mult * 0.75,
            659.25 * mult * 0.75,
            783.99 * mult * 0.75,
            1046.50 * mult * 0.75,
          ],
          noteDurationSec: 0.045,
          volume: 0.38,
        ),
      );
    }

    // E) Rimbalzo sul muro in pietra: colpo grave e profondo ("thud" sordo)
    _wallBouncePcm = _synthSweepPcm(
      durationSec: 0.095,
      startFreq: 145,
      endFreq: 52,
      volume: 0.44,
      noiseMix: 0.12,
    );

    // F) Rimbalzo su Bumper Pinball: "boing" squillante a campana elastica
    _bumperPcm = _synthArpeggioPcm(
      notesHz: [440.0, 880.0, 659.25, 1174.66],
      noteDurationSec: 0.038,
      volume: 0.42,
    );

    // G) Rottura Scudo / Crollo piattaforma: accordo discendente frizzante
    _shieldPcm = _synthArpeggioPcm(
      notesHz: [880.0, 622.25, 440.0, 311.13],
      noteDurationSec: 0.048,
      volume: 0.38,
    );

    // H) Vittoria: fanfara trionfale a 5 note
    _victoryPcm = _synthArpeggioPcm(
      notesHz: [523.25, 659.25, 783.99, 987.77, 1046.50],
      noteDurationSec: 0.085,
      volume: 0.45,
    );

    // I) Sconfitta / Impatto: discesa grave con spruzzo d'inchiostro
    _crashPcm = _synthSweepPcm(
      durationSec: 0.28,
      startFreq: 250,
      endFreq: 46,
      volume: 0.44,
      noiseMix: 0.35,
    );

    if (Platform.isWindows) {
      try {
        final winmm = DynamicLibrary.open('winmm.dll');
        _playSoundWin = winmm
            .lookupFunction<_PlaySoundNative, _PlaySoundDart>('PlaySoundW');

        _aimTickWav = _allocWav(_encodeWav(_aimTickPcm));
        _launchWav = _allocWav(_encodeWav(_launchPcm));
        for (final pcm in _padStickPcms) {
          _padStickWavs.add(_allocWav(_encodeWav(pcm)));
        }
        for (final pcm in _sealPcms) {
          _sealWavs.add(_allocWav(_encodeWav(pcm)));
        }
        _wallBounceWav = _allocWav(_encodeWav(_wallBouncePcm));
        _bumperWav = _allocWav(_encodeWav(_bumperPcm));
        _shieldWav = _allocWav(_encodeWav(_shieldPcm));
        _victoryWav = _allocWav(_encodeWav(_victoryPcm));
        _crashWav = _allocWav(_encodeWav(_crashPcm));
      } catch (_) {
        _playSoundWin = null;
      }
    } else if (Platform.isAndroid) {
      _startAndroidAAudioIsolate();
    }
  }

  Future<void> _startAndroidAAudioIsolate() async {
    try {
      final receivePort = ReceivePort();
      await Isolate.spawn(_androidAudioWorker, receivePort.sendPort);
      final port = await receivePort.first;
      if (port is SendPort) {
        _androidAudioPort = port;
      }
    } catch (_) {}
  }

  void stopAll() {
    if (Platform.isWindows && _playSoundWin != null) {
      _playSoundWin!(nullptr, 0, 0);
    } else if (_androidAudioPort != null) {
      _androidAudioPort!.send('stop');
    }
  }

  void _play(Int16List pcm, Pointer<Uint8>? winWav) {
    if (!_initialized) init();
    if (Platform.isWindows && _playSoundWin != null && winWav != null) {
      _playSoundWin!(winWav, 0, _flags);
    } else if (_androidAudioPort != null) {
      _androidAudioPort!.send(pcm);
    }
  }

  void playAimTick() => _play(_aimTickPcm, _aimTickWav);
  void playLaunch() => _play(_launchPcm, _launchWav);

  void playPadStick(int combo) {
    if (!_initialized) init();
    final idx = combo.clamp(0, _padStickPcms.length - 1);
    final wav = idx < _padStickWavs.length ? _padStickWavs[idx] : null;
    _play(_padStickPcms[idx], wav);
  }

  void playWallBounce() => _play(_wallBouncePcm, _wallBounceWav);
  void playBumper() => _play(_bumperPcm, _bumperWav);

  void playSeal(int combo) {
    if (!_initialized) init();
    final idx = combo.clamp(0, _sealPcms.length - 1);
    final wav = idx < _sealWavs.length ? _sealWavs[idx] : null;
    _play(_sealPcms[idx], wav);
  }

  void playShieldBreak() => _play(_shieldPcm, _shieldWav);
  void playVictory() => _play(_victoryPcm, _victoryWav);
  void playCrash() => _play(_crashPcm, _crashWav);

  Pointer<Uint8> _allocWav(Uint8List wavBytes) {
    final ptr = malloc.allocate<Uint8>(wavBytes.length);
    ptr.asTypedList(wavBytes.length).setAll(0, wavBytes);
    return ptr;
  }

  Int16List _synthSweepPcm({
    required double durationSec,
    required double startFreq,
    required double endFreq,
    required double volume,
    double noiseMix = 0.0,
    double triangleMix = 0.0,
  }) {
    final numSamples = (_sampleRate * durationSec).round();
    final pcm = Int16List(numSamples);
    final rng = Random(42);
    double phase = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = startFreq + (endFreq - startFreq) * t;
      phase += (2 * pi * freq) / _sampleRate;

      final attack = (i / (_sampleRate * 0.004)).clamp(0.0, 1.0);
      final decay = pow(1.0 - t, 1.35).toDouble();
      final env = attack * decay;

      double sample = sin(phase);
      if (triangleMix > 0) {
        final tri = (2.0 / pi) * asin(sin(phase));
        sample = sample * (1.0 - triangleMix) + tri * triangleMix;
      }
      if (noiseMix > 0) {
        final noise = rng.nextDouble() * 2.0 - 1.0;
        sample = sample * (1.0 - noiseMix) + noise * noiseMix;
      }

      pcm[i] = (sample * env * volume * 32767.0).round().clamp(-32768, 32767);
    }
    return pcm;
  }

  Int16List _synthArpeggioPcm({
    required List<double> notesHz,
    required double noteDurationSec,
    required double volume,
  }) {
    final samplesPerNote = (_sampleRate * noteDurationSec).round();
    final totalSamples = samplesPerNote * notesHz.length;
    final pcm = Int16List(totalSamples);
    double phase = 0.0;

    for (int n = 0; n < notesHz.length; n++) {
      final freq = notesHz[n];
      for (int i = 0; i < samplesPerNote; i++) {
        final t = i / samplesPerNote;
        phase += (2 * pi * freq) / _sampleRate;
        final attack = (i / (_sampleRate * 0.003)).clamp(0.0, 1.0);
        final decay = pow(1.0 - t * 0.85, 1.25).toDouble();
        final sample = sin(phase) * 0.72 + sin(phase * 2.0) * 0.28;
        pcm[n * samplesPerNote + i] =
            (sample * attack * decay * volume * 32767.0)
                .round()
                .clamp(-32768, 32767);
      }
    }
    return pcm;
  }

  Uint8List _encodeWav(Int16List pcmSamples) {
    final dataSize = pcmSamples.length * 2;
    final fileSize = 44 + dataSize;
    final bytes = ByteData(fileSize);

    bytes.setUint8(0, 0x52); // 'R'
    bytes.setUint8(1, 0x49); // 'I'
    bytes.setUint8(2, 0x46); // 'F'
    bytes.setUint8(3, 0x46); // 'F'
    bytes.setUint32(4, fileSize - 8, Endian.little);
    bytes.setUint8(8, 0x57); // 'W'
    bytes.setUint8(9, 0x41); // 'A'
    bytes.setUint8(10, 0x56); // 'V'
    bytes.setUint8(11, 0x45); // 'E'

    bytes.setUint8(12, 0x66); // 'f'
    bytes.setUint8(13, 0x6D); // 'm'
    bytes.setUint8(14, 0x74); // 't'
    bytes.setUint8(15, 0x20); // ' '
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, _sampleRate, Endian.little);
    bytes.setUint32(28, _sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);

    bytes.setUint8(36, 0x64); // 'd'
    bytes.setUint8(37, 0x61); // 'a'
    bytes.setUint8(38, 0x74); // 't'
    bytes.setUint8(39, 0x61); // 'a'
    bytes.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < pcmSamples.length; i++) {
      bytes.setInt16(44 + i * 2, pcmSamples[i], Endian.little);
    }

    return bytes.buffer.asUint8List();
  }
}

/// Worker Isolate Android che riproduce con latenza zero i campioni PCM 16-bit
/// tramite la libreria di sistema NDK `libaaudio.so`.
Future<void> _androidAudioWorker(SendPort mainSendPort) async {
  final port = ReceivePort();
  mainSendPort.send(port.sendPort);

  DynamicLibrary aaudio;
  try {
    aaudio = DynamicLibrary.open('libaaudio.so');
  } catch (_) {
    return;
  }

  final createBuilder = aaudio.lookupFunction<
      _AAudioCreateBuilderNative,
      _AAudioCreateBuilderDart>('AAudio_createStreamBuilder');
  final setFormat = aaudio.lookupFunction<
      _AAudioBuilderSetIntNative,
      _AAudioBuilderSetIntDart>('AAudioStreamBuilder_setFormat');
  final setChannels = aaudio.lookupFunction<
      _AAudioBuilderSetIntNative,
      _AAudioBuilderSetIntDart>('AAudioStreamBuilder_setChannelCount');
  final setSampleRate = aaudio.lookupFunction<
      _AAudioBuilderSetIntNative,
      _AAudioBuilderSetIntDart>('AAudioStreamBuilder_setSampleRate');
  final setPerfMode = aaudio.lookupFunction<
      _AAudioBuilderSetIntNative,
      _AAudioBuilderSetIntDart>('AAudioStreamBuilder_setPerformanceMode');
  final openStream = aaudio.lookupFunction<
      _AAudioBuilderOpenStreamNative,
      _AAudioBuilderOpenStreamDart>('AAudioStreamBuilder_openStream');
  final deleteBuilder = aaudio.lookupFunction<
      _AAudioStreamActionNative,
      _AAudioStreamActionDart>('AAudioStreamBuilder_delete');
  final requestStart = aaudio.lookupFunction<
      _AAudioStreamActionNative,
      _AAudioStreamActionDart>('AAudioStream_requestStart');
  final writeStream = aaudio.lookupFunction<
      _AAudioStreamWriteNative,
      _AAudioStreamWriteDart>('AAudioStream_write');
  final closeStream = aaudio.lookupFunction<
      _AAudioStreamActionNative,
      _AAudioStreamActionDart>('AAudioStream_close');

  Pointer<Void> openAAudioStream() {
    final builderPtr = calloc<Pointer<Void>>();
    final streamPtr = calloc<Pointer<Void>>();
    try {
      if (createBuilder(builderPtr) != 0) return nullptr;
      final builder = builderPtr.value;
      setFormat(builder, 1); // AAUDIO_FORMAT_PCM_I16 = 1
      setChannels(builder, 1); // Mono
      setSampleRate(builder, 44100);
      setPerfMode(builder, 12); // AAUDIO_PERFORMANCE_MODE_LOW_LATENCY = 12
      final res = openStream(builder, streamPtr);
      deleteBuilder(builder);
      if (res != 0) return nullptr;
      final stream = streamPtr.value;
      requestStart(stream);
      return stream;
    } finally {
      calloc.free(builderPtr);
      calloc.free(streamPtr);
    }
  }

  Pointer<Void> stream = openAAudioStream();
  const int chunkFrames = 512;
  final Pointer<Int16> chunkBuf = calloc<Int16>(chunkFrames);

  Int16List? activeSamples;
  int sampleCursor = 0;
  bool loopRunning = false;

  Future<void> pumpAudio() async {
    if (loopRunning) return;
    loopRunning = true;
    while (activeSamples != null) {
      if (stream == nullptr) {
        stream = openAAudioStream();
        if (stream == nullptr) {
          activeSamples = null;
          break;
        }
      }
      final samples = activeSamples!;
      final remaining = samples.length - sampleCursor;
      if (remaining <= 0) {
        activeSamples = null;
        break;
      }
      final count = remaining < chunkFrames ? remaining : chunkFrames;
      for (int i = 0; i < count; i++) {
        chunkBuf[i] = samples[sampleCursor + i];
      }
      sampleCursor += count;

      final written = writeStream(stream, chunkBuf, count, 100000000);
      if (written < 0) {
        closeStream(stream);
        stream = openAAudioStream();
      }
      // Cede brevemente alla coda eventi per accettare istantaneamente un nuovo suono o 'stop'
      await Future<void>.delayed(Duration.zero);
    }
    loopRunning = false;
  }

  await for (final msg in port) {
    if (msg == 'stop') {
      activeSamples = null;
      sampleCursor = 0;
    } else if (msg is Int16List) {
      activeSamples = msg;
      sampleCursor = 0;
      unawaited(pumpAudio());
    }
  }
}
