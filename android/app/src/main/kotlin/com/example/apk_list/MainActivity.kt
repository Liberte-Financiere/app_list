package com.example.apk_list

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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppsDetails" -> {
                    val packageNames = call.argument<List<String>>("packages")
                    extractAppsDetails(packageNames, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun extractAppsDetails(packageNames: List<String>?, result: MethodChannel.Result) {
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

                        val pkgInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            pm.getPackageInfo(pkgName, PackageManager.PackageInfoFlags.of(0))
                        } else {
                            @Suppress("DEPRECATION")
                            pm.getPackageInfo(pkgName, 0)
                        }

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

                        val itemDetails = HashMap<String, Any>()
                        itemDetails["sizeInBytes"] = sizeInBytes
                        itemDetails["firstInstallTime"] = pkgInfo.firstInstallTime
                        itemDetails["lastUpdateTime"] = pkgInfo.lastUpdateTime
                        itemDetails["targetSdkVersion"] = appInfo.targetSdkVersion
                        itemDetails["sourceDir"] = sourceDir ?: ""

                        detailsMap[pkgName] = itemDetails
                    } catch (_: PackageManager.NameNotFoundException) {
                        // Package désinstallé ou inaccessible pendant l'itération, ignoré proprement
                    } catch (_: SecurityException) {
                        // Droits restreints sur un paquet système particulier, ignoré proprement
                    }
                }

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
        backgroundExecutor.shutdown()
        super.onDestroy()
    }
}
