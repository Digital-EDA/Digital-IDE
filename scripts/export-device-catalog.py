#!/usr/bin/env python3
"""Export completion-only part names using the vendor tools' public database APIs."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


def write_catalog(output, vendor, source, rows):
    families = {}
    for family, chip, package, part in sorted(set(map(tuple, rows))):
        families.setdefault(family, {}).setdefault(chip, {}).setdefault(package, []).append(part)
    result = {"schemaVersion": 1, "vendor": vendor, "source": source, "families": families}
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"{vendor}: {len(families)} families, {len(rows)} parts -> {output}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("vendor", choices=["xilinx", "efinix"])
    parser.add_argument("--tool-root", type=Path, required=True)
    parser.add_argument("--source-version", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = args.tool_root.resolve()
    if args.vendor == "xilinx":
        with tempfile.TemporaryDirectory(prefix="digital-device-catalog-") as directory:
            script = Path(directory, "export.tcl")
            script.write_text('''set output [open "parts.tsv" w]
foreach part [get_parts -quiet] {
    puts $output "[get_property FAMILY $part]\\t[get_property DEVICE $part]\\t[get_property PACKAGE $part]\\t[get_property SPEED $part]\\t$part"
}
close $output
exit
''')
            subprocess.run([str(root / "bin/vivado"), "-mode", "batch", "-nojournal", "-nolog",
                            "-source", str(script)], cwd=directory, check=True)
            rows = []
            for line in Path(directory, "parts.tsv").read_text().splitlines():
                family, chip, package, speed, part = line.split("\t")
                # DEVICE can contain internal silicon variants such as _CIV;
                # those are not part of the selectable ordering-code prefix.
                if not part.lower().startswith(chip.lower()):
                    chip = chip.split('_')[0]
                if not part.lower().startswith(chip.lower()):
                    raise ValueError(f"Cannot resolve chip prefix for {part}: {chip}")
                end = part.lower().index(package.lower()) + len(package)
                rows.append([family, chip, part[:end], part])
    else:
        # Run with the supplied Efinity Python distribution so its database module is available.
        script = '''from pathlib import Path
from devicedb.pydevicedb import EFXDeviceDatabase
import json, os, re
root = Path(os.environ['EFINITY_HOME'])
db = EFXDeviceDatabase()
db.SetFamilyDeviceFilePath(root / 'arch')
if not db.LoadFamilyData(root / 'arch/devicefamilies.xdb'):
    raise RuntimeError('Cannot load Efinity device families')
rows = []
for family in db.GetVisibleFamilyNames():
    for package in db.GetVisibleDeviceMarketingNames(family):
        chip = re.match(r'(?:Ti|Tz|T)\\d+', package)
        if not chip:
            raise ValueError('Unrecognized device name: ' + package)
        device = db.ConvertToDeviceName(family, package)
        for speed in db.GetTimingModelNames(family, device):
            rows.append([family, chip.group(), package, package + '-' + speed])
print(json.dumps(rows))
'''
        env = {**os.environ, "EFINITY_HOME": str(root),
               "LD_LIBRARY_PATH": str(root / "lib") + os.pathsep + os.environ.get("LD_LIBRARY_PATH", "")}
        result = subprocess.run([str(root / "bin/python3"), "-c", script], env=env,
                                capture_output=True, text=True, check=True)
        rows = json.loads(result.stdout)
    write_catalog(args.output, args.vendor, args.source_version, rows)


if __name__ == "__main__":
    main()
