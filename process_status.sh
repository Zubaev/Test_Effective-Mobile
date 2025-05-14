#!/bin/bash

PROCESS_NAME="test"
URL="https://test.com/monitoring/test/api"
LOG_FILE="/var/log/monitoring.log"

STATUS_FILE="/var/tmp/process_status_$PROCESS_NAME"

if [ ! -f "$STATUS_FILE" ]; then
    echo "unknown" > "$STATUS_FILE"
fi

if pgrep -x "$PROCESS_NAME" > /dev/null; then
    CURRENT_STATUS="running"
else
    CURRENT_STATUS="stopped"
fi

PREVIOUS_STATUS=$(cat "$STATUS_FILE")

if [ "$CURRENT_STATUS" == "running" ] && [ "$PREVIOUS_STATUS" == "stopped" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Процесс '$PROCESS_NAME' был перезапущен." >> "$LOG_FILE"
fi

if [ "$CURRENT_STATUS" == "running" ]; then
    RESPONSE=$(curl --silent --output /dev/null --write-out "%{http_code}" --insecure --max-time 5 "$URL" 2>/dev/null)

    if [ "$RESPONSE" != "200" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') Сервер мониторинга недоступен (HTTP $RESPONSE)." >> "$LOG_FILE"
    fi
fi

echo "$CURRENT_STATUS" > "$STATUS_FILE"