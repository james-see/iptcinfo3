#!/bin/sh
hg push && hg push bitbucket && python setup.py -v register && {
  FILE=$(ls -t dist/IPTCInfo-*.tar.gz| head -n 1)
  scp -p $FILE gthomas@gthomas.homelinux.org:html/python/
  curl -T "$FILE" -u "$PASSW" ftp://ftp.fw.hu/gthomas/python/
}
