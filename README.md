# IPTCINFO 3
### Like IPTCInfo but finally compatible for Python 3

IPTCInfo: extract and modify IPTC (metadata) information on images - port of IPTCInfo.pm by Josh Carter <josh@multipart-mixed.com>'

Ported from Josh Carter's Perl IPTCInfo-1.9.pm by Tamas Gulacsi

Ever wish you add information to your photos like a caption, the place
you took it, the date, and perhaps even keywords and categories? You
already can. The International Press Telecommunications Council (IPTC)
defines a format for exchanging meta-information in news content, and
that includes photographs. You can embed all kinds of information in
your images. The trick is putting it to use.

That's where this IPTCInfo Python module comes into play. You can embed
information using many programs, including Adobe Photoshop, and
IPTCInfo will let your web server -- and other automated server
programs -- pull it back out. You can use the information directly in
Python programs, export it to XML, or even export SQL statements ready
to be fed into a database.

1.9.5-8: https://bitbucket.org/gthomas/iptcinfo/issue/4/file-permissions-for-changed-files-are-not - copy original file's permission bits on save/saveAs

1.9.5-7: https://bitbucket.org/gthomas/iptcinfo/issue/3/images-w-o-iptc-data-should-not-log-errors - have silencable parse errors.

1.9.5-6: to have a nice new upload (seems easy_install grabs an old version).

1.9.5-5: fix some issues with "super"

1.9.5-3: use logging module.

1.9.5-2: Emil Stenström pinpointed some bugs/misleading (un)comments
    Also a new (mis)feature is implemented: if you don't specify inp_charset
    (and the image misses such information, too) than no conversion is made
    to unicode, everything stays bytestring!
    This way you don't need to deal with charsets, BUT it is your risk to make
    the modifications with the SAME charset as it is in the image!

1.9.5-1: getting in sync with the Perl version 1.9.5

1.9.2-rc8:
    charset recognition loosened (failed with some image out of
    Adobe Lightroom).

1.9.2-rc7: NOT READY
    IPTCInfo now accepts 'inp_charset' keyword for setting input charset.

1.9.2-rc6: just PyLint-ed out some errors.

1.9.2-rc5: Amos Latteier sent me a patch which releases the requirement of the
    file objects to be file objects (he uses this on jpeg files stored in
    databases as strings).
        It modifies the module in order to look for a read method on the file
        object. If one exists it assumes the argument is a file object, otherwise it
        assumes it's a filename.

1.9.2-rc4: on Windows systems, tmpfile may not work correctly - now I use
    cStringIO on file save (to save the file without truncating it on Exception).

1.9.2-rc3: some little bug fixes, some safety enhancements (now iptcinfo.py
    will overwrite the original image file (info.save()) only if everything goes
    fine (so if an exception is thrown at writing, it won't cut your original
    file).

    This is a pre-release version: needs some testing, and has an unfound bug
    (yet): some pictures can be enhanced with iptc data, and iptcinfo.py is able
    to read them, but some other iptc data readers will spit on it.

1.9.1: a first release with some little encoding support

    The class IPTCInfo now has an inp_charset and an out_charset attribute - the
    first is the read image's charset (defaults to the system default charset),
    the second is the charset the writer will use (defaults to inp_charset).

    Reader will find the charset included in IPTC data (if any, defaults to the
    system's default charset), and use it to read to unicode strings. Writer will
    write using IPTCinfo.out_charset (if it is not set, will not write charset
    IPTC record).

    With this, it is possible to read and write i18n strings correctly.

    I haven't tested this functionality thoroughly, and that little test was only
    on my WinXP box only, with the only other IPTC reader: IrfanView.


SYNOPSIS

    from iptcinfo import IPTCInfo
    import sys

    fn = (len(sys.argv) > 1 and [sys.argv[1]] or ['test.jpg'])[0]
    fn2 = (len(sys.argv) > 2 and [sys.argv[2]] or ['test_out.jpg'])[0]

    # Create new info object
    info = IPTCInfo(fn)

    # Check if file had IPTC data
    if len(info.data) < 4: raise Exception(info.error)

    # Print list of keywords, supplemental categories, contacts
    print info.keywords
    print info.supplementalCategories
    print info.contacts

    # Get specific attributes...
    caption = info.data['caption/abstract']

    # Create object for file that may does have IPTC data.
    # info = IPTCInfo(fn)
    # for files without IPTC data, use
    info = IPTCInfo(fn, force=True)

    # Add/change an attribute
    info.data['caption/abstract'] = 'Witty caption here'
    info.data['supplemental category'] = ['portrait']

    # Save new info to file
    ##### See disclaimer in 'SAVING FILES' section #####
    info.save()
    info.saveAs(fn2)

    #re-read IPTC info
    print IPTCInfo(fn2)
