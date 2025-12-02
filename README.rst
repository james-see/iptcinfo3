``IPTCINFO 3``
==============

Like IPTCInfo but finally compatible for Python 3
-------------------------------------------------


Ported from Josh Carter's Perl IPTCInfo-1.9.pm by Tamas Gulacsi

Ever wish you add information to your photos like a caption, the place
you took it, the date, and perhaps even keywords and categories? You
already can. The `International Press Telecommunications Council (IPTC) <https://en.wikipedia.org/wiki/International_Press_Telecommunications_Council>`_
defines a format for exchanging meta-information in news content, and
that includes photographs. You can embed all kinds of information in
your images. The trick is putting it to use.

That's where this IPTCInfo Python module comes into play. You can embed
information using many programs, including Adobe Photoshop, and
IPTCInfo will let your web server -- and other automated server
programs -- pull it back out. You can use the information directly in
Python programs, export it to XML, or even export SQL statements ready
to be fed into a database.

Wikidata item https://www.wikidata.org/wiki/Q137179516

Installation
------------

Install from PyPI::

    pip install IPTCInfo3

Or with uv::

    uv pip install IPTCInfo3

On Gentoo Linux: on `gentoo-zh overlay <https://github.com/microcai/gentoo-zh/tree/master/dev-python/iptcinfo3>`_.

Requirements
------------

- Python 3.8 or higher
- No external dependencies required

Usage
-----

``from iptcinfo3 import IPTCInfo``


Create new info object
``info = IPTCInfo('doge.jpg')``

Print list of keywords, supplemental categories, contacts
``print(info['keywords'])``
``print(info['supplementalCategories'])``
``print(info['contacts'])``

Get specific attributes...
``caption = info['caption/abstract']``

Create object for file that may not have IPTC data
``info = IPTCInfo('such_iptc.jpg', force=True)``

Add/change an attribute
``info['caption/abstract'] = 'Witty caption here'``
``info['supplemental category'] = ['portrait']``

Lists for keywords, so you can just append!
``info['keywords']).append('cool')``

Save new info to file
``info.save()``
``info.save_as('very_meta.jpg')``

For real life usage example see https://gitlab.com/vitaly-zdanevich/upload_to_commons_with_categories_from_iptc/-/blob/master/upload_to_commons_with_categories_from_iptc.py
