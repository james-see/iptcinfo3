# Publishing Guide for IPTCInfo3

This project now uses modern Python packaging with `pyproject.toml` and `uv`.

## Prerequisites

```bash
# Install uv (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install twine for PyPI uploads (optional, uv can also publish)
uv pip install twine
```

## Building the Package

```bash
# Clean previous builds
rm -rf dist/

# Build with uv (creates both .tar.gz and .whl)
uv build
```

This will create:
- `dist/iptcinfo3-2.2.0.tar.gz` (source distribution)
- `dist/iptcinfo3-2.2.0-py3-none-any.whl` (wheel)

## Publishing to PyPI

### Option 1: Using uv (recommended)

```bash
# Publish to PyPI (requires PyPI credentials)
uv publish

# Or publish to TestPyPI first
uv publish --publish-url https://test.pypi.org/legacy/
```

### Option 2: Using twine

```bash
# Check the distributions
twine check dist/*

# Upload to TestPyPI first (optional)
twine upload --repository testpypi dist/*

# Upload to PyPI
twine upload dist/*
```

## Testing the Package

### Test locally

```bash
# Install in development mode
uv pip install -e .

# Or install from the built wheel
uv pip install dist/iptcinfo3-2.2.0-py3-none-any.whl
```

### Test from TestPyPI

```bash
uv pip install --index-url https://test.pypi.org/simple/ iptcinfo3
```

### Test from PyPI (after publishing)

```bash
uv pip install iptcinfo3
```

## Version Updates

To release a new version:

1. Update `__version__` in `iptcinfo3.py`
2. Update version in `pyproject.toml`
3. Update `CHANGELOG.md` with changes
4. Commit changes
5. Create a git tag: `git tag v2.2.0`
6. Push with tags: `git push origin master --tags`
7. Build and publish as shown above

## PyPI Credentials

You'll need to configure your PyPI credentials. Create `~/.pypirc`:

```ini
[pypi]
username = __token__
password = pypi-...your-token...

[testpypi]
username = __token__
password = pypi-...your-token...
```

Or use environment variables:
```bash
export TWINE_USERNAME=__token__
export TWINE_PASSWORD=pypi-...your-token...
```

## Notes

- The package name on PyPI is `IPTCInfo3` (with capital letters)
- The module name is `iptcinfo3` (all lowercase)
- Always test on TestPyPI before publishing to production PyPI
- Once published to PyPI, you cannot delete or re-upload the same version

