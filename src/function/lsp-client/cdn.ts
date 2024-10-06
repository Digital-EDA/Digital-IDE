import * as os from 'os';

enum IPlatformSignature {
    x86Windows,
    aach64Windows,
    x86Darwin,
    aarch64Darwin,
    x86Linux,
    aarch64Linux,
    unsupport
};

function getPlatformPlatformSignature(): IPlatformSignature {
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

