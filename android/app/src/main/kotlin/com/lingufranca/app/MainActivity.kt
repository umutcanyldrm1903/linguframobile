package com.lingufranca.app

import android.content.Intent
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import us.zoom.sdk.JoinMeetingOptions
import us.zoom.sdk.JoinMeetingParams
import us.zoom.sdk.MeetingError
import us.zoom.sdk.ZoomError
import us.zoom.sdk.ZoomSDK
import us.zoom.sdk.ZoomSDKInitParams
import us.zoom.sdk.ZoomSDKInitializeListener

class MainActivity : FlutterActivity() {
    private val paymentChannelName = "lingufranca/iyzico"
    private val zoomChannelName = "lingufranca/zoom_meeting"

    private var paymentChannel: MethodChannel? = null
    private var zoomChannel: MethodChannel? = null

    private var zoomInitInProgress = false
    private val pendingZoomInitResults = mutableListOf<MethodChannel.Result>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        paymentChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, paymentChannelName)
        paymentChannel?.setMethodCallHandler { call, result ->
                if (call.method == "startPayment") {
                    val url = call.argument<String>("url") ?: ""
                    if (url.isBlank()) {
                        result.error("missing_url", "Payment URL is missing", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val parsed = Uri.parse(url)
                        val customTabsIntent = CustomTabsIntent.Builder()
                            .setShowTitle(true)
                            .setShareState(CustomTabsIntent.SHARE_STATE_OFF)
                            .build()
                        customTabsIntent.intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
                        customTabsIntent.launchUrl(this, parsed)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("launch_failed", e.localizedMessage, null)
                    }
                } else {
                    result.notImplemented()
                }
            }

        zoomChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, zoomChannelName)
        zoomChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        val jwtToken = call.argument<String>("jwtToken") ?: ""
                        initZoom(jwtToken, result)
                    }

                    "joinMeeting" -> {
                        val meetingId = call.argument<String>("meetingId") ?: ""
                        val password = call.argument<String>("password") ?: ""
                        val displayName = call.argument<String>("displayName") ?: ""
                        joinMeeting(meetingId, password, displayName, result)
                    }

                    else -> result.notImplemented()
                }
            }

        // Handle the case where the app is launched via a deep link.
        maybeForwardDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        maybeForwardDeepLink(intent)
    }

    private fun maybeForwardDeepLink(intent: Intent?) {
        val data = intent?.data ?: return
        if (data.scheme != "lingufranca") return
        paymentChannel?.invokeMethod("deepLink", mapOf("url" to data.toString()))
    }

    private fun initZoom(jwtToken: String, result: MethodChannel.Result) {
        val token = jwtToken.trim()
        if (token.isEmpty()) {
            result.error("missing_jwt", "Zoom SDK JWT token is missing", null)
            return
        }

        val sdk = ZoomSDK.getInstance()
        if (sdk.isInitialized) {
            result.success(true)
            return
        }

        // Coalesce concurrent init requests.
        pendingZoomInitResults.add(result)
        if (zoomInitInProgress) return
        zoomInitInProgress = true

        val params = ZoomSDKInitParams().apply {
            this.jwtToken = token
            domain = "zoom.us"
            enableLog = true
        }

        sdk.initialize(this, object : ZoomSDKInitializeListener {
            override fun onZoomSDKInitializeResult(errorCode: Int, internalErrorCode: Int) {
                val ok = errorCode == ZoomError.ZOOM_ERROR_SUCCESS
                val message = if (ok) null else "Zoom SDK init failed: $errorCode ($internalErrorCode)"
                flushInitResults(ok, message)
            }

            override fun onZoomAuthIdentityExpired() {
                // The token expired; the Flutter layer will fetch a new one and re-init.
                flushInitResults(false, "Zoom auth identity expired")
            }
        }, params)
    }

    private fun flushInitResults(success: Boolean, errorMessage: String?) {
        zoomInitInProgress = false
        val results = pendingZoomInitResults.toList()
        pendingZoomInitResults.clear()
        for (r in results) {
            if (success) {
                r.success(true)
            } else {
                r.error("zoom_init_failed", errorMessage ?: "Zoom init failed", null)
            }
        }
    }

    private fun joinMeeting(
        meetingId: String,
        password: String,
        displayName: String,
        result: MethodChannel.Result,
    ) {
        val meetingNo = meetingId.trim()
        if (meetingNo.isEmpty()) {
            result.error("missing_meeting_id", "Meeting ID is missing", null)
            return
        }

        val sdk = ZoomSDK.getInstance()
        if (!sdk.isInitialized) {
            result.error("zoom_not_initialized", "Zoom SDK is not initialized", null)
            return
        }

        val meetingService = sdk.meetingService
        if (meetingService == null) {
            result.error("zoom_service_missing", "Zoom MeetingService is not available", null)
            return
        }

        val opts = JoinMeetingOptions()
        val params = JoinMeetingParams().apply {
            this.meetingNo = meetingNo
            this.password = password.trim()
            this.displayName = displayName.trim().ifEmpty { "Lingufranca" }
        }

        val ret = meetingService.joinMeetingWithParams(this, params, opts)
        result.success(ret == MeetingError.MEETING_ERROR_SUCCESS)
    }
}
