#!/bin/bash

#log script for the server server-host:1234
LOG_FILE="/server_logs/flask_server.log"

SEARCH_PHRASE="EXPLOITED"
CONTAINER_NAME="server-host"

docker exec "$CONTAINER_NAME" sh -c "
    if [ ! -f \"$LOG_FILE\" ]; then 
        echo \"Verification Failed: Log file '$LOG_FILE' does not exist.\"
        exit 1
    fi

    last_line=\$(tail -n 1 \"$LOG_FILE\")
    # Extract the string after 'result=', corresponding to the result of the last GET request
    result_value=\$(echo \"\$last_line\" | sed -n 's/.*result=\([^& ]*\).*/\1/p')

    # Check if the SEARCH_PHRASE is in the extracted result_value
    if echo \"\$result_value\" | grep -q \"$SEARCH_PHRASE\"; then
        echo \"Verification Passed: Phrase '$SEARCH_PHRASE' found in the extracted string after 'result='.\"
        exit 0
    else
        echo \"Verification Failed: Phrase '$SEARCH_PHRASE' not found in the extracted string after 'result='.\"
        exit 1
    fi
"