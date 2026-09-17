import { createScanner, findNodeAtLocation, getLocation, parseTree, SyntaxKind } from 'jsonc-parser';

export interface DeviceCatalog {
    schemaVersion: number;
    vendor: string;
    source: string;
    families: Record<string, Record<string, Record<string, string[]>>>;
}

export interface DeviceSuggestion {
    label: string;
    value: string;
    stage: 'family' | 'device' | 'package' | 'part';
    detail: string;
}

export function deviceValueContext(text: string, offset: number): {
    vendor: 'xilinx' | 'efinix'; prefix: string; start: number; end: number;
} | undefined {
    const scanner = createScanner(text);
    for (let kind = scanner.scan(); kind !== SyntaxKind.EOF; kind = scanner.scan()) {
        if (scanner.getTokenOffset() > offset) {break;}
        if (offset >= scanner.getTokenOffset() && offset <= scanner.getTokenOffset() + scanner.getTokenLength()
            && (kind === SyntaxKind.LineCommentTrivia || kind === SyntaxKind.BlockCommentTrivia)) {return undefined;}
    }
    const location = getLocation(text, offset);
    if (location.isAtPropertyKey || location.path.length !== 1 || location.path[0] !== 'device') {
        return undefined;
    }
    const tree = parseTree(text, [], { allowTrailingComma: true, disallowComments: false });
    const toolChain = tree && findNodeAtLocation(tree, ['toolChain'])?.value;
    const vendor = toolChain === 'xilinx' ? 'xilinx'
        : toolChain === 'efinity' || toolChain === 'efinix' ? 'efinix' : undefined;
    if (!vendor) {
        return undefined;
    }
    const node = location.previousNode;
    if (node) {
        if (node.type !== 'string' || offset < node.offset + 1 || offset > node.offset + node.length) {
            return undefined;
        }
        const end = node.offset + node.length;
        const contentEnd = text[end - 1] === '"' ? end - 1 : end;
        return {
            vendor,
            prefix: text.slice(node.offset + 1, Math.min(offset, contentEnd)),
            start: node.offset,
            end,
        };
    }
    return { vendor, prefix: '', start: offset, end: offset };
}

function familyPrefix(device: string): string {
    return device.match(/^(?:x[a-z]+(?:7[a-z]+)?|Ti|Tz|T)/i)?.[0] ?? device;
}

export function suggestDevices(catalog: DeviceCatalog, input: string): DeviceSuggestion[] {
    const prefix = input.toLowerCase();
    const families = Object.entries(catalog.families);
    const records = families.flatMap(([family, devices]) => Object.entries(devices)
        .flatMap(([device, packages]) => Object.entries(packages)
            .flatMap(([packageName, parts]) => parts.map(part => ({ family, device, packageName, part })))));
    const matching = records.filter(record => record.part.toLowerCase().startsWith(prefix));
    if (matching.length === 0) {
        return [];
    }
    const exactParts = matching.filter(record => record.part.toLowerCase() === prefix);
    if (exactParts.length) {
        return exactParts.map(record => ({ label: record.part, value: record.part, stage: 'part', detail: record.family }));
    }
    const packageSelected = matching.some(record => record.packageName.toLowerCase() === prefix);
    const deviceSelected = matching.some(record => record.device.toLowerCase() === prefix);
    const result = new Map<string, DeviceSuggestion>();
    const add = (value: string, stage: DeviceSuggestion['stage'], detail: string, label = value): void => {
        const key = `${stage}:${value}`;
        const previous = result.get(key);
        if (previous) {
            if (!previous.detail.split(' / ').includes(detail)) {previous.detail += ` / ${detail}`;}
        } else {
            result.set(key, { label, value, stage, detail });
        }
    };
    for (const [family] of families) {
        const members = matching.filter(record => record.family === family);
        if (!members.length) {continue;}
        for (const record of members) {
            const groupPrefix = familyPrefix(record.device);
            if (!packageSelected && !deviceSelected && groupPrefix.toLowerCase().startsWith(prefix)
                && prefix.length < groupPrefix.length) {
                add(groupPrefix, 'family', family, groupPrefix);
            } else if (packageSelected || prefix.length >= record.packageName.length) {
                add(record.part, 'part', family);
            } else if (deviceSelected || prefix.length >= record.device.length) {
                add(record.packageName, 'package', family);
            } else {
                add(record.device, 'device', family);
            }
        }
    }
    return [...result.values()].sort((a, b) => a.value.localeCompare(b.value, 'en', { numeric: true }));
}
