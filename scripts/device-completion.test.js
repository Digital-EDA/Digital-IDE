const assert = require('node:assert/strict');
const { test } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { deviceValueContext, suggestDevices } = require('../out/project/deviceCatalog');
const root = path.resolve(__dirname, '..');
const catalogs = Object.fromEntries(['xilinx', 'efinix'].map(vendor => [vendor,
    JSON.parse(fs.readFileSync(path.join(root, 'resources/property/devices', vendor + '.json'), 'utf8'))]));

function context(source) {
    const offset = source.indexOf('|');
    const text = source.replace('|', '');
    return { text, result: deviceValueContext(text, offset) };
}

test('only completes the root device value, using the current document toolChain', () => {
    assert.equal(context('{"toolChain":"xilinx","device":"xc7|"}').result.vendor, 'xilinx');
    assert.equal(context('{"device":"Ti|", "toolChain":"efinity"}').result.vendor, 'efinix');
    assert.equal(context('{"device":"T|", "toolChain":"efinix"}').result.vendor, 'efinix');
    for (const source of [
        '{"device":"|"}', '{"toolChain":"quartus","device":"|"}',
        '{"toolChain":"xilinx","nested":{"device":"|"}}',
        '{"toolChain":"xilinx","dev|ice":""}',
        '{"toolChain":"xi|linx","device":""}',
        '{"toolChain":"xilinx","device": /* | */ ""}',
        '{"toolChain":"xilinx","device":12|}',
    ]) assert.equal(context(source).result, undefined, source);
});

test('handles comments, unfinished JSON and replacing an existing quoted value', () => {
    for (const source of [
        '{"toolChain":"xilinx", // comment\n"device":"xc7|"}',
        '{"toolChain":"xilinx","device":"xc7|',
        '{"toolChain":"xilinx","device":|}',
        '{"toolChain":"xilinx","device":"xc7|incorrect-suffix",}',
    ]) {
        const { text, result } = context(source);
        assert.ok(result, source);
        const edited = text.slice(0, result.start) + JSON.stringify('xc7z020clg400-2') + text.slice(result.end);
        const { parse } = require('jsonc-parser');
        assert.equal(parse(edited).device, 'xc7z020clg400-2');
        assert.equal(parse(edited).toolChain, 'xilinx');
    }
});

test('progressively completes Xilinx and Efinix without inventing package/speed combinations', () => {
    for (const [vendor, stages] of [
        ['xilinx', ['xc7z', 'xc7z020', 'xc7z020clg400', 'xc7z020clg400-2']],
        ['efinix', ['Ti', 'Ti60', 'Ti60F100S3F2', 'Ti60F100S3F2-C4']],
    ]) {
        let input = '';
        for (const value of stages) {
            const suggestions = suggestDevices(catalogs[vendor], input);
            assert.ok(suggestions.some(item => item.value === value), `${vendor}: ${input} -> ${value}`);
            assert.ok(suggestions.every(item => item.value.toLowerCase().startsWith(input.toLowerCase())));
            input = value;
        }
        assert.ok(suggestDevices(catalogs[vendor], input.toLowerCase()).some(item => item.value === input));
        assert.deepEqual(suggestDevices(catalogs[vendor], 'custom-future-part'), []);
    }
    assert.ok(suggestDevices(catalogs.efinix, 'T').some(item => item.value === 'T20'));
    assert.ok(suggestDevices(catalogs.xilinx, 'XC7Z020CLG400-').some(item => item.value === 'xc7z020clg400-2'));
});

test('every catalog family and every complete part is reachable', () => {
    for (const catalog of Object.values(catalogs)) {
        const initial = suggestDevices(catalog, '');
        for (const [family, devices] of Object.entries(catalog.families)) {
            assert.ok(initial.some(item => item.detail.split(' / ').includes(family)), family);
            for (const [chip, packages] of Object.entries(devices)) {
                const packageSuggestions = suggestDevices(catalog, chip);
                for (const [prefix, parts] of Object.entries(packages)) {
                    assert.ok(packageSuggestions.some(item => item.value === prefix), `${chip} -> ${prefix}`);
                    assert.ok(parts.every(part => part.toLowerCase().startsWith(chip.toLowerCase())), chip);
                    const items = suggestDevices(catalog, prefix);
                    for (const part of parts) assert.ok(items.some(item => item.value === part), part);
                }
            }
        }
    }
    assert.equal(Object.keys(catalogs.xilinx.families).length, 41);
    assert.deepEqual(Object.keys(catalogs.efinix.families).sort(), ['Titanium', 'Trion']);
});

test('device remains free-form and device mutation commands are not contributed', () => {
    const schema = JSON.parse(fs.readFileSync(path.join(root, 'resources/property/property-schema.json'), 'utf8'));
    assert.deepEqual(Object.keys(schema.properties.device).sort(), ['description', 'type']);
    const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
    assert.equal(pkg.contributes.commands.some(c => /digital-ide\.pl\.(addDevice|delDevice)$/.test(c.command)), false);
    for (const file of ['src/project/commands.ts', '../src/server/project.rs']) {
        assert.doesNotMatch(fs.readFileSync(path.join(root, file), 'utf8'), /[Aa]ddDevice|[Dd]elDevice/);
    }
});
