#!/bin/sh
VERSION=$(sed -ne '/^__version__/ { s/^[^0-9]*//;s/. *$//p }' iptcinfo.py)
echo VERSION=$VERSION
hg tags | grep -q $VERSION || {
  echo "tagging $VERSION"
  hg tag "iptcinfo-$VERSION" || exit 2
}
echo 'hg push...'  && hg push \
&& echo 'hg push bitbucket...' && hg push bitbucket \
&& echo 'python setup.py register...' && python setup.py -v register \
&& echo 'python setup.py sdist upload...' \
&& python setup.py sdist -d dist upload && {
  FILE=dist/IPTCInfo-${VERSION}.tar.gz
  echo "scp $FILE gho:html/python/..."
  scp -p $FILE gthomas@gthomas.homelinux.org:html/python/
  curl -T "$FILE" ftp://gthomas@ftp.fw.hu/gthomas/python/
}
