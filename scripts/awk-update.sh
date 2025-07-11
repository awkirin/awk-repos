#!/bin/bash
set -euo pipefail

#   sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/awkirin/awk-snippets/refs/heads/main/scripts/awk-update.sh)"


brew update
brew upgrade --force-bottle
brew upgrade --cask
brew cleanup
