#include <jni.h>
#include <string>

static std::string g_model_path;

extern "C" JNIEXPORT jboolean JNICALL
Java_com_ari_adaptiveassistant_ml_LlamaNative_init(
        JNIEnv* env,
        jobject /* this */) {
    return JNI_TRUE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_ari_adaptiveassistant_ml_LlamaNative_loadModel(
        JNIEnv* env,
        jobject /* this */,
        jstring path) {
    const char* c_path = env->GetStringUTFChars(path, nullptr);
    g_model_path = c_path ? c_path : "";
    env->ReleaseStringUTFChars(path, c_path);
    // TODO: load model via llama.cpp
    return g_model_path.empty() ? JNI_FALSE : JNI_TRUE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_ari_adaptiveassistant_ml_LlamaNative_rewrite(
        JNIEnv* env,
        jobject /* this */,
        jstring input,
        jint /* maxTokens */,
        jfloat /* temperature */,
        jint /* maxTimeMs */,
        jint /* threads */,
        jint /* contextSize */) {
    const char* c_input = env->GetStringUTFChars(input, nullptr);
    std::string out = c_input ? c_input : "";
    env->ReleaseStringUTFChars(input, c_input);
    // TODO: run llama.cpp inference
    return env->NewStringUTF(out.c_str());
}

extern "C" JNIEXPORT void JNICALL
Java_com_ari_adaptiveassistant_ml_LlamaNative_release(
        JNIEnv* env,
        jobject /* this */) {
    // TODO: free llama.cpp resources
    g_model_path.clear();
}
