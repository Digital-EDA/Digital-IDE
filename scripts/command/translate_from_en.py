import sys
import os
sys.path.append(os.path.abspath('.'))
from typing import Dict

import requests as r
from zhconv import convert

from script.util import read_json, write_json


PACKAGE_FILE = './package.json'

LANG_PACKGE_FILES = {
    'en': './package.nls.json',
    'zh-cn': './package.nls.zh-cn.json',
    'zh-tw': './package.nls.zh-tw.json',
}

def youdao_translate(query: str, from_lang: str='AUTO', to_lang: str='AUTO') -> str:
    url = 'http://fanyi.youdao.com/translate'
    data = {
        "i": query,  # 待翻译的字符串
        "from": from_lang,
        "to": to_lang,
        "smartresult": "dict",
        "client": "fanyideskweb",
        "salt": "16081210430989",
        "doctype": "json",
        "version": "2.1",
        "keyfrom": "fanyi.web",
        "action": "FY_BY_CLICKBUTTION"
    }
    res = r.post(url, data=data).json()
    return res['translateResult'][0][0]['tgt']

def to_complex_zh(words: str) -> str:
    return convert(words, 'zh-tw')

def translate_from_en(en_config: Dict[str, str], target_config: Dict[str, str], target_lang_id: str):
    for command in target_config.keys():
        desc = target_config[command]
        if len(desc) == 0:
            en_desc = en_config.get(command, '')
            assert len(en_desc) > 0, f'command:{command} in en_config is empty'
            target_desc = youdao_translate(en_desc, from_lang='en', to_lang=target_lang_id)
            target_config[command] = target_desc

def translate_complex_zh(zh_config: Dict[str, str], zh_tw_config: Dict[str, str]):
    for command in zh_tw_config.keys():
        zh_desc = zh_config.get(command, '')
        assert len(zh_desc) > 0, f'{command} in zh_config is empty'
        complex_zh_desc = to_complex_zh(zh_desc)
        zh_tw_config[command] = complex_zh_desc


def main():
    en_config = read_json(LANG_PACKGE_FILES["en"])

    zh_cn_config = read_json(LANG_PACKGE_FILES["zh-cn"])
    zh_tw_config = read_json(LANG_PACKGE_FILES["zh-tw"])

    translate_from_en(en_config, zh_cn_config, 'zh')
    translate_complex_zh(zh_cn_config, zh_tw_config)

    write_json(LANG_PACKGE_FILES["zh-cn"], zh_cn_config)
    write_json(LANG_PACKGE_FILES["zh-tw"], zh_tw_config)

main()