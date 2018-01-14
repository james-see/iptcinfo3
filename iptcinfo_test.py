from iptcinfo3 import IPTCInfo


def test_getitem_can_read_info():
    info = IPTCInfo('fixtures/Lenna.jpg')

    assert len(info) >= 4
    assert info['keywords'] == [b'lenna', b'test']
    assert info['supplemental category'] == [b'supplemental category']
    assert info['caption/abstract'] == b'I am a caption'


def test_save_as_saves_as_new_file_with_info():
    info = IPTCInfo('fixtures/Lenna.jpg')
    info.save_as('fixtures/deleteme.jpg')

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
