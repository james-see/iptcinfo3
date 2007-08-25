#!/usr/bin/env python
import iptcinfo, sys

if len(sys.argv) != 2:
  print """usage = list file.jpg"""
  sys.exit()
fn = sys.argv[1]

info = iptcinfo.IPTCInfo(fn, force=True)
print info

