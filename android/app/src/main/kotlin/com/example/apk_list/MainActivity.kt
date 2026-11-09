package com.example.apk_list

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Activité principale gérant les canaux natifs haute performance pour l'extraction
 * des métadonnées système (tailles de fichiers, dates, versions SDK) en tâche de fond.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.example.apk_list/native_details"
    private val backgroundExecutor = Executors.newFixedThreadPool(2)
    private val mainHandler = Handler(Looper.getMainLooper())
    private var channel: MethodChannel? = null
    private var dynamicPackageReceiver: BroadcastReceiver? = null

    companion object {
        private var activeInstance: MainActivity? = null

        /**
         * Notifie Flutter qu'un événement système sur un paquet (ajout, suppression, màj) est survenu.
         */
        fun notifyPackageChange(action: String, packageName: String) {
            activeInstance?.let { activity ->
                activity.mainHandler.post {
                    activity.channel?.invokeMethod(
                        "onPackageChanged",
                        mapOf(
                            "action" to action,
                            "packageName" to packageName
                        )
                    )
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        activeInstance = this

        // Canal de communication bidirectionnel entre Flutter (Dart) et Android (Kotlin)
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel = methodChannel

        // Réception et traitement des commandes envoyées par Flutter
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                // Flutter demande les métadonnées approfondies de la liste des applications
                "getAppsDetails" -> {
                    val packageNames = call.argument<List<String>>("packages")
                    extractAppsDetails(packageNames, result)
                }
                // Flutter demande les caractéristiques matérielles du téléphone (fabricant, modèle, version OS)
                "getDeviceInfo" -> {
                    val info = HashMap<String, String>()
                    val manufacturer = Build.MANUFACTURER.replaceFirstChar { it.uppercase() }
                    val model = Build.MODEL
                    val release = Build.VERSION.RELEASE
                    info["manufacturer"] = manufacturer
                    info["model"] = model
                    info["fullName"] = if (model.startsWith(manufacturer, ignoreCase = true)) model else "$manufacturer $model"
                    info["osVersion"] = "Android $release"
                    result.success(info)
                }
                else -> result.notImplemented()
            }
        }

        registerDynamicPackageReceiver()
    }

    private fun registerDynamicPackageReceiver() {
        if (dynamicPackageReceiver != null) return

        dynamicPackageReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent == null) return
                val action = intent.action ?: return
                val packageName = intent.data?.schemeSpecificPart ?: ""
                notifyPackageChange(action, packageName)
            }
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            addDataScheme("package")
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(dynamicPackageReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                registerReceiver(dynamicPackageReceiver, filter)
            }
        } catch (_: Exception) {
            // Ignoré si les permissions système restreignent l'enregistrement dynamique
        }
    }

    private fun extractAppsDetails(packageNames: List<String>?, result: MethodChannel.Result) {
        // Exécution sur un thread d'arrière-plan pour ne jamais geler l'affichage Flutter
        backgroundExecutor.execute {
            try {
                val pm = context.packageManager
                val detailsMap = HashMap<String, HashMap<String, Any>>()

                val targets = if (!packageNames.isNullOrEmpty()) {
                    packageNames
                } else {
                    val installed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0))
                    } else {
                        @Suppress("DEPRECATION")
                        pm.getInstalledApplications(0)
                    }
                    installed.map { it.packageName }
                }

                for (pkgName in targets) {
                    try {
                        val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            pm.getApplicationInfo(pkgName, PackageManager.ApplicationInfoFlags.of(0))
                        } else {
                            @Suppress("DEPRECATION")
                            pm.getApplicationInfo(pkgName, 0)
                        }

                        // Récupération des informations de base du package (sans flag GET_PERMISSIONS pour optimiser la mémoire et les I/O)
                        val pkgInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            pm.getPackageInfo(pkgName, PackageManager.PackageInfoFlags.of(0))
                        } else {
                            @Suppress("DEPRECATION")
                            pm.getPackageInfo(pkgName, 0)
                        }

                        // Mesure de la taille réelle du fichier APK stocké sur le disque
                        val sourceDir = appInfo.sourceDir
                        val sizeInBytes = if (!sourceDir.isNullOrEmpty()) {
                            val apkFile = File(sourceDir)
                            if (apkFile.exists() && apkFile.canRead()) {
                                apkFile.length()
                            } else {
                                0L
                            }
                        } else {
                            0L
                        }

                        // Détection du magasin d'installation d'origine (Google Play, Phoenix, etc.)
                        val installerPackageName: String? = try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                val installSource = pm.getInstallSourceInfo(pkgName)
                                installSource.installingPackageName ?: installSource.initiatingPackageName ?: installSource.originatingPackageName
                            } else {
                                @Suppress("DEPRECATION")
                                pm.getInstallerPackageName(pkgName)
                            }
                        } catch (_: Exception) {
                            null
                        }

                        val itemDetails = HashMap<String, Any>()
                        itemDetails["sizeInBytes"] = sizeInBytes
                        itemDetails["firstInstallTime"] = pkgInfo.firstInstallTime
                        itemDetails["lastUpdateTime"] = pkgInfo.lastUpdateTime
                        itemDetails["targetSdkVersion"] = appInfo.targetSdkVersion
                        itemDetails["sourceDir"] = sourceDir ?: ""
                        itemDetails["installerPackageName"] = installerPackageName ?: ""

                        detailsMap[pkgName] = itemDetails
                    } catch (_: PackageManager.NameNotFoundException) {
                        // Package désinstallé ou inaccessible pendant l'itération, ignoré proprement
                    } catch (_: SecurityException) {
                        // Droits restreints sur un paquet système particulier, ignoré proprement
                    }
                }

                // Renvoi des résultats complets à Flutter sur le thread principal UI
                mainHandler.post {
                    result.success(detailsMap)
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("EXTRACTION_ERROR", "Échec de l'extraction des métadonnées: ${e.message}", null)
                }
            }
        }
    }

    override fun onDestroy() {
        dynamicPackageReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) {
            }
            dynamicPackageReceiver = null
        }
        if (activeInstance == this) {
            activeInstance = null
        }
        channel = null
        backgroundExecutor.shutdown()
        super.onDestroy()
    }
}
