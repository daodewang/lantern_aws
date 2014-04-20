#!/usr/bin/env bash

LOG=$(dirname $0)/install-lantern.log

set -e

# In trying to restart Lantern every minute, this is killing all java processes.
# Let's disable it so it doesn't kill the building of Lantern.
[ ! -e check_lantern.py ] || (mv check_lantern.py check_lantern.bak ; sleep 5s)

[ ! -e lantern-repo ] || rm -rf lantern-repo
git clone --depth 1 --recursive --branch {{ pillar.get('branch', 'fallback') }} git://github.com/getlantern/lantern.git lantern-repo > $LOG 2>&1
cd lantern-repo
# Symlink pt to the right version of pt in install to get PluggableTransports support
ln -s install/linux_x86_64/pt pt
./install.bash >> $LOG 2>&1

# Restore check_lantern iff we've built Lantern successfully.
cd $(dirname $0)
[ ! -e check_lantern.bak ] || mv check_lantern.bak check_lantern.py

echo
echo 'changed=yes'