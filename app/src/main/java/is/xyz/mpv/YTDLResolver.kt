package `is`.xyz.mpv

import android.content.Context
import android.preference.PreferenceManager
import android.util.Log
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import java.io.File
import java.io.FileOutputStream

// Resolves web page URLs (YouTube, etc.) to direct media URLs using yt-dlp,
// and manages the user-provided cookies file.

object YTDLResolver {
    private const val TAG = "ytdl"

    const val PREF_ENABLED = "ytdl_enabled"
    const val PREF_COOKIES_FILE = "ytdl_cookies_file"
    const val PREF_COOKIES_NAME = "ytdl_cookies_name"

    private const val COOKIES_TARGET = "cookies.txt"

    /** A resolved media stream. [primary] is the main URL (video), [secondary] the audio track. */
    data class Resolved(val primary: String, val secondary: String? = null)

    fun isEnabled(context: Context): Boolean {
        return PreferenceManager.getDefaultSharedPreferences(context)
            .getBoolean(PREF_ENABLED, true)
    }

    fun cookiesPath(context: Context): String? {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        if (!prefs.contains(PREF_COOKIES_FILE))
            return null
        val file = File(context.filesDir, COOKIES_TARGET)
        return if (file.exists()) file.absolutePath else null
    }

    fun cookiesDisplayName(context: Context): String? {
        return PreferenceManager.getDefaultSharedPreferences(context)
            .getString(PREF_COOKIES_NAME, null)
    }

    /** Copies the content of a user-picked cookies file into the app dir and records the choice. */
    fun storeCookiesFile(context: Context, uri: android.net.Uri, displayName: String?): Boolean {
        return try {
            val target = File(context.filesDir, COOKIES_TARGET)
            context.contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(target).use { output -> input.copyTo(output) }
            } ?: return false
            with (PreferenceManager.getDefaultSharedPreferences(context).edit()) {
                putString(PREF_COOKIES_FILE, target.absolutePath)
                if (displayName != null)
                    putString(PREF_COOKIES_NAME, displayName)
                commit()
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "failed to store cookies file", e)
            false
        }
    }

    fun clearCookies(context: Context) {
        File(context.filesDir, COOKIES_TARGET).delete()
        with (PreferenceManager.getDefaultSharedPreferences(context).edit()) {
            remove(PREF_COOKIES_FILE)
            remove(PREF_COOKIES_NAME)
            commit()
        }
    }

    /**
     * Resolves a web page URL to direct media URLs on a background thread.
     * `onResult` is called on a background thread; a [Resolved] or an exception is provided.
     */
    fun resolve(context: Context, url: String, onResult: (Result<Resolved>) -> Unit) {
        Thread {
            try {
                YoutubeDL.init(context)

                val request = YoutubeDLRequest(url)
                request.addOption("-g")          // print the direct media URL
                request.addOption("--no-warnings")
                request.addOption("--no-playlist")
                // Bilibili and YouTube only offer separate video/audio (DASH) streams these days,
                // so prefer a merged pair; mpv plays the primary URL and mounts secondary as audio.
                request.addOption("-f", "bestvideo+bestaudio/best")
                cookiesPath(context)?.let { request.addOption("--cookies", it) }

                val response = YoutubeDL.execute(request)
                if (response.exitCode == 0) {
                    val lines = response.out.split('\n')
                        .map { it.trim() }
                        .filter { it.isNotBlank() }
                    if (lines.isEmpty())
                        onResult(Result.failure(
                            IllegalStateException("yt-dlp 没有输出直链: ${response.err}")))
                    else
                        onResult(Result.success(
                            Resolved(lines[0], lines.getOrNull(1))))
                } else {
                    onResult(Result.failure(
                        IllegalStateException(response.err.ifBlank {
                            "yt-dlp 解析失败 (exit ${response.exitCode})"
                        })))
                }
            } catch (e: Exception) {
                Log.w(TAG, "resolve failed", e)
                onResult(Result.failure(e))
            }
        }.start()
    }
}
