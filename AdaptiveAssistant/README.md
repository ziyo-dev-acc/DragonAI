# AdaptiveAssistant

Offline‑first personal voice assistant for Android 14 with always‑listening wake word, local skills, and optional local/cloud LLM.

## Build (Android Studio)
1. Install Flutter SDK and Android SDK.
2. Create `android/local.properties` with:
   - `flutter.sdk=/path/to/flutter`
   - `sdk.dir=/path/to/Android/Sdk`
3. Run:
   - `flutter pub get`
   - `flutter run`

> Note: `android/gradle/wrapper/gradle-wrapper.jar` is not included here. If Gradle wrapper is missing, run `gradle wrapper` or use Android Studio to sync, which will regenerate it.

## Wake Word (Picovoice Porcupine)
- Add your Porcupine access key and keyword file path in `android/app/src/main/kotlin/com/ari/adaptiveassistant/services/WakeWordService.kt`.
- Place your `.ppn` keyword file in app internal storage or assets, then update `keywordPath`.
- Foreground service notification shows: "Assistant is listening (wake word enabled)" with Pause/Stop actions.

## Speech‑to‑Text
- Uses Android `SpeechRecognizer` via MethodChannel.
- Partial transcripts are pushed via EventChannel.
- If STT is unavailable, app falls back to typed input (UI wiring left minimal).

## Local LLM (llama.cpp)
- NDK JNI stub is in `android/app/src/main/cpp/llama_jni.cpp`.
- JNI bridge is wired in `android/app/src/main/kotlin/com/ari/adaptiveassistant/ml/LlamaBridge.kt`.
- Add llama.cpp under `android/app/src/main/cpp/third_party/llama.cpp` and update `CMakeLists.txt` (set `USE_LLAMA=ON`) to link it.
- Model Manager lets user pick GGUF via SAF. Selected model is copied to internal storage as `files/local_model.gguf`.

Recommended low‑end defaults:
- context size: 512
- max tokens: 96
- temperature: 0.4
- threads: 2
- max inference time: 2000ms

## Cloud Help
- Toggle off by default.
- Intended to send only transcript + minimal context. No file names or content unless user enables sharing.

## Permissions & Setup
- Microphone, media access, document tree picker, notification listener, and optional WRITE_SETTINGS.
- Notification cache stores last 50 notifications locally.

## Notes
- Low CPU/battery: wake word runs in foreground service, local LLM runs only after command is captured.
- Media indexing for PDFs uses SAF tree picker and stores metadata in local SQLite.
