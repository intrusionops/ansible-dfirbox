#!/bin/bash
# OS updates often overwrite desktop launchers. This cronjob is intended
# to make sure these apps are always launched via firejail.
#
# brave browser
sed -i -s 's/Exec=\/usr\/bin\/brave-browser-stable/Exec=\/usr\/bin\/firejail /g' /usr/share/applications/brave-browser.desktop 
# thunderbird
sed -i -s 's/Exec=\/usr\/bin\/thunderbird/Exec=\/usr\/bin\/firejail \/usr\/bin\/thunderbird %u/g' /usr/share/applications/thunderbird.desktop 
# chromium
sed -i -s 's/Exec=\/usr\/bin\/chromium/Exec=\/usr\/bin\/firejail \/usr\/bin\/chromium %U/g' /usr/share/applications/chromium.desktop 
# vscodium
sed -i -s 's/Exec=\/usr\/share\/codium\/codium/Exec=\/usr\/bin\/firejail \/usr\/share\/codium\/codium /g' /usr/share/applications/codium.desktop 
# libreoffice apps
sed -i -s 's/Exec=libreoffice/Exec=\/usr\/bin\/firejail libreoffice /g' /usr/share/applications/libreoffice*
