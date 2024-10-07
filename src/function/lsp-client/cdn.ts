import * as os from 'os';
import axios from 'axios';

enum IPlatformSignature {
    x86Windows = 'windows_amd64',
    aach64Windows = 'windows_aarch64',
    x86Darwin = 'darwin_amd64',
    aarch64Darwin = 'darwin_aarch64',
    x86Linux = 'linux_amd64',
    aarch64Linux = 'linux_aarch64',
    unsupport = 'unsupport'
};

export function getPlatformPlatformSignature(): IPlatformSignature {
    // Possible values are `'arm'`, `'arm64'`, `'ia32'`, `'mips'`,`'mipsel'`, `'ppc'`, `'ppc64'`, `'s390'`, `'s390x'`, `'x32'`, and `'x64'`
    const arch = os.arch();

    // Possible values are `'aix'`, `'darwin'`, `'freebsd'`,`'linux'`, `'openbsd'`, `'sunos'`, and `'win32'`.
    const osName = os.platform();

    switch (arch) {
        case 'arm':
        case 'arm64':
            switch (osName) {
                case 'win32': return IPlatformSignature.aach64Windows;
                case 'darwin': return IPlatformSignature.aarch64Darwin;
                case 'linux': return IPlatformSignature.aarch64Linux;
                default: return IPlatformSignature.unsupport;
            }
        
        case 'x32':
        case 'x64':
            switch (osName) {
                case 'win32': return IPlatformSignature.x86Windows;
                case 'darwin': return IPlatformSignature.x86Darwin;
                case 'linux': return IPlatformSignature.x86Linux;
                default: return IPlatformSignature.unsupport;
            }
    
        default: return IPlatformSignature.unsupport;
    }
}

// const link1 = 'https://gitee.com/Digital-IDE/Digital-IDE/releases/download/0.4.0/digital-lsp_0.4.0_darwin_aarch64.tar.gz';
// const link2 = 'https://github.com/Digital-EDA/Digital-IDE/releases/download/0.4.0/digital-lsp_0.4.0_darwin_aarch64.tar.gz';

export function getGithubDownloadLink(signature: string, version: string): string {
    return `https://github.com/Digital-EDA/Digital-IDE/releases/download/${version}/digital-lsp_${version}_${signature}.tar.gz`;
}

export function getGiteeDownloadLink(signature: string, version: string): string {
    return `https://gitee.com/Digital-IDE/Digital-IDE/releases/download/${version}/digital-lsp_${version}_${signature}.tar.gz`;
}