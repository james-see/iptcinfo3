# Issue Closing Comments for v2.2.0 Release

Copy and paste these comments when closing each issue.

---

## Issue #42 - "Destination" field in gThumb, in exiftool also shows "Destination"

**Comment:**
```
Fixed in v2.2.0! 

Added 'destination' as an alias for 'original transmission reference' (dataset 103) to provide compatibility with gThumb and exiftool.

You can now use:
```python
info['destination'] = 'Your destination'
```

This will be available in the next PyPI release. Thank you for reporting!
```

**Action:** Close issue

---

## Issue #41 - AttributeError: 'IPTCInfo' object has no attribute '_fob'

**Comment:**
```
This was already fixed in the master branch (uses `_fobj` correctly). 

Version 2.2.0 is now ready for PyPI release with all the latest fixes. Thank you for your patience!
```

**Action:** Close issue

---

## Issue #40 - Inconsistent license statements

**Comment:**
```
Fixed in v2.2.0!

Updated all license statements to consistently state "Artistic-1.0 OR GPL-1.0-or-later" in both:
- `iptcinfo3.py` header
- `setup.py` 
- `pyproject.toml`

This clarifies that users can choose either the Artistic License or GPL, following the original Perl module's licensing model.

Thank you for pointing out this inconsistency!
```

**Action:** Close issue

---

## Issue #39 - Please update release on PyPI

**Comment:**
```
Great news! Version 2.2.0 is now ready for PyPI release! 🎉

This release includes:
- All fixes from master branch
- Modern build system (pyproject.toml + uv)
- Support for Python 3.8-3.13
- Multiple bug fixes and new features

The package has been built and tested successfully. Publishing to PyPI now!

Thank you for your patience and for maintaining interest in this project!
```

**Action:** Close issue after publishing to PyPI

---

## Issue #38 - A temporary file with ~ at the end

**Comment:**
```
The fix for this is already in the codebase (merged in PR #29).

To avoid the backup file with `~` at the end, use the `overwrite` option:

```python
info.save_as('image.jpg', {'overwrite': True})
```

Without this option, the library creates a backup of the original file (with `~` suffix) before overwriting, which is a safety feature.

Documentation has been updated in v2.2.0. Closing as this is working as designed with the option to disable backups.
```

**Action:** Close issue

---

## Issue #35 - Add "Credit Line" (IPTC core 1.1)

**Comment:**
```
Fixed in v2.2.0! 🎉

Updated dataset 110 from 'credit' to 'credit line' per IPTC Core 1.1 specification.

For backward compatibility, both field names work:
```python
info['credit line'] = 'Your credit'  # New standard name
info['credit'] = 'Your credit'       # Still works for compatibility
```

Thank you for the feature request!
```

**Action:** Close issue

---

## Issue #32 - WARNING: problems with charset recognition (b'\x1b')

**Comment:**
```
Fixed in v2.2.0! 🎉

The code now properly handles ISO 2022 escape sequences for charset declaration:
- `ESC % G` (`\x1b%G`) is correctly recognized as UTF-8
- `ESC % / @` is recognized as UTF-16
- Falls back to legacy numeric charset encoding when needed

The warning about `b'\x1b'` should no longer appear for properly encoded images.

Thank you @nealmcb for the detailed analysis and test case!
```

**Action:** Close issue

---

## Issue #26 - Can't save files (TypeError with float/NaN)

**Comment:**
```
Fixed in v2.2.0! 🎉

Added validation in `packedIIMData()` to properly handle:
- Float values (converted to strings)
- NaN values (skipped gracefully)
- None values (skipped)
- Empty strings and lists (skipped)

Your code will now work without modification. The library automatically handles these edge cases.

Thank you for reporting with a detailed example!
```

**Action:** Close issue

---

## Issue #24 - "Marker scan hit start of image data" should not be the WARN

**Comment:**
```
Fixed in v2.2.0! 🎉

When `force=True` is used in the IPTCInfo constructor, the "Marker scan hit start of image data" message is now logged at INFO level instead of WARNING.

This makes sense because when you use `force=True`, you're explicitly indicating that you expect files without IPTC data, so it shouldn't be treated as a warning condition.

Thank you for the suggestion!
```

**Action:** Close issue

---

## Issue #15 - IPTC info tag collection

**Comment:**
```
Thank you for the detailed field mapping!

Most of the fields you mentioned are already supported in the library. The current implementation includes:
- All standard IPTC fields
- custom1 through custom20 (datasets 200-219) for non-standard fields

Version 2.2.0 includes:
- Enhanced field mappings
- Better documentation
- Support for 'credit line' (IPTC Core 1.1)

The custom fields provide flexibility for any non-standard tags you need. If there are specific standard IPTC fields still missing, please open a new focused issue for each one.

Closing this as the core functionality is complete. Thank you for your interest in improving the project!
```

**Action:** Close issue

---

## After Closing All Issues

Create a new comment on the main repo or discussion:

```
🎉 **IPTCInfo3 v2.2.0 Released!**

All 10 open issues have been resolved! This release includes:

### Bug Fixes
- Fixed charset recognition for ISO 2022 escape sequences (#32)
- Fixed float/NaN handling in save operations (#26)
- Fixed license statement inconsistencies (#40)
- Fixed logging levels when force=True (#24)

### New Features
- Added 'credit line' field support (IPTC Core 1.1) (#35)
- Added 'destination' field alias (#42)

### Improvements
- Modernized build system with pyproject.toml and uv
- Python 3.8-3.13 support
- Ready for PyPI release (#39, #41)
- Documented backup file behavior (#38)

Thank you to everyone who reported issues and contributed to making this release possible! 🙏
```

