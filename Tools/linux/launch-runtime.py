"""Apply the renderer's release settings, then replace this process with the game."""
import json
import os
from pathlib import Path
import re
import sys


def prepare_environment(run_dir, environment):
    if environment.get("ASTROHYBRID_HANG_WATCHDOG") != "1":
        environment.setdefault("KYTY_HANG_WATCHDOG", "0")
    if environment.get("ASTROHYBRID_PERFORMANCE_PRESET") != "0":
        preset = run_dir / "u59-preset.json"
        if not preset.is_file():
            preset = Path(__file__).resolve().parents[1] / "kyty-int21/tools/u59-preset.json"
        values = json.loads(preset.read_text())
        if not isinstance(values, dict) or any(
            not re.fullmatch(r"(?:KYTY|TRACY)_[A-Z0-9_]+", key)
            or not isinstance(value, str) or "\0" in value
            for key, value in values.items()
        ):
            raise ValueError("invalid renderer preset")
        for key, value in values.items():
            environment.setdefault(key, value)
    if environment.get("ASTROHYBRID_DRAW_PREP_TUNING") != "0":
        environment.setdefault("KYTY_DRAW_PREP_SPIN_US", "10")
        environment.setdefault("KYTY_DRAW_PREP_COLD_SPIN_US", "5")
    if environment.get("ASTROHYBRID_SHADER_CACHE") != "0" and not environment.get("ASTROHYBRID_CACHE_TITLE_ID"):
        metadata = run_dir / "app0/sce_sys/param.json"
        if metadata.is_file():
            title = json.loads(metadata.read_text()).get("titleId", "")
            if isinstance(title, str) and re.fullmatch(r"PPSA[0-9]{5}", title):
                environment["ASTROHYBRID_CACHE_TITLE_ID"] = title


if __name__ == "__main__":
    try:
        prepare_environment(Path.cwd(), os.environ)
    except (OSError, ValueError, TypeError) as error:
        sys.exit(f"Cannot prepare Linux runtime: {error}")
    os.execv("./AstroBot", ["./AstroBot", *sys.argv[1:]])
