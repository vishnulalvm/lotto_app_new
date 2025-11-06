# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# ===============================================
# FLUTTER SPECIFIC RULES
# ===============================================

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep method channels and platform channels
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodCall *;
}

# Keep Flutter activity and application
-keep class io.flutter.app.FlutterActivity { *; }
-keep class io.flutter.app.FlutterApplication { *; }

# Keep Dart classes
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# ===============================================
# FIREBASE SPECIFIC RULES
# ===============================================

# Firebase Core
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.database.** { *; }

# Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.crashlytics.** { *; }

# Firebase Auth (if used)
-keep class com.google.firebase.auth.** { *; }

# Keep Firebase model classes
-keepclassmembers class * {
    @com.google.firebase.database.PropertyName *;
}

# ===============================================
# GOOGLE MOBILE ADS (ADMOB) RULES
# ===============================================

# AdMob
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# AdMob mediation adapters (if used)
-keep class com.google.ads.mediation.** { *; }

# Google Mobile Ads SDK
-keep class com.google.android.gms.ads.identifier.** { *; }

# ===============================================
# DART/JSON SERIALIZATION RULES
# ===============================================

# Keep JSON serialization classes
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep model classes that might be serialized
-keep class **.model.** { *; }
-keep class **.models.** { *; }
-keep class **.data.** { *; }

# Keep classes with @JsonSerializable annotation (if using json_annotation)
-keep @interface **.*JsonSerializable*
-keep class **.*JsonSerializable* { *; }

# ===============================================
# KOTLIN SPECIFIC RULES
# ===============================================

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ===============================================
# ANDROID SPECIFIC RULES
# ===============================================

# Keep Android support library classes
-keep class androidx.** { *; }
-keep interface androidx.** { *; }

# Keep WebView - Critical for AdMob to prevent GPU crashes
-keep class android.webkit.** { *; }
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebChromeClient {
    public void *(android.webkit.WebView, java.lang.String);
}

# Prevent WebView renderer crashes (MediaTek GPU issue fix)
-keep class org.chromium.** { *; }
-dontwarn org.chromium.**

# Keep Activity classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# ===============================================
# THIRD-PARTY LIBRARIES RULES
# ===============================================

# OkHttp (commonly used by Flutter plugins)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Retrofit (if used)
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }

# Gson (if used)
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

# ===============================================
# GENERAL RULES
# ===============================================

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep setters in Views so that animations can still work
-keepclassmembers public class * extends android.view.View {
   void set*(***);
   *** get*();
}

# Keep classes that are referenced only in layout XMLs
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep enum classes
-keepclassmembers enum * { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ===============================================
# GOOGLE PLAY CORE / PLAY STORE SPECIFIC RULES
# ===============================================

# Google Play Core (for app bundles and dynamic features)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep classes related to split install
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Flutter Play Store integration
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

# ===============================================
# CUSTOM APP SPECIFIC RULES
# ===============================================

# Keep your main application class
-keep class app.solidapps.lotto.** { *; }

# Keep any classes that might be used via reflection
-keep class * {
    @androidx.annotation.Keep *;
}

# Keep classes used by Flutter plugins
-keep class * implements io.flutter.plugin.common.PluginRegistry$Registrar { *; }

# ===============================================
# OPTIMIZATION RULES
# ===============================================

# Enable optimization
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Remove unused code
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# ===============================================
# DEBUGGING (REMOVE IN PRODUCTION)
# ===============================================

# Uncomment these lines if you need to debug ProGuard issues
# -printmapping mapping.txt
# -printseeds seeds.txt
# -printusage usage.txt