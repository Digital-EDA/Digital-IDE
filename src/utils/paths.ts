const verbatimUncPrefix = '\\\\?\\UNC\\';
const verbatimPrefix = '\\\\?\\';
const forwardVerbatimUncPrefix = '//?/UNC/';
const forwardVerbatimPrefix = '//?/';

function startsWithIgnoreCase(value: string, prefix: string): boolean {
    return value.slice(0, prefix.length).toLowerCase() === prefix.toLowerCase();
}

export function normalizeWindowsPath(value: string): string {
    if (startsWithIgnoreCase(value, verbatimUncPrefix)) {
        return `\\\\${value.slice(verbatimUncPrefix.length)}`;
    }
    if (startsWithIgnoreCase(value, verbatimPrefix)) {
        return value.slice(verbatimPrefix.length);
    }
    if (startsWithIgnoreCase(value, forwardVerbatimUncPrefix)) {
        return `//${value.slice(forwardVerbatimUncPrefix.length)}`;
    }
    if (startsWithIgnoreCase(value, forwardVerbatimPrefix)) {
        return value.slice(forwardVerbatimPrefix.length);
    }
    return value;
}

export function normalizePathSettingValue(value: unknown): unknown {
    if (typeof value === 'string') {
        return normalizeWindowsPath(value);
    }
    if (Array.isArray(value)) {
        return value.map(normalizePathSettingValue);
    }
    if (value !== null && typeof value === 'object') {
        return Object.fromEntries(
            Object.entries(value).map(([key, child]) => [key, normalizePathSettingValue(child)]),
        );
    }
    return value;
}

export function isPathSetting(key: string): boolean {
    return key.toLowerCase().includes('path');
}
