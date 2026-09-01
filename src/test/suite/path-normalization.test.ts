import * as assert from 'assert';
import {
    isPathSetting,
    normalizePathSettingValue,
    normalizeWindowsPath,
} from '../../utils/paths';

suite('Windows path normalization', () => {
    test('removes drive and UNC verbatim prefixes', () => {
        assert.strictEqual(
            normalizeWindowsPath('\\\\?\\D:\\Project\\FPGA\\top.sv'),
            'D:\\Project\\FPGA\\top.sv',
        );
        assert.strictEqual(
            normalizeWindowsPath('\\\\?\\unc\\server\\share\\top.vhd'),
            '\\\\server\\share\\top.vhd',
        );
        assert.strictEqual(
            normalizeWindowsPath('//?/UNC/server/share/top.vhd'),
            '//server/share/top.vhd',
        );
    });

    test('normalizes path settings without changing non-path settings', () => {
        assert.ok(isPathSetting('digital-ide.function.simulate.vendorCachePath'));
        assert.ok(!isPathSetting('digital-ide.standard.vhdl'));
        assert.deepStrictEqual(
            normalizePathSettingValue([
                '\\\\?\\C:\\Vivado',
                '\\\\?\\UNC\\server\\share',
            ]),
            ['C:\\Vivado', '\\\\server\\share'],
        );
        assert.deepStrictEqual(
            normalizePathSettingValue({
                executable: '\\\\?\\C:\\Vivado\\bin\\vivado.bat',
                nested: { cache: '//?/UNC/server/share/cache' },
            }),
            {
                executable: 'C:\\Vivado\\bin\\vivado.bat',
                nested: { cache: '//server/share/cache' },
            },
        );
    });
});
