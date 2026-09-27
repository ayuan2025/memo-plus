## Gson rules
# Keep generic type info used by Gson and TypeToken.
-keepattributes Signature
-keepattributes *Annotation*

# Gson specific classes
-dontwarn sun.misc.**

# Prevent ProGuard/R8 from stripping interfaces used by Gson adapters.
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent R8 from leaving data members always null.
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Retain generic signatures of TypeToken and its subclasses.
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

## ML Kit 文字识别 (google_mlkit_text_recognition)
# 插件在 android/build.gradle 里把「非拉丁语种」的识别器声明成 compileOnly：
#   compileOnly com.google.mlkit:text-recognition-{chinese,devanagari,japanese,korean}
# 中文由 app/build.gradle.kts 显式引入，梵文/日文/韩文没有进包。
# 于是 R8 在混淆时会判定「引用了不存在的类」并中断构建，
# 报错引用点是插件自身的 TextRecognizer.initialize(...)。
# 下面三条与 AGP 自动生成的 build/app/outputs/mapping/fullRelease/missing_rules.txt 一致。
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# 中文/拉丁的 Options 类实际位于 com.google.android.gms:play-services-mlkit-text-recognition-*，
# 这些 AAR 都没有自带 proguard 规则。R8 full mode 下一旦把这些类裁掉或改名，
# 离线模型会在运行时才报错（NoClassDefFoundError / 找不到模型资源），编译期毫无提示，
# 因此整包保留，换取「离线识别一定能跑起来」的确定性。
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.android.libraries.vision.visionkit.pipeline.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_bundled_common.** { *; }
