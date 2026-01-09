#!/usr/bin/env bash
SERVER_KEY=${1:-$FCM_SERVER_KEY}
TARGET_TOKEN=${2:-$FCM_TARGET_TOKEN}

if [ -z "$SERVER_KEY" ] || [ -z "$TARGET_TOKEN" ]; then
  echo "Usage: ./send_fcm_test.sh <SERVER_KEY> <TARGET_TOKEN>"
  echo "Or set FCM_SERVER_KEY and FCM_TARGET_TOKEN environment variables"
  exit 1
fi

json=$(cat <<EOF
{
  "to":"${TARGET_TOKEN}",
  "data":{
    "title":"Test JTM",
    "body":"Message de test envoyé depuis script",
    "test":"1"
  }
}
EOF
)

curl -s -X POST -H "Authorization: key=${SERVER_KEY}" -H "Content-Type: application/json" -d "${json}" https://fcm.googleapis.com/fcm/send | jq .
