-keep class com.google.crypto.tink.** { *; }
-keepclassmembers class * {
    @com.google.crypto.tink.* *;
}
-dontwarn com.google.crypto.tink.**