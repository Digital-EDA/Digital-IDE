from typing import List
import sys
import os
sys.path.append(os.path.abspath('.'))

from script.util import read_json, write_json

PACKAGE_FILE = './package.json'

LANG_PACKGE_FILES = {
    'en': './package.nls.json',
    'zh-cn': './package.nls.zh-cn.json',
    'zh-tw': './package.nls.zh-tw.json',
}

def generate_title_token(command_name: str) -> str:
    names = command_name.split('.')
    prj_name = names[0]
    main_names = names[1:]
    title_token_name = [prj_name] + main_names + ['title']
    return '.'.join(title_token_name)

def merge_tokens(lang_package_path: str, tokens: List[str]):
    config = read_json(lang_package_path)
    for token in tokens:
        if token not in config:
            config[token] = ""
    
    write_json(lang_package_path, config)

if __name__ == '__main__':
    # adjust main package
    config = read_json(PACKAGE_FILE)
    commands = config['contributes']['commands']
    token_names = []

    for c_item in commands:
        if 'command' in c_item:
            token_name = generate_title_token(c_item['command'])
            token_names.append(token_name)
            c_item['title'] = '%' + token_name + '%'
    write_json(PACKAGE_FILE, config)
    
    # cover in lang package
    for name, lang_path in LANG_PACKGE_FILES.items():
        merge_tokens(lang_path, token_names)