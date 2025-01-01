import json
from typing import Any

def read_json(path: str) -> Any:
    with open(path, 'r', encoding='utf-8') as fp:
        config = json.load(fp=fp)
    return config

def write_json(path: str, obj: object):
    with open(path, 'w', encoding='utf-8') as fp:
        json.dump(obj, fp=fp, indent=4, ensure_ascii=False)
        