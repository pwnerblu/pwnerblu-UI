#!/bin/bash

echo "Fixing the v0.8.5-beta updater..."
sleep 2
rm -rf pwnerblu-UI.sh

curl -L -o pwnerblu-UI.sh https://raw.githubusercontent.com/pwnerblu/pwnerblu-UI/refs/heads/main/pwnerblu-UI.sh

chmod +x pwnerblu-UI.sh

echo "Done! pwnerblu-UI has been updated from v0.8.5-beta to v0.8.5-beta re-release"
exit 0
