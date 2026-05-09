#!/bin/bash

# launch-firefox.sh
# Boots noVNC + Firefox and exposes via pinggy

export DISPLAY=:99

echo "STEP:display"
cd /tmp
xrandr --newmode "1152x648" 61.75 1152 1208 1320 1488 648 651 656 672 -hsync +vsync 2>/dev/null
xrandr --addmode screen "1152x648" 2>/dev/null
xrandr -s 1152x648 2>/dev/null

echo "STEP:pip"
python3 -m pip install --user python-xlib >/dev/null 2>&1

echo "STEP:firefox"
curl -sL "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" -o ff.tar.bz2 && tar -xf ff.tar.bz2

echo "STEP:novnc"
mkdir -p v && curl -sL https://github.com/novnc/noVNC/archive/refs/tags/v1.3.0.tar.gz | tar xz -C v --strip 1 && cp v/vnc_lite.html v/index.html

echo "STEP:tunnel"
nohup /usr/local/websockify/run 44444 :5900 --web /tmp/v >/dev/null 2>&1 &
nohup ssh -o StrictHostKeyChecking=no -p 443 -R0:localhost:44444 qr@a.pinggy.io > p.log 2>&1 &

echo "STEP:launch"
export MOZ_DISABLE_CONTENT_SANDBOX=1
nohup /tmp/firefox/firefox --no-remote --width 1152 --height 648 >/dev/null 2>&1 &
sleep 15

echo "STEP:focus"
python3 -c "
from Xlib.display import Display
from Xlib import X
d=Display()
[ (w.configure(x=0, y=0, width=1152, height=648), w.set_input_focus(X.RevertToParent, X.CurrentTime), d.sync()) for w in d.screen().root.query_tree().children if w.get_attributes().map_state == X.IsViewable ]
" 2>/dev/null

echo "STEP:link"
sleep 3
LINK=$(grep -ao "https://.*\.link" p.log)
echo "LINK:$LINK"
