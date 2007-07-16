#!/usr/bin/env python
# -*- coding: utf-8 -*-
# :mode=python:encoding=UTF-8:
from iptcinfo import IPTCInfo
import sys

fn = (len(sys.argv) > 1 and [sys.argv[1]] or ['test.jpg'])[0]
fn2 = (len(sys.argv) > 2 and [sys.argv[2]] or ['test_out.jpg'])[0]

# Create new info object
info = IPTCInfo(fn, force=True)

# Check if file had IPTC data
# if len(info.data) < 4: raise Exception(info.error)

# Get list of keywords, supplemental categories, or contacts
keywords = info.keywords
suppCats = info.supplementalCategories
contacts = info.contacts

# Get specific attributes...
caption = info.data['caption/abstract']

# Create object for file that may or may not have IPTC data.
info = IPTCInfo(fn, force=True)

# Add/change an attribute
info.data['caption/abstract'] = 'árvíztűrő tükörfúrógép'
info.data['supplemental category'] = ['portrait']
info.data[123] = '123'
info.data['nonstandard_123'] = 'n123'

print info.data

# Save new info to file
##### See disclaimer in 'SAVING FILES' section #####
info.save()
info.saveAs(fn2)

#re-read IPTC info
print IPTCInfo(fn2)

