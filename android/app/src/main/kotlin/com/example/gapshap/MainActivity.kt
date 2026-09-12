package com.example.gapshap

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.URLEncoder
import java.nio.charset.StandardCharsets

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val CHANNEL = "com.krevzy/upi"
        private const val UPI_REQUEST_CODE = 9101
    }

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "launchUpi" -> {
                    if (pendingResult != null) {
                        result.error(
                            "UPI_BUSY",
                            "Another UPI transaction is already in progress.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    val receiverUpiId =
                        call.argument<String>("receiverUpiId")

                    val receiverName =
                        call.argument<String>("receiverName")

                    val transactionRef =
                        call.argument<String>("transactionRef")

                    val transactionNote =
                        call.argument<String>("transactionNote")

                    val amount =
                        call.argument<String>("amount")

                    if (
                        receiverUpiId.isNullOrBlank() ||
                        receiverName.isNullOrBlank() ||
                        transactionRef.isNullOrBlank() ||
                        amount.isNullOrBlank()
                    ) {
                        result.error(
                            "INVALID_UPI_DATA",
                            "Required UPI payment information is missing.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    pendingResult = result

                    launchUpiIntent(
                        receiverUpiId = receiverUpiId,
                        receiverName = receiverName,
                        transactionRef = transactionRef,
                        transactionNote =
                            transactionNote ?: "KREVZY Wallet Top Up",
                        amount = amount
                    )
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun launchUpiIntent(
        receiverUpiId: String,
        receiverName: String,
        transactionRef: String,
        transactionNote: String,
        amount: String
    ) {
        try {

            val uri = Uri.parse(
                "upi://pay" +
                        "?pa=${encode(receiverUpiId)}" +
                        "&pn=${encode(receiverName)}" +
                        "&tr=${encode(transactionRef)}" +
                        "&tn=${encode(transactionNote)}" +
                        "&am=${encode(amount)}" +
                        "&cu=INR"
            )

            val intent = Intent(Intent.ACTION_VIEW, uri)

            val chooser = Intent.createChooser(
                intent,
                "Pay with UPI"
            )

            startActivityForResult(
                chooser,
                UPI_REQUEST_CODE
            )

        } catch (e: Exception) {

            pendingResult?.error(
                "UPI_LAUNCH_FAILED",
                e.message ?: "Unable to launch UPI application.",
                null
            )

            pendingResult = null
        }
    }

    private fun encode(value: String): String {
        return URLEncoder.encode(
            value,
            StandardCharsets.UTF_8.toString()
        )
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(
            requestCode,
            resultCode,
            data
        )

        if (requestCode != UPI_REQUEST_CODE) {
            return
        }

        val response = data?.getStringExtra("response")

        val status =
            parseUpiStatus(response)

        val resultMap = hashMapOf<String, Any?>(
            "status" to status,
            "response" to response,
            "resultCode" to resultCode
        )

        pendingResult?.success(resultMap)

        pendingResult = null
    }

    private fun parseUpiStatus(response: String?): String {

        if (response.isNullOrBlank()) {
            return "cancelled"
        }

        val normalized = response.lowercase()

        val status = extractValue(
            normalized,
            "status"
        )

        return when (status?.lowercase()) {

            "success" -> "success"

            "submitted" -> "submitted"

            "pending" -> "pending"

            "failure" -> "failure"

            "failed" -> "failure"

            "cancelled" -> "cancelled"

            "canceled" -> "cancelled"

            else -> {
                when {
                    normalized.contains("success") ->
                        "success"

                    normalized.contains("submitted") ->
                        "submitted"

                    normalized.contains("pending") ->
                        "pending"

                    normalized.contains("fail") ->
                        "failure"

                    else ->
                        "unknown"
                }
            }
        }
    }

    private fun extractValue(
        response: String,
        key: String
    ): String? {

        val parts = response.split("&")

        for (part in parts) {

            val pair = part.split(
                "=",
                limit = 2
            )

            if (
                pair.size == 2 &&
                pair[0].trim() == key
            ) {
                return pair[1].trim()
            }
        }

        return null
    }

    override fun onDestroy() {
        pendingResult = null
        super.onDestroy()
    }
}