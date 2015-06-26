#!/usr/bin/env python
# :mode=python:encoding=utf-8
# -*- coding: utf-8 -*-

import sys
sys.path.insert(0, '.')
from iptcinfo import IPTCInfo, LOG, LOGDBG

if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.DEBUG)
    LOGDBG.setLevel(logging.DEBUG)
    if len(sys.argv) > 1:
        info = IPTCInfo(sys.argv[1],True)
        info.keywords = ['test']
        info.supplementalCategories = []
        info.contacts = []
        print("info = %s\n%s" % (info,"="*30), file=sys.stderr)
        info.save()
