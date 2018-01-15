import os

from iptcinfo3 import IPTCInfo


def test_getitem_can_read_info():
    info = IPTCInfo('fixtures/Lenna.jpg')

    assert len(info) >= 4
    assert info['keywords'] == [b'lenna', b'test']
    assert info['supplemental category'] == [b'supplemental category']
    assert info['caption/abstract'] == b'I am a caption'


def test_save_as_saves_as_new_file_with_info():
    if os.path.isfile('fixtures/deleteme.jpg'):
        os.unlink('fixtures/deleteme.jpg')

    info = IPTCInfo('fixtures/Lenna.jpg')
    info.save_as('fixtures/deleteme.jpg')

    info2 = IPTCInfo('fixtures/deleteme.jpg')

    # The files won't be byte for byte exact, so filecmp won't work
    assert info._data == info2._data
    with open('fixtures/Lenna.jpg', 'rb') as fh, open('fixtures/deleteme.jpg', 'rb') as fh2:
        start, end, adobe = info.jpegCollectFileParts(fh)
        start2, end2, adobe2 = info.jpegCollectFileParts(fh2)

    # But we can compare each section
    assert start == start2
    assert end == end2
    assert adobe == adobe2

    # # Create object for file that may or may not have IPTC data.
    # info = IPTCInfo(fn, force=True)
    #
    # # Add/change an attribute
    # info.data['caption/abstract'] = 'árvíztűrő tükörfúrógép'
    # info.data['supplemental category'] = ['portrait']
    # info.data[123] = '123'
    # info.data['nonstandard_123'] = 'n123'
    #
    # print((info.data))
    #
    # # Save new info to file
    # ##### See disclaimer in 'SAVING FILES' section #####
    # info.save()
    # info.saveAs(fn2)
    #
    # #re-read IPTC info
    # print((IPTCInfo(fn2)))
