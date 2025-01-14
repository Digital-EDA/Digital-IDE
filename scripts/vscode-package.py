import os
import shutil
import zipfile
from colorama import Fore, Style
from typing import List, Union
from collections import namedtuple

Command = namedtuple(typename='Command', field_names=['name', 'cmd'])

class CommandPipe:
    def __init__(self) -> None:
        self.pipes: List[Command] = []
    
    def add_command(self, name: str, cmd: str):
        command = Command(name, cmd)
        self.pipes.append(command)

    def run(self):
        for i, p in enumerate(self.pipes):
            progress = int((i + 1) / len(self.pipes) * 100)
            space_prefix = ' ' if progress < 100 else ''
            print(Fore.GREEN, f'[{space_prefix}{progress}%]', Style.RESET_ALL, p.name)
            if callable(p.cmd):
                p.cmd()
            elif isinstance(p.cmd, str):
                os.system(p.cmd)
        print('Done! :D')


def remove_folder(name: str):
    if os.path.exists(name):
        shutil.rmtree(name)

def copy_dir(src, dist):
    if os.path.exists(dist):
        shutil.rmtree(dist)
    shutil.copytree(src, dist)

def copy_file(src, dist):
    if os.path.exists(dist):
        os.remove(dist)
    dirname = os.path.dirname(dist)
    if not os.path.exists(dirname):
        os.makedirs(dirname)
    shutil.copyfile(src, dist)

def modify_vsix():
    vsix_filter = filter(lambda file: file.endswith('.vsix'), os.listdir('.'))
    vsix_file = list(vsix_filter)
    if len(vsix_file) == 0:
        print(Fore.RED, 'no .vsix is detected', Style.RESET_ALL)
        exit()
    vsix_path = vsix_file[0]
    if not os.path.exists('dist'):
        os.mkdir('dist')

    dist_path = os.path.join('dist', vsix_path.replace('.vsix', '.zip'))
    shutil.move(vsix_path, dist_path)

    extract_folder = os.path.join('dist', 'digital-ide-temp')
    with zipfile.ZipFile(dist_path, 'r') as zip_ref:
        zip_ref.extractall(extract_folder)
    
    os.remove(dist_path)

    # webview
    print("move netlist")
    copy_dir('./resources/dide-netlist/view', os.path.join(extract_folder, 'extension', 'resources', 'dide-netlist', 'view'))
    copy_dir('./resources/dide-netlist/static/share', os.path.join(extract_folder, 'extension', 'resources', 'dide-netlist', 'static', 'share'))
    copy_file('./resources/dide-netlist/static/yosys.wasm', os.path.join(extract_folder, 'extension', 'resources', 'dide-netlist', 'static', 'yosys.wasm'))

    print("move vcd")
    copy_dir('./resources/dide-viewer/view', os.path.join(extract_folder, 'extension', 'resources', 'dide-viewer', 'view'))

    # remake
    target_path = os.path.join('dist', vsix_path)
    zip_dir(extract_folder, target_path)
    


def zip_dir(dirpath, outFullName):
    zip = zipfile.ZipFile(outFullName, "w", zipfile.ZIP_DEFLATED)
    for path, _, filenames in os.walk(dirpath):
        fpath = path.replace(dirpath, '')
        for filename in filenames:
            zip.write(os.path.join(path, filename), os.path.join(fpath, filename))
    zip.close()

def install_extension():
    vsix_filter = filter(lambda file: file.endswith('.vsix'), os.listdir('dist'))
    vsix_files = list(vsix_filter)
    if len(vsix_files) == 0:
        print(Fore.RED, 'no .vsix is detected in dist', Style.RESET_ALL)
        exit()

    vsix_path = os.path.join('dist', vsix_files[0])
    os.system('code --install-extension ' + vsix_path)

if os.path.exists('dist'):
    shutil.rmtree('dist')

pipe = CommandPipe()
pipe.add_command('uninstall original extension', 'code --uninstall-extension sterben.fpga-support')
pipe.add_command('compile typescript', 'tsc -p ./ --outDir out-js')
pipe.add_command('webpack', 'webpack --mode production')
pipe.add_command('make vsix installer', 'vsce package')
pipe.add_command('modify vsix installer', lambda : modify_vsix())
# pipe.add_command('remove out-js', lambda : remove_folder('out-js'))
# pipe.add_command('remove out', lambda : remove_folder('out'))
pipe.add_command('install', lambda : install_extension())

pipe.run()