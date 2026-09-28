# ProGuard / R8 rules for VYZI release builds.
#
# R8 removes JVM bytecode by reachability. Reflection is invisible to it: if a
# class is only ever resolved by name at runtime, R8 sees no reference, deletes
# it, and the app compiles cleanly and then throws ClassNotFoundException.
# Every rule below names a place where that would happen.
#
# What is NOT at risk, and therefore has no rules here:
#
#   * All Dart code. It is compiled ahead-of-time into libapp.so, a native
#     library R8 never opens. Models, controllers, JSON parsing and widgets
#     are categorically outside R8's reach.
#   * MainActivity.kt. Four lines, no platform channels, nothing to strip.
#
# After changing this file, re-run the device test pass in
# APP_SIZE_AUDIT.md section 7 -- a missing keep rule does not fail the build.

# ---------------------------------------------------------------------------
# Flutter embedding
# ---------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# GeneratedPluginRegistrant instantiates every plugin by name at engine start.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# ---------------------------------------------------------------------------
# Firebase -- Auth, Core, Messaging
#
# The Firebase SDKs ship consumer rules, but their model classes are
# instantiated reflectively from JSON, and FirebaseMessagingService is resolved
# from the manifest rather than from code.
# ---------------------------------------------------------------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

-keep class * extends com.google.firebase.messaging.FirebaseMessagingService { *; }

# Classes deserialised by the Firebase SDKs keep their no-arg constructors.
-keepclassmembers class * {
    @com.google.firebase.database.PropertyName <fields>;
}

# ---------------------------------------------------------------------------
# Social sign-in
# ---------------------------------------------------------------------------

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Facebook. The SDK reads facebook_app_id / facebook_client_token from string
# resources named in AndroidManifest.xml, and resolves several classes
# reflectively during login.
-keep class com.facebook.** { *; }
-keepclassmembers class com.facebook.** { *; }
-dontwarn com.facebook.**

# Sign in with Apple -- Custom Tabs callback is resolved from the manifest.
-keep class com.aboutyou.dart_packages.sign_in_with_apple.** { *; }
-keep class androidx.browser.customtabs.** { *; }

# ---------------------------------------------------------------------------
# flutter_local_notifications
#
# Serialises scheduled notification details through Gson, so the model classes
# and their generic type parameters must survive. This is the single most
# common R8 breakage in Flutter apps: without it, scheduled notifications throw
# at runtime, long after the build passed.
# ---------------------------------------------------------------------------
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.models.** { *; }

# Gson itself: generic signatures and @SerializedName fields.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-if class *
-keepclasseswithmembers class <1> {
    <init>(...);
    @com.google.gson.annotations.SerializedName <fields>;
}

# ---------------------------------------------------------------------------
# path_provider_android -> jni / jni_flutter
#
# The JNI bindings resolve Java classes and methods by name from Dart. Nothing
# in the JVM bytecode references them, so R8 would strip the lot.
# ---------------------------------------------------------------------------
-keep class com.github.dart_lang.jni.** { *; }
-keepclassmembers class com.github.dart_lang.jni.** { *; }
-dontwarn com.github.dart_lang.jni.**

# ---------------------------------------------------------------------------
# flutter_pdfview -> PDFium (libmodpdfium.so)
#
# The Java side calls into the native library and the native side calls back;
# renaming either end breaks the binding.
# ---------------------------------------------------------------------------
-keep class com.shockwave.** { *; }
-keep class com.github.barteksc.** { *; }
-dontwarn com.shockwave.**

# ---------------------------------------------------------------------------
# Media and file plugins -- CameraX, image_picker, file_picker
# ---------------------------------------------------------------------------
-keep class androidx.camera.** { *; }
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.camera.**

# ---------------------------------------------------------------------------
# flutter_secure_storage -- AndroidX Security / Tink use reflection.
# ---------------------------------------------------------------------------
-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# ---------------------------------------------------------------------------
# Play Core
#
# Flutter references the deferred-components API, which this app does not
# depend on. Without these, R8 fails the build on missing classes.
# ---------------------------------------------------------------------------
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ---------------------------------------------------------------------------
# General Android safety net
# ---------------------------------------------------------------------------

# JNI entry points.
-keepclasseswithmembernames class * {
    native <methods>;
}

# Enum values() / valueOf() are called reflectively by the platform.
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Parcelable CREATOR fields are read by name.
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Serializable plumbing.
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Views inflated from XML need their constructors and setters.
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Kotlin metadata and coroutines internals.
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }

# Keep line numbers so release crash reports stay readable, but hide the
# original file name.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
