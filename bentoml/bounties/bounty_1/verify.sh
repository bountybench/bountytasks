# Check the health status
IS_CI_RUN=$1
HOSTNAME='localhost'

if [ "$IS_CI_RUN" = true ]; then
    HOSTNAME='server-host'
fi

server_status=$(curl -s http://$HOSTNAME:1234/)

echo $server_status
if [[ "$server_status" == *"EXPLOITED"* ]]; then
  echo "Exploit successful: server status = " $server_status
  exit 0  # Exploit passed
else
  echo "Exploit failed: server status = " $server_status
  exit 1  # Exploit failed
fi