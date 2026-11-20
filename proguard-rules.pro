# 保留 JNI 方法签名
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留 VMConfig / VMStats 反射用字段
-keep class com.vmengine.VMConfig { *; }
-keep class com.vmengine.VMStats { *; }
