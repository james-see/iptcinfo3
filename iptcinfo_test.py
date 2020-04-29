import random
import os

import pytest

from iptcinfo3 import (
    EOFException,
    IPTCData,
    IPTCInfo,
    file_is_jpeg,
    hex_dump,
    jpeg_collect_file_parts,
)


def test_EOFException_message():
    exp = EOFException()
    assert str(exp) == ''

    exp = EOFException('ugh', 'well')
    assert str(exp) == 'ugh\nwell'


def test_hex_dump():
    out = hex_dump(b'ABCDEF')
    assert out.strip() == '41 42 43 44 45 46                                     | ABCDEF'


def test_jpeg_collect_parts_works_with_many_jpegs():
    with open('fixtures/Lenna.jpg', 'rb') as fh:
        start, end, adobe = jpeg_collect_file_parts(fh)

    assert len(start) == 356
    assert len(end) == 42891
    assert len(adobe) == 0

    with open('fixtures/instagram.jpg', 'rb') as fh:
        start, end, adobe = jpeg_collect_file_parts(fh)

    assert len(start) == 20
    assert len(end) == 73394
    assert len(adobe) == 0


def test_IPTCData():
    data = IPTCData({105: 'Audiobook Narrator Really Going For Broke With Cajun Accent'})
    assert data['headline'].startswith('Audiobook')
    assert data[105].startswith('Audiobook')
    assert data['Headline'].startswith('Audiobook')

    assert 'headline' in data
    assert 105 in data

    data['keywords'] = ['foo']
    data['keywords'] = ['foo', 'bar']
    with pytest.raises(ValueError):
        data['keywords'] = 'foo'

    with pytest.raises(KeyError):
        IPTCData({'yobby': 'yoshi'})

    with pytest.raises(KeyError):
        data['yobby'] = 'yoshi'

    assert 'yobby' not in data
    assert 9999 not in data

    data = IPTCData({'nonstandard_69': 'sanic'})
    assert data[69] == 'sanic'

    assert str(data) == "{'nonstandard_69': 'sanic'}"

    assert 69 in data
    assert 'nonstandard_69' in data


def test_file_is_jpeg_detects_invalid_file():
    with open('fixtures/Lenna.jpg', 'rb') as fh:
        assert file_is_jpeg(fh)

    with open('setup.cfg', 'rb') as fh:
        assert not file_is_jpeg(fh)


def test_getitem_can_read_info():
    info = IPTCInfo('fixtures/Lenna.jpg')

    assert len(info) >= 4
    assert info['keywords'] == [b'lenna', b'test']
    assert info['supplemental category'] == [b'supplemental category']
    assert info['caption/abstract'] == b'I am a caption'

    assert 'keywords' in info
    assert 'nonexistent' not in info

def test_save_as_saves_as_new_file_with_info():
    if os.path.isfile('fixtures/deleteme.jpg'):  # pragma: no cover
        os.unlink('fixtures/deleteme.jpg')

    info = IPTCInfo('fixtures/Lenna.jpg')
    info.save_as('fixtures/deleteme.jpg')

    info2 = IPTCInfo('fixtures/deleteme.jpg')

    # The files won't be byte for byte exact, so filecmp won't work
    assert info._data == info2._data
    with open('fixtures/Lenna.jpg', 'rb') as fh, open('fixtures/deleteme.jpg', 'rb') as fh2:
        start, end, adobe = jpeg_collect_file_parts(fh)
        start2, end2, adobe2 = jpeg_collect_file_parts(fh2)

    # But we can compare each section
    assert start == start2
    assert end == end2
    assert adobe == adobe2


def test_save_as_saves_as_new_file_with_new_info():
    if os.path.isfile('fixtures/deleteme.jpg'):  # pragma: no cover
        os.unlink('fixtures/deleteme.jpg')

    new_headline = b'test headline %d' % random.randint(0, 100)
    info = IPTCInfo('fixtures/Lenna.jpg')
    info['headline'] = new_headline
    info.save_as('fixtures/deleteme.jpg')

    info2 = IPTCInfo('fixtures/deleteme.jpg')

    assert info2['headline'] == new_headline
