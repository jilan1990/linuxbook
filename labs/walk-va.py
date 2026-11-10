#!/usr/bin/env python3
"""4KB, 48-bit, four-level example. No real page-table memory is read."""
import argparse
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('address',type=lambda s:int(s,0));a=p.parse_args().address
if not 0<=a<2**64:p.error('address must fit in 64 bits')
print(f'VA={a:#018x}')
for label,shift in [('L0',39),('L1',30),('L2',21),('L3',12)]:print(f'{label} index={(a>>shift)&0x1ff:#x}')
print(f'page offset={a&0xfff:#x}')
print('Index decomposition only; validate canonicality and actual TCR/config separately.')
