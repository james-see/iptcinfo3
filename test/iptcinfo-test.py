#!/usr/bin/env python
# :mode=python:encoding=ISO-8859-2:
# -*- coding: utf-8 -*-
# Author: 2004 Gulácsi Tamás

import sys
sys.path.insert(0, '.')
from iptcinfo import IPTCInfo, LOG, LOGDBG

if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.DEBUG)
    LOGDBG.setLevel(logging.DEBUG)
    if len(sys.argv) > 1:
        info = IPTCInfo(sys.argv[1],True)
        info.keywords = [u'test']
        info.supplementalCategories = []
        info.contacts = []
        print >>sys.stderr,"info = %s\n%s" % (info,"="*30)
        info.save()
