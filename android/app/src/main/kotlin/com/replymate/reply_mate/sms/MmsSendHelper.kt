package com.replymate.reply_mate.sms

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Telephony
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.util.Log
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileInputStream

/**
 * Sends an MMS message that contains an image part and a text part.
 *
 * Strategy:
 *  1. Copy the image from its local path into the app's cache dir.
 *  2. Expose the cached copy via [FileProvider] to get a content:// URI.
 *  3. Build a native MMS send Intent and deliver via [SmsManager.sendMultimediaMessage].
 *
 * Fallback: if anything fails the caller should degrade to plain SMS.
 */
object MmsSendHelper {

    private const val TAG = "ReplyMate/MMS"
    private const val AUTHORITY_SUFFIX = ".provider"

    /**
     * Attempt to send an MMS with [imagePath] as the JPEG/PNG image part and [text] as the body.
     *
     * @return `true` if the MMS was dispatched without throwing, `false` otherwise.
     */
    fun sendMmsWithImage(
        context: Context,
        subscriptionId: Int?,
        destinationAddress: String,
        text: String,
        imagePath: String,
    ): Boolean {
        return try {
            val appCtx = context.applicationContext

            // 1. Resolve image file
            val imageFile = File(imagePath)
            if (!imageFile.exists() || !imageFile.canRead()) {
                Log.w(TAG, "Image file not readable: $imagePath")
                return false
            }

            // 2. Copy into cache so FileProvider can serve it
            val cacheFile = File(appCtx.cacheDir, "mms_image_${System.currentTimeMillis()}.jpg")
            FileInputStream(imageFile).use { input ->
                cacheFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }

            // 3. Build content:// URI via FileProvider
            val authority = appCtx.packageName + AUTHORITY_SUFFIX
            val imageUri: Uri = FileProvider.getUriForFile(appCtx, authority, cacheFile)

            // 4. Build MMS PDU parts using ContentValues (Android MMS API)
            val contentUri = buildMmsPdu(appCtx, destinationAddress, text, imageUri)
            if (contentUri == null) {
                File(appCtx.filesDir, "mms_debug.txt").appendText("\n${java.util.Date()}: buildMmsPdu returned null (Not Default SMS App?)")
                return false
            }

            // 5. Send
            val smsManager = resolveSmsManager(subscriptionId)
            smsManager.sendMultimediaMessage(appCtx, contentUri, null, null, null)

            Log.d(TAG, "MMS dispatched to $destinationAddress")
            File(appCtx.filesDir, "mms_debug.txt").appendText("\n${java.util.Date()}: MMS dispatched to $destinationAddress via sendMultimediaMessage")
            true
        } catch (e: Exception) {
            Log.e(TAG, "MMS send failed for $destinationAddress", e)
            File(context.filesDir, "mms_debug.txt").appendText("\n${java.util.Date()}: Exception sending MMS: ${e.message}\n${Log.getStackTraceString(e)}")
            false
        }
    }

    /**
     * Inserts a minimal MMS PDU into [Telephony.Mms.CONTENT_URI] with:
     *  - one image part
     *  - one text part
     *
     * Returns the inserted message URI (used by [SmsManager.sendMultimediaMessage]) or null on failure.
     */
    private fun buildMmsPdu(
        ctx: Context,
        to: String,
        text: String,
        imageUri: Uri,
    ): Uri? {
        val resolver = ctx.contentResolver

        // Insert MMS message stub
        val msgValues = ContentValues().apply {
            put(Telephony.Mms.MESSAGE_TYPE, 128) // PduHeaders.MESSAGE_TYPE_SEND_REQ
            put(Telephony.Mms.MMS_VERSION, 18) // MmsConfig.getMmsVersion() ≈ 0x12
            put(Telephony.Mms.TEXT_ONLY, 0)
            put(Telephony.Mms.READ, 1)
            put(Telephony.Mms.SEEN, 1)
        }
        val msgUri = resolver.insert(Telephony.Mms.CONTENT_URI, msgValues) ?: run {
            Log.e(TAG, "Failed to insert MMS stub")
            return null
        }

        val msgId = msgUri.lastPathSegment ?: return null

        // Insert To address
        val addrUri = Uri.parse("${Telephony.Mms.CONTENT_URI}/$msgId/addr")
        val addrValues = ContentValues().apply {
            put(Telephony.Mms.Addr.ADDRESS, to)
            put(Telephony.Mms.Addr.CHARSET, 106) // UTF-8
            put(Telephony.Mms.Addr.TYPE, 151)    // PduHeaders.TO
        }
        resolver.insert(addrUri, addrValues)

        // Insert image part
        val partsUri = Uri.parse("${Telephony.Mms.CONTENT_URI}/$msgId/part")
        val imgPartValues = ContentValues().apply {
            put(Telephony.Mms.Part.MSG_ID, msgId)
            put(Telephony.Mms.Part.SEQ, 0)
            put(Telephony.Mms.Part.CONTENT_TYPE, "image/jpeg")
            put(Telephony.Mms.Part.NAME, "image.jpg")
            put(Telephony.Mms.Part.CONTENT_DISPOSITION, "attachment")
        }
        val imgPartUri = resolver.insert(partsUri, imgPartValues) ?: run {
            Log.e(TAG, "Failed to insert image part")
            return null
        }
        // Stream the image bytes into the part
        resolver.openOutputStream(imgPartUri)?.use { out ->
            resolver.openInputStream(imageUri)?.use { inp ->
                inp.copyTo(out)
            }
        }

        // Insert text part
        val txtPartValues = ContentValues().apply {
            put(Telephony.Mms.Part.MSG_ID, msgId)
            put(Telephony.Mms.Part.SEQ, 1)
            put(Telephony.Mms.Part.CONTENT_TYPE, "text/plain")
            put(Telephony.Mms.Part.NAME, "body.txt")
            put(Telephony.Mms.Part.CHARSET, 106) // UTF-8
            put(Telephony.Mms.Part.TEXT, text)
        }
        resolver.insert(partsUri, txtPartValues) ?: run {
            Log.e(TAG, "Failed to insert text part")
            return null
        }

        return msgUri
    }

    private fun resolveSmsManager(subscriptionId: Int?): SmsManager {
        if (subscriptionId != null &&
            subscriptionId != SubscriptionManager.INVALID_SUBSCRIPTION_ID
        ) {
            return SmsManager.getSmsManagerForSubscriptionId(subscriptionId)
        }
        return SmsManager.getDefault()
    }
}
