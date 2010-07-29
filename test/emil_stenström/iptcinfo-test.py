#!/usr/bin/env python
# -*- coding: utf-8 -*-

try:
    from iptcinfo import IPTCInfo
except ImportError:
    import sys, os
    sys.path.insert(0, os.path.join(os.pardir, os.pardir))
    from iptcinfo import IPTCInfo

if __name__ == '__main__':
    iptc = IPTCInfo(sys.argv[1], force=True)
    caption = iptc.data["caption/abstract"] or u'árvíztűrő Dag 1 tükörfúrógép'
    newcaption = caption.replace("Dag 1", "Dag 2")
    iptc.data["caption/abstract"] = newcaption
    iptc.saveAs(sys.argv[1].rsplit('.', 1)[0] + '-t.jpg') 
