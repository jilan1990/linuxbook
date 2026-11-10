#!/usr/bin/env python3
"""Create deterministic gzip newc; no root or host mknod required."""
from pathlib import Path
import gzip, os, stat, sys

def encode_entry(name, mode, data=b'', ino=1, rmajor=0, rminor=0):
    names=name.encode('utf-8')+b'\0'
    fields=[ino,mode,0,0,2 if stat.S_ISDIR(mode) else 1,0,len(data),0,0,rmajor,rminor,len(names),0]
    header=b'070701'+b''.join(f'{v:08x}'.encode('ascii') for v in fields)
    record=header+names
    record+=b'\0'*((-len(record))%4)
    record+=data
    record+=b'\0'*((-len(data))%4)
    return record

def make_archive(root):
    buf=bytearray();ino=1
    if (root/'dev').exists() and not (root/'dev').is_dir():
        raise ValueError('ROOT/dev must be a directory')
    if not (root/'dev').exists():
        buf+=encode_entry('dev',stat.S_IFDIR|0o755,ino=ino);ino+=1
    for p in sorted(root.rglob('*'),key=lambda p:p.relative_to(root).as_posix()):
        name=p.relative_to(root).as_posix()
        if name=='dev/console':continue
        if p.is_symlink():mode=stat.S_IFLNK|0o777;data=os.readlink(p).encode()
        elif p.is_dir():mode=stat.S_IFDIR|0o755;data=b''
        elif p.is_file():mode=stat.S_IFREG|stat.S_IMODE(p.stat().st_mode);data=p.read_bytes()
        else:raise ValueError(f'Unsupported input: {p}')
        buf+=encode_entry(name,mode,data,ino);ino+=1
    buf+=encode_entry('dev/console',stat.S_IFCHR|0o600,ino=ino,rmajor=5,rminor=1)
    buf+=encode_entry('TRAILER!!!',0,ino=ino+1)
    buf+=b'\0'*((-len(buf))%512)
    return bytes(buf)

if __name__=='__main__':
    if len(sys.argv)!=3:raise SystemExit('usage: mkinitramfs.py ROOT OUTPUT.cpio.gz')
    root=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve()
    if not (root/'init').is_file():raise SystemExit('ROOT/init is required')
    out.parent.mkdir(parents=True,exist_ok=True)
    with out.open('wb') as f:
        with gzip.GzipFile(filename='',mode='wb',fileobj=f,mtime=0) as gz:gz.write(make_archive(root))
    print(out)
