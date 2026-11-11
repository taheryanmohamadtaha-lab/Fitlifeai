"""Patch the generated Android project for notifications (run in CI after `flutter create`)."""
import os
import re
import sys

root = sys.argv[1] if len(sys.argv) > 1 else "android"

# ---------- Manifest ----------
mp = os.path.join(root, "app/src/main/AndroidManifest.xml")
m = open(mp, encoding="utf-8").read()
perms = [
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.VIBRATE",
]
add = ""
for p in perms:
    if p not in m:
        add += f'    <uses-permission android:name="{p}"/>\n'
if add:
    m = m.replace("<application", add + "    <application", 1)
if "ScheduledNotificationReceiver" not in m:
    receivers = """
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""
    m = m.replace("</application>", receivers + "    </application>", 1)
open(mp, "w", encoding="utf-8").write(m)
print("manifest patched")

# ---------- Gradle: core library desugaring ----------
kts = os.path.join(root, "app/build.gradle.kts")
groovy = os.path.join(root, "app/build.gradle")
if os.path.exists(kts):
    g = open(kts, encoding="utf-8").read()
    if "isCoreLibraryDesugaringEnabled" not in g:
        if "compileOptions {" in g:
            g = g.replace("compileOptions {", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", 1)
        else:
            g = g.replace("android {", "android {\n    compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n    }", 1)
    if "coreLibraryDesugaring(" not in g:
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    open(kts, "w", encoding="utf-8").write(g)
    print("gradle.kts patched")
elif os.path.exists(groovy):
    g = open(groovy, encoding="utf-8").read()
    if "coreLibraryDesugaringEnabled" not in g:
        if "compileOptions {" in g:
            g = g.replace("compileOptions {", "compileOptions {\n        coreLibraryDesugaringEnabled true", 1)
        else:
            g = g.replace("android {", "android {\n    compileOptions {\n        coreLibraryDesugaringEnabled true\n    }", 1)
    if "coreLibraryDesugaring '" not in g:
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    open(groovy, "w", encoding="utf-8").write(g)
    print("gradle patched")
else:
    print("ERROR: no app/build.gradle(.kts) found")
    sys.exit(1)
