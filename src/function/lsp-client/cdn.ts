import axios from 'axios';
import { performance } from 'perf_hooks';

export function getLspFileName(version: string, signature: string) {
    return `digital-lsp-${signature}.tar.gz`;
}

// const link1 = 'https://gitee.com/Digital-EDA/digital-lsp/releases/download/0.4.1/digital-lsp-aarch64-win.tar.gz';
// const link2 = 'https://github.com/Digital-EDA/digital-lsp/releases/download/0.4.1/digital-lsp-aarch64-win.tar.gz';



export function getGithubDownloadLink(signature: string, version: string): string {
    const filename = getLspFileName(version, signature);
    return `https://github.com/Digital-EDA/Digital-IDE/releases/download/${version}/${filename}`;
}

export function getGiteeDownloadLink(signature: string, version: string): string {
    const filename = getLspFileName(version, signature);
    return `https://gitee.com/Digital-EDA/Digital-IDE/releases/download/${version}/${filename}`;
}

function measureRequestTimecost(url: string, timeout: number = 5): Promise<number> {
    let s = performance.now();

    let timer: NodeJS.Timeout;

    const responseP = axios.get(url, { responseType: 'stream' });

    return new Promise<number>((resolve, reject) => {
        // 设置超时计时器
        timer = setTimeout(() => {
            resolve(Infinity);
        }, timeout);

        responseP.then(response => {
            // 清除超时计时器
            clearTimeout(timer);

            const totalLength = response.headers['content-length'];
            if (totalLength > 0) {
                resolve(performance.now() - s);
            } else {
                resolve(Infinity);
            }
        }).catch(error => {
            // 清除超时计时器
            clearTimeout(timer);
            reject(error);
        });
    });
}

export async function chooseBestDownloadSource(signature: string, version: string, timeout: number = 3000) {
    const links = [
        // TODO: lsp update
        getGithubDownloadLink(signature, '0.4.1'),
        getGiteeDownloadLink(signature, '0.4.1')
    ];
    const pools: Promise<number>[] = [];
    for (const link of links) {
        pools.push(measureRequestTimecost(link, timeout));
    }
    let fastTc = Infinity;
    let fastTcIndex = -1;
    for (let i = 0; i < pools.length; ++ i) {
        const tc = await pools[i];
        if (tc < fastTc) {
            fastTc = tc;
            fastTcIndex = i;
        }
    }
    if (fastTcIndex == -1) {
        return links[0];
    }
    return links[fastTcIndex];
}