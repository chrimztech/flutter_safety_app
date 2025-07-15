# Prevent R8 from stripping necessary crypto and annotation classes

# Keep Tink (encryption) classes
-keep class com.google.crypto.tink.** { *; }

# Keep errorprone and javax annotations (used by Tink and others)
-keep class com.google.errorprone.annotations.** { *; }
-keep class javax.annotation.** { *; }
-keep class javax.annotation.concurrent.** { *; }

# Don't warn about them either
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn com.google.crypto.tink.**
