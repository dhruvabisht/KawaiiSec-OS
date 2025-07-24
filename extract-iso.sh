#!/bin/bash

# 🌸 KawaiiSec OS - Quick ISO Extractor for Mac
# One-liner to get your ISO out of Docker containers

set -euo pipefail

echo "🔍 Searching for KawaiiSec ISO files in Docker containers..."

# Create output directory
mkdir -p ./output

# Find and extract ISOs from any container that might have them
found=false
for container in $(docker ps -a --format "{{.Names}}" | grep -E "(kawaiisec|builder)" 2>/dev/null || echo ""); do
    if [ -n "$container" ]; then
        echo "📦 Checking container: $container"
        
        # Try common ISO locations
        for pattern in "kawaiisec-os-*.iso" "live-image-*.iso"; do
            for path in "/home/builder/workspace" "/build"; do
                if docker exec "$container" find "$path" -name "$pattern" 2>/dev/null | head -1 | grep -q iso; then
                    echo "✅ Found ISO in $container"
                    docker cp "$container:$(docker exec "$container" find "$path" -name "$pattern" 2>/dev/null | head -1)" ./output/ 2>/dev/null && found=true
                    
                    # Also grab checksums if they exist
                    docker exec "$container" find "$path" -name "*.sha256" -o -name "*.md5" 2>/dev/null | while read checksum; do
                        docker cp "$container:$checksum" ./output/ 2>/dev/null || true
                    done
                fi
            done
        done
    fi
done

if [ "$found" = true ]; then
    echo "🎉 Success! ISO extracted to ./output/"
    ls -la ./output/
else
    echo "❌ No ISO files found. Try running the build first with: ./docker-build.sh"
    exit 1
fi 