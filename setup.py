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
        print((self.get_archive_files()))
        for fn in self.get_archive_files():
            os.system('scp -p %s gtmainbox:/var/www/html/python/' % fn)
        return res


def openfile(fname):
    import os
    return open(os.path.join(os.path.dirname(__file__), fname))

version = next((row.split('=', 1)[-1].strip().strip("'").strip('"')
    for row in open('iptcinfo.py', 'rU')
    if row.startswith('__version__')))
#~ version = '1.9.2-rc8'
#zipext = (sys.platform.startswith('Win') and ['zip'] or ['tar.gz'])[0]
setup(  # cmdclass={'sdist': sdist},
    name='IPTCInfo3',
    version=version,
    url='https://github.com/jamesacampbell/iptcinfo3',
    download_url='https://github.com/jamesacampbell/iptcinfo3',
    author='Tamas Gulacsi',
    author_email='gthomas@fw.hu',
    maintainer='James Campbell',
    maintainer_email='james@jamescampbell.us',
    long_description=openfile('README.md').read(),
    license='http://www.opensource.org/licenses/gpl-license.php',
    platforms=['any'],
    description=openfile('README.md').readline(),
    classifiers=[_f for _f in classifiers.split('\n') if _f],
    py_modules=['iptcinfo3'],
    )
