#!/bin/bash
#
# Install Visual Studio Code Ruby extensions
#
extensions=(
  # https://marketplace.visualstudio.com/items?itemName=KoichiSasada.vscode-rdbg
  "KoichiSasada.vscode-rdbg"
)
for extension in ${extensions[@]}; do
  code --install-extension $extension
done
