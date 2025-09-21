#!/bin/bash

# ================================================
# SLACK INTEGRATION TEST SCRIPT
# ================================================
# Tests Slack webhook and bot functionality

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load environment
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURSOR_DIR="$(dirname "$SCRIPT_DIR")"

if [ "$1" == "prod" ]; then
    ENV_FILE="$CURSOR_DIR/.env.production"
else
    ENV_FILE="$CURSOR_DIR/.env.development"
fi

if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

# Slack webhook URL
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-https://hooks.slack.com/services/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}"

echo -e "${BLUE}Testing Slack Integration${NC}"
echo "================================"
echo ""

# Test 1: Basic message
echo -e "${YELLOW}Test 1: Sending basic message...${NC}"
response=$(curl -X POST -H 'Content-type: application/json' \
    --data '{"text":"✅ Cursor IDE Slack Test - Basic Message"}' \
    "$WEBHOOK_URL" 2>/dev/null)

if [ "$response" == "ok" ]; then
    echo -e "${GREEN}✓ Basic message sent successfully${NC}"
else
    echo "Response: $response"
fi

# Test 2: Formatted message with blocks
echo -e "${YELLOW}Test 2: Sending formatted message...${NC}"
response=$(curl -X POST -H 'Content-type: application/json' \
    --data '{
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": "🚀 Cursor IDE Status Report"
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": "*Environment:*\n'"${NODE_ENV:-development}"'"
                    },
                    {
                        "type": "mrkdwn",
                        "text": "*Timestamp:*\n'"$(date '+%Y-%m-%d %H:%M:%S')"'"
                    }
                ]
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": "*Stytch Status:*\n✅ Configured"
                    },
                    {
                        "type": "mrkdwn",
                        "text": "*Database:*\n✅ Connected"
                    }
                ]
            }
        ]
    }' \
    "$WEBHOOK_URL" 2>/dev/null)

if [ "$response" == "ok" ]; then
    echo -e "${GREEN}✓ Formatted message sent successfully${NC}"
else
    echo "Response: $response"
fi

# Test 3: Notification with buttons (for interactive messages)
echo -e "${YELLOW}Test 3: Sending interactive message...${NC}"
response=$(curl -X POST -H 'Content-type: application/json' \
    --data '{
        "text": "Cursor IDE Deployment Ready",
        "attachments": [
            {
                "text": "A new version is ready to deploy",
                "fallback": "You cannot deploy from this client",
                "callback_id": "deploy_cursor",
                "color": "#3AA3E3",
                "attachment_type": "default",
                "actions": [
                    {
                        "name": "deployment",
                        "text": "Deploy to Production",
                        "type": "button",
                        "value": "deploy_prod",
                        "style": "primary"
                    },
                    {
                        "name": "deployment",
                        "text": "Deploy to Staging",
                        "type": "button",
                        "value": "deploy_staging"
                    },
                    {
                        "name": "deployment",
                        "text": "Cancel",
                        "style": "danger",
                        "type": "button",
                        "value": "cancel"
                    }
                ]
            }
        ]
    }' \
    "$WEBHOOK_URL" 2>/dev/null)

if [ "$response" == "ok" ]; then
    echo -e "${GREEN}✓ Interactive message sent successfully${NC}"
else
    echo "Response: $response"
fi

echo ""
echo -e "${GREEN}Slack integration tests completed!${NC}"
echo "Check your Slack channel for the test messages"
echo ""
echo "Webhook URL: $WEBHOOK_URL"
echo "App ID: ${SLACK_APP_ID:-Not configured}"
echo "App Name: ${SLACK_APP_NAME:-Not configured}"