#!/bin/bash
set -e

VERSION="${1:-2.3.1}"

echo "🚀 Creating GitHub Release for v${VERSION}"
echo ""

# Add and commit helper files
echo "1️⃣  Committing release documentation..."
git add CHANGELOG.md PUBLISHING.md pyproject.toml iptcinfo3.py README.rst Pipfile .python-version .circleci/config.yml 2>/dev/null || true
git commit -m "Release v${VERSION}: Python 3.10-3.15 support" || echo "Already committed"

# Create and push tag
echo ""
echo "2️⃣  Creating and pushing tag v${VERSION}..."
git tag -a "v${VERSION}" -m "Release v${VERSION}: Python 3.10-3.15 support" 2>/dev/null || echo "Tag already exists"
git push origin master
git push origin "v${VERSION}" 2>/dev/null || echo "Tag already pushed"

echo ""
echo "✅ Tag pushed successfully!"
echo ""
echo "3️⃣  Next steps:"
echo "   Go to: https://github.com/jamesacampbell/iptcinfo3/releases/new"
echo "   - Select tag: v${VERSION}"
echo "   - Copy the v${VERSION} section from CHANGELOG.md as release notes"
echo "   - Upload files from dist/ folder"
echo "   - Click 'Publish release'"
echo ""
echo "📦 Files to upload:"
ls -lh "dist/iptcinfo3-${VERSION}"*
