# FPGA device completion catalog

These catalogs supply suggestions only. `property.json.device` is a free-form
string, without an enum, model lookup, or validation against the catalogs. Selecting
a suggestion edits only that value in the document; requesting suggestions never
saves, rewrites, or normalizes the configuration.

In `.vscode/property.json`, use Ctrl+Space inside `device`. Completion reads the
current document's `toolChain`, including unsaved edits, and progresses through
family prefix, chip, package, then the full part/speed-grade name. Selecting an
intermediate prefix automatically opens the next suggestions. A typed prefix can
also skip directly to its matching stage.

- `xilinx`: 4,131 parts from **Vivado 2022.2**, covering all 41 families/variants
  returned by that installation's `get_parts` (7 Series, Zynq, UltraScale,
  UltraScale+, RFSoC, HBM, Versal, and automotive/defense variants).
- `efinity` (also recognized as `efinix` by completion): 360 parts from the
  **Efinity June 2024 distribution**, covering both public families, **Trion** and
  **Titanium**, with their database-listed packages and timing grades.

Coverage is versioned, not a claim to include every future part or legacy ISE-only
device. No device/package/speed cross-products are fabricated. Tools need not be
installed to use these bundled suggestions. Later parts can be typed freely or
added by regenerating from a newer tool installation.

To regenerate, run `extension/scripts/export-device-catalog.py` from the repository
root, supplying an installation root and a descriptive version. For example:

```sh
python3 extension/scripts/export-device-catalog.py xilinx \
  --tool-root /path/to/Vivado/version --source-version 'Vivado VERSION / get_parts' \
  --output extension/resources/property/devices/xilinx.json
python3 extension/scripts/export-device-catalog.py efinix \
  --tool-root /path/to/efinity --source-version 'Efinity VERSION / device database' \
  --output extension/resources/property/devices/efinix.json
```

The exporter queries vendor APIs and stores family/chip/package/part names only;
it does not copy implementation databases, tool paths, or generated binaries.
