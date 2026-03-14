package com.lingufranca.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
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
    private val zoomPermissionRequestCode = 6205
    private val zoomPermissions = arrayOf(
        Manifest.permission.CAMERA,
        Manifest.permission.RECORD_AUDIO,
    )

    private var paymentChannel: MethodChannel? = null
    private var zoomChannel: MethodChannel? = null

    private var zoomInitInProgress = false
    private val pendingZoomInitResults = mutableListOf<MethodChannel.Result>()
    private var pendingZoomJoinRequest: PendingZoomJoinRequest? = null
    private var pendingZoomJoinResult: MethodChannel.Result? = null

    private data class PendingZoomJoinRequest(
        val meetingId: String,
        val password: String,
        val displayName: String,
    )

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

        maybeForwardDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        maybeForwardDeepLink(intent)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != zoomPermissionRequestCode) {
            return
        }

        val result = pendingZoomJoinResult
        val request = pendingZoomJoinRequest
        pendingZoomJoinResult = null
        pendingZoomJoinRequest = null

        if (result == null || request == null) {
            return
        }

        val granted = grantResults.isNotEmpty() &&
            grantResults.all { permissionResult -> permissionResult == PackageManager.PERMISSION_GRANTED }

        if (!granted) {
            result.error(
                "permission_denied",
                "Camera and microphone permissions are required to join the lesson",
                null,
            )
            return
        }

        performJoinMeeting(
            meetingId = request.meetingId,
            password = request.password,
            displayName = request.displayName,
            result = result,
        )
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
            result.success(mapOf("status" to "initialized"))
            return
        }

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
                val message = if (ok) {
                    null
                } else {
                    "Zoom SDK init failed: $errorCode ($internalErrorCode)"
                }
                flushInitResults(ok, message)
            }

            override fun onZoomAuthIdentityExpired() {
                flushInitResults(false, "Zoom auth identity expired")
            }
        }, params)
    }

    private fun flushInitResults(success: Boolean, errorMessage: String?) {
        zoomInitInProgress = false
        val results = pendingZoomInitResults.toList()
        pendingZoomInitResults.clear()
        for (result in results) {
            if (success) {
                result.success(mapOf("status" to "initialized"))
            } else {
                result.error("zoom_init_failed", errorMessage ?: "Zoom init failed", null)
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

        if (!hasZoomPermissions()) {
            if (pendingZoomJoinResult != null) {
                result.error("zoom_join_failed", "Another Zoom permission request is already in progress", null)
                return
            }

            pendingZoomJoinRequest = PendingZoomJoinRequest(
                meetingId = meetingNo,
                password = password,
                displayName = displayName,
            )
            pendingZoomJoinResult = result
            ActivityCompat.requestPermissions(this, zoomPermissions, zoomPermissionRequestCode)
            return
        }

        performJoinMeeting(
            meetingId = meetingNo,
            password = password,
            displayName = displayName,
            result = result,
        )
    }

    private fun performJoinMeeting(
        meetingId: String,
        password: String,
        displayName: String,
        result: MethodChannel.Result,
    ) {
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

        val options = JoinMeetingOptions()
        val params = JoinMeetingParams().apply {
            this.meetingNo = meetingId
            this.password = password.trim()
            this.displayName = displayName.trim().ifEmpty { "Lingufranca" }
        }

        val joinResult = meetingService.joinMeetingWithParams(this, params, options)
        if (joinResult == MeetingError.MEETING_ERROR_SUCCESS) {
            result.success(mapOf("status" to "joined"))
            return
        }

        result.error(
            "zoom_join_failed",
            "Zoom join failed: $joinResult",
            mapOf("meetingError" to joinResult),
        )
    }

    private fun hasZoomPermissions(): Boolean {
        return zoomPermissions.all { permission ->
            ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
        }
    }
}
