package com.replymate.reply_mate.autoreply

/**
 * Mirrors Flutter [contact_filter_phone_normalize] for consistent SMS / filter matching.
 */
object ContactPhoneNormalize {
    fun digitsOnly(s: String): String = s.replace(Regex("[^0-9]"), "")

    fun canonicalPhoneKey(digitsOnly: String): String {
        var x = digitsOnly
        if (x.isEmpty()) return ""
        while (x.startsWith("0") && x.length > 10) {
            x = x.substring(1)
        }
        if (x.startsWith("91") && x.length >= 12) {
            x = x.substring(2)
        } else if (x.startsWith("91") && x.length == 11) {
            x = x.substring(2)
        }
        if (x.length == 11 && x.startsWith("1")) {
            x = x.substring(1)
        }
        return x
    }
}
