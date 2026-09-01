const fs = require('fs');
const path = require('path');

const workspace = path.resolve(process.argv[2] ?? '');
const propertyPath = path.join(workspace, '.vscode', 'property.json');
if (!workspace || !fs.existsSync(propertyPath)) {
    throw new Error(`Xilinx demo workspace is missing ${propertyPath}`);
}

const property = JSON.parse(fs.readFileSync(propertyPath, 'utf8'));
if (String(property.toolChain ?? '').toLowerCase() !== 'xilinx') {
    throw new Error('Xilinx ILA demo requires property.json toolChain to be xilinx.');
}
const device = String(property.device ?? '').trim();
if (!device || device === 'none') {
    throw new Error('Xilinx ILA demo requires a concrete property.json device.');
}

const relativeOutput = path.join('prj', 'debugger', 'xilinx-ila-demo');
const output = path.join(workspace, relativeOutput);
const bin = path.join(output, 'bin');
fs.mkdirSync(bin, { recursive: true });

const bitstreamHash = '1ad145615b37d6d5d3f408e029ab0c30895d265091b1e42192bb036bdc04b24c';
const conditionsHash = 'd53d18c23212ea7b6300594bb89bce60218f6eff2b9d628b8cc42d3e79bbd5ab';
const top = 'xilinx_ila_demo_top';
const hardwareHash = 'xilinx-ila-demo-hardware-v1';

fs.writeFileSync(path.join(output, 'top.bit'), 'bitstream');
fs.writeFileSync(path.join(output, 'top.ltx'), 'bitstream');
fs.writeFileSync(path.join(output, 'conditions.tcl'), '[]');

const probe = (name, width, probeType) => ({
    name,
    debug_path: null,
    width,
    probe_type: probeType,
    probe_mode: 'data_and_trigger',
    direction: null,
    init_val: '0',
});
const vioProbe = (name, width, direction, initVal = 0) => ({
    ...probe(name, width, direction === null ? 'clock' : 'data'),
    direction,
    init_val: String(initVal),
});

fs.writeFileSync(path.join(output, 'debug_manifest.json'), `${JSON.stringify({
    version: 1,
    top,
    vendor: 'vivado',
    config_path: path.join(output, 'xilinx_ila_demo.debug.toml'),
    ila: [{
        id: 0,
        label: 'capture_bus',
        module_id: 0,
        uuid: 'xilinx-ila-demo-logical-uuid',
        data_depth: 1024,
        pipe_stages: 1,
        clock: probe('clk', 1, 'clock'),
        probes: [
            probe('counter', 8, 'data'),
            probe('valid', 1, 'data'),
        ],
        capture_condition: null,
        trigger_condition: null,
    }],
    vio: [{
        id: 0,
        label: 'control_bus',
        module_id: 1,
        uuid: 'xilinx-vio-demo-logical-uuid',
        clock: vioProbe('clk', 1, null),
        inputs: [vioProbe('status', 4, 'in')],
        outputs: [vioProbe('control', 4, 'out', 5)],
        input_activity: true,
    }],
    cascades: [],
    hardware_hash: hardwareHash,
}, null, 2)}\n`);

const artifactPath = file => path.join(relativeOutput, file).split(path.sep).join('/');
fs.writeFileSync(path.join(output, 'debugstamp.json'), `${JSON.stringify({
    version: 2,
    vendor: 'vivado',
    toolVersion: 'Vivado v2022.2 Digital-IDE ILA demo',
    device,
    top,
    hardwareHash,
    rtlHash: 'xilinx-ila-demo-rtl-v1',
    projectHash: 'xilinx-ila-demo-project-v1',
    bitstreamHash: 'xilinx-ila-demo-bitstream-v1',
    artifacts: [
        { kind: 'bitstream', path: artifactPath('top.bit'), hash: bitstreamHash },
        { kind: 'probes', path: artifactPath('top.ltx'), hash: bitstreamHash },
        { kind: 'conditions', path: artifactPath('conditions.tcl'), hash: conditionsHash },
    ],
    connection: {
        backend: 'vivado',
        probesHash: bitstreamHash,
        conditionsHash,
        coreUuids: {
            'ila:0': '00112233445566778899aabbccddeeff',
            'vio:0': 'ffeeddccbbaa99887766554433221100',
        },
    },
}, null, 2)}\n`);

const fakeVivado = `#!/usr/bin/python3.10
import os
import re
import sys

vio_value = 5
buffer = []
for line in sys.stdin:
    buffer.append(line)
    if line.strip() != 'flush stdout':
        continue
    request = ''.join(buffer)
    buffer = []
    match = re.search(r'__DIDE_BEGIN__:(\\d+)', request)
    if match is None:
        continue
    request_id = match.group(1)
    typed = []
    if 'write_hw_ila_data' in request:
        payload_match = re.search(r'-csv_file "([^\\"]+)"', request)
        if payload_match is not None:
            with open(payload_match.group(1), 'w', encoding='utf-8') as stream:
                stream.write('Radix - 2,,,Hex,Hex\\n')
                stream.write('Sample in Buffer,Sample in Window,TRIGGER,dide_ila_0/probe0,dide_ila_0/probe1\\n')
                for index in range(64):
                    trigger = 1 if index == 32 else 0
                    valid = 1 if (index // 8) % 2 == 0 else 0
                    stream.write(f'{index},{index},{trigger},{index:02x},{valid}\\n')
        typed.append('digital_server_debugger_capture:0')
        typed.append('digital_server_debugger_capture_timing:25:40:50:60')
    elif 'digital_server_debugger_status:' in request:
        typed.append('digital_server_debugger_status:7265616479:17')
    output_match = re.search(r'set_property OUTPUT_VALUE "([0-9a-fA-F]+)" \\$__dide_vio_output_0', request)
    if output_match is not None:
        vio_value = int(output_match.group(1), 16)
    if 'digital_server_debugger_vio_output:0' in request:
        value = ('0b' + format(vio_value, '04b')).encode().hex()
        typed.append('digital_server_debugger_vio_output:0:' + value)
    if 'digital_server_debugger_vio_input:0' in request:
        value = ('0b' + format(vio_value, '04b')).encode().hex()
        typed.append('digital_server_debugger_vio_input:0:' + value)
    print('__DIDE_BEGIN__:' + request_id)
    for record in typed:
        print(record)
    print('__DIDE_MSG__:' + request_id + ':')
    print('__DIDE_RC__:' + request_id + ':0')
    print('__DIDE_END__:' + request_id)
    sys.stdout.flush()
`;
fs.writeFileSync(path.join(bin, 'fake-vivado.py'), fakeVivado);
fs.writeFileSync(path.join(bin, 'vivado'), `#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
exec /usr/bin/python3.10 -B "$(dirname -- "$0")/fake-vivado.py" "$@"
`);
fs.chmodSync(path.join(bin, 'vivado'), 0o755);
fs.chmodSync(path.join(bin, 'fake-vivado.py'), 0o755);

process.stdout.write(`Prepared Xilinx ILA demo: ${output}\n`);
