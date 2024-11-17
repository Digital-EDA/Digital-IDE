import requests as r
import os
import shutil
import zipfile

# 下载 压缩包
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
    'Cookie': 'cna=FeNcHjgPWA8CAXU/P9lD8IsF; EGG_SESS_ICONFONT=Hu68kBY7XO7C6Udp3T99M1asKmUZ0gxjps8xjTrjx4ZtNCIR_nFu9Li15nxoPAWLmGlcEMN2KEQyAvgBfASR3cSsmd2lhqg89lUmApzbWgBgCWjMwMzjawMqh2KNT8kCICxit3iWC7YLdUuCdUfXg_cGkRjPNvDohqyeHF27gTb5CloBSvLjqN45PcUvcUig; ctoken=Ku-GfnHTFQU6ObMjjX4rrwYn; u=10114852; u.sig=mv5vi-TPPlhvQJi2PMIC4VoPpD03Wc9UykMTMiG6ElA; xlly_s=1; tfstk=fSrIwBNqyBACtg2sZ2BZ5BUbpIn7PWsVNLM8n8KeeDnpwQex_JrEY887N5wxykyrvui717NU8DUUPYN4p7glKbl-N7y88OSV0J2nq0K5giSVfSIC9W9pv3B-6YMoT58eCJ2nqdvwwZzTKU6xnQBS27ntXvkj2HHKwO9tnfKKeHHJ6OMo6bn-9v39XxMD9e3Kpbdy1Y7IeJ69Kr6y7I-gLftJcKDKJZyez3-yav0nMVh62Arsd2GYpk3XwyMTblgq7L5ZX-4a9AifbenYCzFbk7b2SDw8J70_t1Ys_PE3eb3wenysPXaTvV9J2RmsN447O6Tn9yPsoA39FiDagfe3vP6k6JFqODHt7iBbB4UaxqqF6HiYoJoUy7b2SDw8JcszunlfpXTWCqxSCjW1CUYrE4jk1CVx8l3KIvIVCOO6r2HiCjW1CUYoJADLuO661Uf..; isg=BCwsfWsQZki1QXEWw0jCCc4h_Qpe5dCP-aVamIZsF1d6kc6br_ZyHmFnsVkpGQjn',
    'Pragma': 'no-cache',
    'sec-fetch-mode': 'navigate'
}



url = 'https://www.iconfont.cn/api/project/download.zip?spm=a313x.manage_type_myprojects.i1.d7543c303.21213a81tE9WyY&pid=4748764&ctoken=QcRJGHx0m7kL39pW1Slgy_E8'
res = r.get(url, headers=headers)

if res.status_code:
    with open('./script/tmp.zip', 'wb') as fp:
        fp.write(res.content)

# 解压文件
with zipfile.ZipFile('./script/tmp.zip', 'r') as zipf:
    zipf.extractall('./script/tmp')

# 将文件搬运至工作区，我的 css 全放在 public 下面了，你的视情况而定
for parent, _, files in os.walk('./script/tmp'):
    for file in files:
        filepath = os.path.join(parent, file)
        if file.startswith('demo'):
            continue
        if file.endswith('.css'):
            content = open(filepath, 'r', encoding='utf-8').read().replace('font-size: 16px;', '')
            open(filepath, 'w', encoding='utf-8').write(content)
            shutil.move(filepath, os.path.join('./resources/dide-doc', file))
        elif file.endswith('.woff2'):
            shutil.move(filepath, os.path.join('./resources/dide-doc', file))

# 删除压缩包和解压区域
os.remove('./script/tmp.zip')
shutil.rmtree('./script/tmp')