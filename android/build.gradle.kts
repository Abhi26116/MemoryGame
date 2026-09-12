plugins {
    id("com.android.application") version "8.7.3" apply false
    // Billing Library 8.3+ ships Kotlin 2.2 metadata — keep the compiler in sync.
    id("org.jetbrains.kotlin.android") version "2.2.10" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.10" apply false
}
