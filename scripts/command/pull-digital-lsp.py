import tarfile
import os

import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--version', default='0.4.0')
args = parser.parse_args()
version_string = args.version

def compress_to_tar_gz(source_dir, output_filename):
    with tarfile.open(output_filename, "w:gz") as tar:
        if os.path.isdir(source_dir):
            # 如果是目录，递归添加目录中的所有文件
            for root, dirs, files in os.walk(source_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, source_dir)
                    tar.add(file_path, arcname=arcname)
        else:
            # 如果是文件，直接添加文件
            tar.add(source_dir, arcname=os.path.basename(source_dir))

os.system('scp -P 8024 dide@nc-ai.cn:/home/dide/project/digital-lsp-server/target/release/digital-lsp digital-lsp')
compress_to_tar_gz('digital-lsp', f'digital-lsp_{version_string}_linux_amd64.tar.gz')

os.system('scp -P 8024 dide@nc-ai.cn:/home/dide/project/digital-lsp-server/target/aarch64-unknown-linux-gnu/release/digital-lsp digital-lsp')
compress_to_tar_gz('digital-lsp', f'digital-lsp_{version_string}_linux_aarch64.tar.gz')

os.system('scp -P 8024 dide@nc-ai.cn:/home/dide/project/digital-lsp-server/target/x86_64-pc-windows-gnu/release/digital-lsp.exe digital-lsp.exe')
compress_to_tar_gz('digital-lsp.exe', f'digital-lsp_{version_string}_windows_amd64.tar.gz')

os.system('scp -P 8024 dide@nc-ai.cn:/home/dide/project/digital-lsp-server/target/aarch64-pc-windows-msvc/release/digital-lsp.exe digital-lsp.exe')
compress_to_tar_gz('digital-lsp.exe', f'digital-lsp_{version_string}_windows_aarch64.tar.gz')

os.system('scp -P 8024 dide@nc-ai.cn:/home/dide/project/digital-lsp-server/target/x86_64-apple-darwin/release/digital-lsp digital-lsp')
compress_to_tar_gz('digital-lsp', f'digital-lsp_{version_string}_darwin_amd64.tar.gz')

os.system('scp -P 8024 dide@nc-ai.cn:/home/dide/project/digital-lsp-server/target/aarch64-apple-darwin/release/digital-lsp digital-lsp')
compress_to_tar_gz('digital-lsp', f'digital-lsp_{version_string}_darwin_aarch64.tar.gz')

