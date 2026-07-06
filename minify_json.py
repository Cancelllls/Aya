import json
import sys
import glob
import os

def minify(file_path):
    print(f"Minifying {file_path}...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    original_size = os.path.getsize(file_path)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'), ensure_ascii=False)
        
    new_size = os.path.getsize(file_path)
    print(f"Original: {original_size/1024/1024:.2f} MB, New: {new_size/1024/1024:.2f} MB, Saved: {(original_size-new_size)/1024/1024:.2f} MB")

if __name__ == '__main__':
    for file in glob.glob('assets/hadith/*.json'):
        minify(file)
