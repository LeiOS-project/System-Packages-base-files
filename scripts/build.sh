#!/bin/bash

set -e

# check if version argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

cd ./src

# Save current changelog
cp debian/changelog debian/changelog.backup


# Create a temporary changelog with the version you want
cat > debian/changelog <<EOF
leios-base-files ($1) unstable; urgency=medium

  * Build for version $1

 -- Linus Fischer <leicraft@leicraftmc.de>  $(date -R)

EOF

# Append the original changelog after the new entry
cat debian/changelog.backup >> debian/changelog


# Build
INSERT_LEIOS_RELEASE=$(echo $1) dpkg-buildpackage -us -uc

# Restore original
mv debian/changelog.backup debian/changelog

cd ..
