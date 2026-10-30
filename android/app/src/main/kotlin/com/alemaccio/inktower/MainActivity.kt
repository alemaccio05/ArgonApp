package com.alemaccio.inktower

import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "com.alemaccio.inktower/audio"
    private var soundPool: SoundPool? = null
    private val soundIds = ConcurrentHashMap<String, Int>()
    private val loadedSampleIds = ConcurrentHashMap.newKeySet<Int>()
    private val audioExecutor = Executors.newSingleThreadExecutor()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Assicura che i tasti volume del telefono regolino il volume Media del gioco
        volumeControlStream = AudioManager.STREAM_MUSIC
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val pool = SoundPool.Builder()
            .setMaxStreams(10)
            .setAudioAttributes(audioAttributes)
            .build()

        pool.setOnLoadCompleteListener { _, sampleId, status ->
            if (status == 0) {
                loadedSampleIds.add(sampleId)
            }
        }
        soundPool = pool

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initWavs" -> {
                        val args = call.arguments as? Map<*, *>
                        if (args != null) {
                            audioExecutor.execute {
                                for ((k, v) in args) {
                                    val key = k as? String ?: continue
                                    val bytes = v as? ByteArray ?: continue
                                    try {
                                        val file = File(cacheDir, "sfx_$key.wav")
                                        if (!file.exists() || file.length() != bytes.size.toLong()) {
                                            file.writeBytes(bytes)
                                        }
                                        val id = pool.load(file.absolutePath, 1)
                                        soundIds[key] = id
                                    } catch (_: Exception) {
                                    }
                                }
                            }
                        }
                        result.success(true)
                    }
                    "play" -> {
                        val key = call.argument<String>("key")
                        val vol = (call.argument<Double>("volume") ?: 1.0).toFloat()
                        if (key != null) {
                            val soundId = soundIds[key]
                            if (soundId != null && loadedSampleIds.contains(soundId)) {
                                // Esegue play su thread dedicato per evitare micro-stuttering
                                // dell'UI thread su HAL audio MIUI (POCO) e ColorOS (OPPO)
                                audioExecutor.execute {
                                    pool.play(soundId, vol, vol, 1, 0, 1.0f)
                                }
                            }
                        }
                        result.success(null)
                    }
                    "setPaused" -> {
                        val paused = call.arguments as? Boolean ?: false
                        audioExecutor.execute {
                            if (paused) {
                                pool.autoPause()
                            } else {
                                pool.autoResume()
                            }
                        }
                        result.success(null)
                    }
                    "stopAll" -> {
                        audioExecutor.execute {
                            pool.autoPause()
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        audioExecutor.shutdownNow()
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
