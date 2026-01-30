package com.ari.adaptiveassistant.ml

object LlamaNative {
    init {
        System.loadLibrary("llama_jni")
    }

    external fun init(): Boolean
    external fun loadModel(path: String): Boolean
    external fun rewrite(
        input: String,
        maxTokens: Int,
        temperature: Float,
        maxTimeMs: Int,
        threads: Int,
        contextSize: Int,
    ): String
    external fun release()
}
