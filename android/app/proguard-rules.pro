# Flutter & Kotlin rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Ignore missing optional Google Play Services and Play Core classes
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.gms.**
-dontwarn com.baseflow.geolocator.location.FusedLocationClient
-dontwarn com.baseflow.geolocator.**

