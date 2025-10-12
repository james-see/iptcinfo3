#!/bin/bash
set -e

echo "🚀 Creating GitHub Release for v2.2.0"
echo ""

# Add and commit helper files
echo "1️⃣  Committing release documentation..."
git add ISSUE_CLOSING_COMMENTS.md RELEASE_NOTES_v2.2.0.md PUBLISHING.md pyproject.toml
git commit -m "Add release documentation for v2.2.0" || echo "Already committed"

# Create and push tag
echo ""
echo "2️⃣  Creating and pushing tag v2.2.0..."
git tag -a v2.2.0 -m "Release v2.2.0: Fix all issues and modernize build system" 2>/dev/null || echo "Tag already exists"
git push origin master
git push origin v2.2.0 2>/dev/null || echo "Tag already pushed"

echo ""
echo "✅ Tag pushed successfully!"
echo ""
echo "3️⃣  Next steps:"
echo "   Go to: https://github.com/jamesacampbell/iptcinfo3/releases/new"
echo "   - Select tag: v2.2.0"
echo "   - Copy content from: RELEASE_NOTES_v2.2.0.md"
echo "   - Upload files from dist/ folder"
echo "   - Click 'Publish release'"
echo ""
echo "📦 Files to upload:"
ls -lh dist/iptcinfo3-2.2.0*

