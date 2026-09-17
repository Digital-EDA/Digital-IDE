# fsdb2fst source

`fsdb2fst.cpp` is copied from Tencent/wave-mcp commit
`867df476d699275351fdc4caaedf8fd9d5164223` and is licensed under MIT by its
authors. It is source-only: Digital-IDE never redistributes Synopsys/Verdi
headers, shared libraries, or a converter binary.

On Linux, `digital-server wave-mcp` can compile this source into the current user's cache when
`FSDB2FST_FREADER`, `VERDI_HOME`, or `NOVAS_HOME` identifies a legal
FsdbReader installation. The `fst/` directory is the GTKWave libfst writer
snapshot used by the same upstream commit. `fstapi` and FastLZ carry MIT
notices; LZ4 carries its BSD 2-Clause notice. Release packaging
places this source bundle beside the Linux executable so installed VSIX builds
retain the same on-demand behavior.

The resulting binary is a local cache artifact and must not be committed or
included in a VSIX.
