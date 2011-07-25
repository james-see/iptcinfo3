#!/bin/sh
hg push && hg push bitbucket && python setup.py -v register \
  && python setup.py sdist -d dist upload && {
    FILE=$(ls -t dist/IPTCInfo-*.tar.gz| head -n 1)
    scp -p $FILE gthomas@gthomas.homelinux.org:html/python/
    curl -T "$FILE" ftp://gthomas@ftp.fw.hu/gthomas/python/
  }
