package com.example.apk_list

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Récepteur de diffusion système réagissant aux ajouts, remplacements et suppressions
 * de paquets d'applications sur l'appareil Android de façon silencieuse et sans surcoût CPU.
 */
class PackageChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent == null) return

        val action = intent.action ?: return
        val packageName = intent.data?.schemeSpecificPart ?: ""

        Log.d("PackageChangeReceiver", "Événement de paquet détecté: $action ($packageName)")
        MainActivity.notifyPackageChange(action, packageName)
    }
}
