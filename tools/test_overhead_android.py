"""Exercise tap and hold/release on the user's connected Android demo.

Saves screenshots, a screen recording and only this app's logcat diagnostics.
Uses a separate app package and never clears device logs or changes phone settings.
"""
import argparse
import json
import re
import subprocess
import time
from pathlib import Path

from PIL import Image

ADB = r"F:\_Work\AndroidSDK\Sdk\platform-tools\adb.exe"
PACKAGE = "org.mistandiron.overheaddemo"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serial", default="N9AIOC1546046RZ")
    parser.add_argument("--output", type=Path, default=Path("build/overhead-device-test"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    prefix = [ADB, "-s", args.serial]

    def call(*items):
        return subprocess.run(prefix + list(items), capture_output=True, check=True,
                              creationflags=subprocess.CREATE_NO_WINDOW).stdout

    def shot(name):
        path = args.output / (name + ".png")
        path.write_bytes(call("exec-out", "screencap", "-p"))
        return Image.open(path)

    def logs():
        pid = call("shell", "pidof", PACKAGE).decode().strip()
        return call("logcat", "-d", "--pid=" + pid).decode("utf-8", errors="replace")

    call("shell", "am", "force-stop", PACKAGE)
    call("shell", "am", "start", "-n", PACKAGE + "/com.godot.game.GodotAppLauncher")
    time.sleep(2)
    ready = shot("ready")
    w, h = ready.size
    assert w > h, "Demo must be landscape"
    assert sum(ready.getpixel((w // 2, h // 4))[:3]) > 100, "Demo must actually render"
    x, y = str(round(w * .82)), str(round(h * .78))
    recorder = subprocess.Popen(prefix + ["shell", "screenrecord", "--time-limit", "9",
                                "/sdcard/MistIronOverheadDemo-test.mp4"],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                creationflags=subprocess.CREATE_NO_WINDOW)
    call("shell", "input", "tap", x, y)
    time.sleep(2.2)
    shot("normal_finished")
    baseline = len(re.findall(r"OVERHEAD_IMPACT", logs()))
    assert baseline == 1, f"Normal tap must hit exactly once, got {baseline}"
    hold = subprocess.Popen(prefix + ["shell", "input", "swipe", x, y, x, y, "2700"],
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            creationflags=subprocess.CREATE_NO_WINDOW)
    time.sleep(.8)
    shot("charge_held")
    assert len(re.findall(r"OVERHEAD_IMPACT", logs())) == baseline, "Charge must not damage"
    hold.communicate(timeout=10)
    assert hold.returncode == 0
    time.sleep(.08)
    shot("charged_impact")
    time.sleep(1.8)
    shot("charged_finished")
    log = logs()
    impacts = [int(n) for n in re.findall(r"OVERHEAD_IMPACT damage=(\d+)", log)]
    assert impacts == [100, 250], f"Expected normal/full charge hits once each, got {impacts}"
    errors = [line for line in log.splitlines() if "SCRIPT ERROR" in line or " FATAL " in line]
    assert not errors, "Runtime errors: " + repr(errors)
    recorder.communicate(timeout=12)
    assert recorder.returncode == 0
    call("pull", "/sdcard/MistIronOverheadDemo-test.mp4", str(args.output / "android_demo.mp4"))
    (args.output / "app.log").write_text(log, encoding="utf-8")
    report = {"package": PACKAGE, "serial": args.serial, "screen": [w, h],
              "impact_damages": impacts, "charge_does_not_damage": True,
              "runtime_script_errors": errors, "landscape": True}
    (args.output / "verification.json").write_text(json.dumps(report, indent=2))
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
