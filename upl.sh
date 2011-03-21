#!/bin/sh
hg push && hg push bitbucket && python setup.py -v register && {
  FILE=$(ls -t dist/IPTCInfo-*.tar.gz| head -n 1)
  scp -p $FILE gthomas.homelinux.org:/var/www/html/python/
  wput $FILE ftp://gthomas@ftp.fw.hu/gthomas/python/
}
