# Release v2.2.0 - All Issues Fixed + Build System Modernization

🎉 **Major release fixing all 10 open issues and modernizing the build system!**

## 🐛 Bug Fixes

- **#40**: Fixed inconsistent license statements - now consistently "Artistic-1.0 OR GPL-1.0-or-later"
- **#24**: Changed "Marker scan hit start of image data" to INFO level when `force=True` is used
- **#32**: Fixed charset recognition for ISO 2022 escape sequences (UTF-8 as `\x1b%G`)
- **#26**: Added validation for float/NaN values in `packedIIMData()` to prevent TypeError

## ✨ New Features

- **#35**: Added 'credit line' field support per IPTC Core 1.1 (backward compatible with 'credit')
- **#42**: Added 'destination' field as alias for 'original transmission reference'

## 🔧 Improvements

- **#15**: Enhanced IPTC tag collection with better field mappings
- **#38**: Verified backup file behavior (use `options={'overwrite': True}` to avoid ~ files)
- Better error handling and logging throughout
- **#39, #41**: All master branch fixes now available on PyPI

## 🚀 Build System Modernization

- Migrated from legacy `setup.py` to modern `pyproject.toml`
- Now uses `uv` and `hatchling` for building (PEP 517/518 compliant)
- Simplified setup.py to minimal backward compatibility shim
- Added comprehensive publishing guide (`PUBLISHING.md`)
- Supports Python 3.8 through 3.13

## 📦 Installation

```bash
pip install IPTCInfo3==2.2.0
```

or with uv:

```bash
uv pip install IPTCInfo3==2.2.0
```

## 🔗 Links

- [Full Changelog](https://github.com/jamesacampbell/iptcinfo3/blob/master/CHANGELOG.md)
- [Publishing Guide](https://github.com/jamesacampbell/iptcinfo3/blob/master/PUBLISHING.md)
- [Documentation](https://github.com/jamesacampbell/iptcinfo3/blob/master/README.rst)

## 🙏 Thank You

Special thanks to all contributors who reported issues and helped make this release possible:
@vitaly-zdanevich, @CuriousLearner, @stefan6419846, @AlexSzatmary, @fdrov, @hyanwong, @nealmcb, @martimpassos, @niwics, @Mesqualito, and everyone else who contributed!

---

**Full Changelog**: https://github.com/jamesacampbell/iptcinfo3/compare/v2.1.4...v2.2.0

