#!/usr/bin/env python

import sys, os
import iptcinfo

iptcinfo.debugMode = 4

IPTCInfo = iptcinfo.IPTCInfo

fn = (len(sys.argv) > 0 and [sys.argv[1]] or ['test.jpg'])[0]
fn2 = '.'.join(fn.split('.')[:-1]) + '_o.jpg'
info = IPTCInfo(fn, force=True)
print info
info.data['urgency'] = 'GT'
info.keywords += ['ize']
print info
#info2.data[field] = ""
#print info2
info.saveAs(fn2)
info = IPTCInfo(fn2)
print info

