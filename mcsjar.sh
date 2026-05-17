#!/bin/bash
pkill -f "server.jar" 2>/dev/null
rm -f /tmp/world/session.lock /tmp/p.log /tmp/mc.log
echo "downloading jre"
curl -L "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.11+10/OpenJDK21U-jre_x64_linux_hotspot_21.0.11_10.tar.gz" -o /tmp/jdk21.tar.gz 2>/dev/null
tar -xzf /tmp/jdk21.tar.gz -C /tmp && mv /tmp/jdk-21* /tmp/jdk21 2>/dev/null
echo "downloading jar"
curl -sL https://piston-data.mojang.com/v1/objects/59353fb40c36d304f2035d51e7d6e6baa98dc05c/server.jar -o /tmp/server.jar
echo "eula=true" > /tmp/eula.txt
echo "starting"
nohup /tmp/jdk21/bin/java -Xmx3G -Xms1G -jar /tmp/server.jar nogui > /tmp/mc.log 2>&1 &
nohup ssh -p 443 -o StrictHostKeyChecking=no -R0:localhost:25565 tcp@free.pinggy.io > /tmp/p.log 2>&1 &
LAST_PROGRESS=""
while ! grep -q "Done" /tmp/mc.log 2>/dev/null; do
  PROGRESS=$(grep "Preparing spawn area" /tmp/mc.log 2>/dev/null | tail -1 | grep -o '[0-9]*%')
  if [ -n "$PROGRESS" ] && [ "$PROGRESS" != "$LAST_PROGRESS" ]; then
    echo "  generating world... $PROGRESS"
    LAST_PROGRESS="$PROGRESS"
  fi
  sleep 2
done
if [ "$LAST_PROGRESS" != "100%" ]; then
  echo "  generating world... 100%"
fi
echo ""
echo "1.21.1 server running at:"
grep -ao "[a-z0-9-]*\.run\.pinggy-free\.link:[0-9]*" /tmp/p.log | tail -1
echo ""
