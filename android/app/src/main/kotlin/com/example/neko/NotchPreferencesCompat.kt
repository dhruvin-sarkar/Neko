package com.example.neko

import android.content.SharedPreferences

object NotchPreferencesCompat {
    fun getBoolean(prefs: SharedPreferences, key: String, defaultValue: Boolean): Boolean {
        for (candidate in candidateKeys(key)) {
            if (prefs.contains(candidate)) {
                return prefs.getBoolean(candidate, defaultValue)
            }
        }
        return defaultValue
    }

    fun getString(prefs: SharedPreferences, key: String, defaultValue: String?): String? {
        for (candidate in candidateKeys(key)) {
            if (prefs.contains(candidate)) {
                return prefs.getString(candidate, defaultValue)
            }
        }
        return defaultValue
    }

    fun putBoolean(prefs: SharedPreferences, key: String, value: Boolean) {
        val editor = prefs.edit()
        for (candidate in candidateKeys(key)) {
            editor.putBoolean(candidate, value)
        }
        editor.commit()
    }

    fun putString(prefs: SharedPreferences, key: String, value: String) {
        val editor = prefs.edit()
        for (candidate in candidateKeys(key)) {
            editor.putString(candidate, value)
        }
        editor.commit()
    }

    fun candidateKeys(key: String): List<String> {
        val normalized = key.removePrefix("flutter.")
        return if (key == normalized) {
            listOf(normalized, "flutter.$normalized")
        } else {
            listOf(key, normalized)
        }
    }
}
