#!/usr/bin/env python3
"""Allow Samsung HwModuleTest to register its legacy receiver on Android 16."""

from __future__ import annotations

import os
from pathlib import Path
import re
import shutil
import sys
import tempfile


TARGET = Path("smali/com/android/server/am/BroadcastController.smali")
PACKAGE = "com.sec.android.app.hwmoduletest"
INSERT = [
    f'    const-string/jumbo v3, "{PACKAGE}"\n',
    "\n",
    "    invoke-virtual {v3, v10}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z\n",
    "\n",
    "    move-result v3\n",
    "\n",
    "    if-nez v3, :cond_1a\n",
    "\n",
]


def instruction(lines: list[str], start: int) -> tuple[int, str] | None:
    for index in range(start, len(lines)):
        value = lines[index].strip()
        if not value or value.startswith((".line ", ".local ", ".end local", ".restart local")):
            continue
        return index, value
    return None


def previous_instruction(lines: list[str], start: int) -> tuple[int, str] | None:
    for index in range(start, -1, -1):
        value = lines[index].strip()
        if not value or value.startswith((".line ", ".local ", ".end local", ".restart local")):
            continue
        return index, value
    return None


def main() -> int:
    if not TARGET.is_file():
        print(f"missing smali target: {TARGET}", file=sys.stderr)
        return 1

    lines = TARGET.read_text(encoding="utf-8").splitlines(keepends=True)
    if any(PACKAGE in line for line in lines):
        print("HwModuleTest receiver compatibility is already present")
        return 0

    message = "One of RECEIVER_EXPORTED or RECEIVER_NOT_EXPORTED should be specified"
    message_lines = [index for index, line in enumerate(lines) if message in line]
    match: tuple[int, str, str] | None = None
    if len(message_lines) == 1:
        message_index = message_lines[0]
        package_register = None
        for index in range(message_index + 1, min(message_index + 8, len(lines))):
            register_match = re.search(r"invoke-static \{(v\d+), v1\}", lines[index])
            if register_match:
                package_register = register_match.group(1)
                break

        exception_label = None
        exception_label_index = None
        for index in range(message_index - 1, max(-1, message_index - 12), -1):
            value = lines[index].strip()
            if value.startswith(":cond_"):
                exception_label = value
                exception_label_index = index
                break

        if package_register and exception_label and exception_label_index is not None:
            jump = previous_instruction(lines, exception_label_index - 1)
            second = previous_instruction(lines, jump[0] - 1) if jump else None
            first = previous_instruction(lines, second[0] - 1) if second else None
            jump_match = re.fullmatch(r"goto (?P<label>:\S+)", jump[1]) if jump else None
            second_match = re.fullmatch(r"if-eqz v\d+, (?P<label>:\S+)", second[1]) if second else None
            first_match = re.fullmatch(r"if-eqz v\d+, (?P<label>:\S+)", first[1]) if first else None
            if (
                jump_match
                and second_match
                and first_match
                and second_match.group("label") == exception_label
            ):
                match = (second[0], first_match.group("label"), package_register)

    if match is None:
        print(f"expected one receiver-export exception flow, found {len(message_lines)} messages", file=sys.stderr)
        diagnostic = os.environ.get("F2Q_RECEIVER_DIAGNOSTIC")
        if diagnostic:
            destination = Path(diagnostic)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(TARGET, destination)
            print(f"saved diagnostic smali to {destination}", file=sys.stderr)
        return 1

    insert_at, success_label, package_register = match
    insert = [line.replace("v10", package_register).replace(":cond_1a", success_label) for line in INSERT]
    updated = lines[:insert_at] + insert + lines[insert_at:]
    mode = TARGET.stat().st_mode
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=TARGET.parent, delete=False
    ) as stream:
        stream.writelines(updated)
        temporary = Path(stream.name)
    os.chmod(temporary, mode)
    os.replace(temporary, TARGET)
    print(f"patched HwModuleTest receiver check in {TARGET}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
