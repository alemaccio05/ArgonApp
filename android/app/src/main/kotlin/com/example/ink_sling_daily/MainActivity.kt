package com.example.ink_sling_daily

import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.ink_sling_daily/audio"
    private var soundPool: SoundPool? = null
    private val soundIds = ConcurrentHashMap<String, Int>()
    private val loadedSampleIds = ConcurrentHashMap.newKeySet<Int>()
    private val activeStreamIds = CopyOnWriteArrayList<Int>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Assicura che i tasti volume del telefono regolino il volume Media del gioco
        volumeControlStream = AudioManager.STREAM_MUSIC
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()

        val pool = SoundPool.Builder()
            .setMaxStreams(12)
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
                            for ((k, v) in args) {
                                val key = k as? String ?: continue
                                val bytes = v as? ByteArray ?: continue
                                try {
                                    val file = File(cacheDir, "sfx_$key.wav")
                                    file.writeBytes(bytes)
                                    val id = pool.load(file.absolutePath, 1)
                                    soundIds[key] = id
                                } catch (_: Exception) {
                                }
                            }
                        }
                        result.success(true)
                    }
                    "play" -> {
                        val key = call.argument<String>("key")
                        if (key != null) {
                            val soundId = soundIds[key]
                            if (soundId != null && loadedSampleIds.contains(soundId)) {
                                val streamId = pool.play(soundId, 1.0f, 1.0f, 1, 0, 1.0f)
                                if (streamId != 0) {
                                    activeStreamIds.add(streamId)
                                    if (activeStreamIds.size > 24) {
                                        activeStreamIds.removeAt(0)
                                    }
                                }
                            }
                        }
                        result.success(null)
                    }
                    "stopAll" -> {
                        for (streamId in activeStreamIds) {
                            pool.stop(streamId)
                        }
                        activeStreamIds.clear()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}

