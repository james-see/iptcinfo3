#!/bin/userenv python2.3
# -*- coding: utf-8 -*-
# Author: 2004 Gulácsi Tamás

classifiers = """\
Development Status :: 3 - Alpha
License :: OSI Approved :: Artistic License
License :: OSI Approved :: GNU General Public License (GPL)
Intended Audience :: Developers
Programming Language :: Python
Topic :: Multimedia :: Graphics
Topic :: Utilities
"""

from distutils.core import setup
from distutils.command.sdist import sdist as _sdist
import sys

if sys.version_info < (2, 3):
    _setup = setup

    def setup(**kwargs):
        if "classifiers" in kwargs:
            del kwargs["classifiers"]
            _setup(**kwargs)


class sdist(_sdist, object):
    def run(self):
        import os
        res = _sdist.run(self)
        print self.get_archive_files()
        for fn in self.get_archive_files():
            os.system('scp -p %s gtmainbox:/var/www/html/python/' % fn)
        return res


def openfile(fname):
    import os
    return open(os.path.join(os.path.dirname(__file__), fname))

version = (row.split('=', 1)[-1].strip().strip("'").strip('"')
    for row in open('iptcinfo.py', 'rU')
    if row.startswith('__version__')).next()
#~ version = '1.9.2-rc8'
#zipext = (sys.platform.startswith('Win') and ['zip'] or ['tar.gz'])[0]
setup(  # cmdclass={'sdist': sdist},
    name='IPTCInfo',
    version=version,
    url='http://bitbucket.org/gthomas/iptcinfo/downloads',
    download_url='http://bitbucket.org/gthomas/iptcinfo/get/'
        'iptcinfo-%s.tar.bz2' % version,
    author=u'Tamas Gulacsi',
    author_email='gthomas@fw.hu',
    maintainer=u'Tamas Gulacsi',
    maintainer_email='gthomas@fw.hu',
    long_description=openfile('README').read(),
    license='http://www.opensource.org/licenses/gpl-license.php',
    platforms=['any'],
    description=openfile('README').readline(),
    classifiers=filter(None, classifiers.split('\n')),
    py_modules=['iptcinfo'],
    )
