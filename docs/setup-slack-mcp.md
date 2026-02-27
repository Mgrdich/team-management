# Slack MCP Setup Guide

This guide explains how to configure the Slack MCP (Model Context Protocol) integration for the team management system.

## Prerequisites

- Claude Code CLI installed
- Slack workspace with admin access
- Ability to create Slack apps

## Overview

The Slack MCP integration enables:
- Importing team members from Slack channels (`/import-slack-channel`)
- Automatically populating member profiles with Slack data
- Tracking Slack user IDs for future sync features

## Step 1: Create a Slack App

1. Go to [https://api.slack.com/apps](https://api.slack.com/apps)
2. Click **"Create New App"**
3. Choose **"From scratch"**
4. Enter app name: `Team Management Bot`
5. Select your workspace
6. Click **"Create App"**

## Step 2: Configure OAuth Scopes

1. In your app settings, go to **"OAuth & Permissions"**
2. Scroll to **"Scopes"** → **"Bot Token Scopes"**
3. Add the following scopes:

   **Required scopes:**
   - `channels:read` - View basic channel information
   - `groups:read` - View private channel information
   - `users:read` - View people in the workspace
   - `users:read.email` - View email addresses of people in the workspace

4. Click **"Save Changes"**

## Step 3: Install App to Workspace

1. Scroll to top of **"OAuth & Permissions"** page
2. Click **"Install to Workspace"**
3. Review permissions and click **"Allow"**
4. Copy the **"Bot User OAuth Token"** (starts with `xoxb-`)
   - **Important:** Keep this token secure!

## Step 4: Configure Slack MCP

Create or update your MCP configuration file:

**Location:** `~/.claude/mcp.json` (or project-specific `.claude/mcp.json`)

**Add Slack MCP configuration:**

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-slack",
        "--token",
        "YOUR_BOT_TOKEN_HERE"
      ]
    }
  }
}
```

**Replace `YOUR_BOT_TOKEN_HERE`** with your Bot User OAuth Token from Step 3.

**Alternative: Environment Variable**

For better security, use an environment variable:

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-slack",
        "--token"
      ],
      "env": {
        "SLACK_BOT_TOKEN": "YOUR_BOT_TOKEN_HERE"
      }
    }
  }
}
```

Or set in your shell profile:
```bash
export SLACK_BOT_TOKEN="xoxb-your-token-here"
```

## Step 5: Verify Installation

Restart Claude Code and verify Slack MCP is loaded:

```bash
# Check if Slack tools are available
# Slack MCP should provide tools like:
# - conversations.list
# - conversations.members
# - users.info
```

Test the `/import-slack-channel` skill to verify it works.

## Step 6: Invite Bot to Channels

For the bot to access channel members, invite it to the channels you want to import:

1. Open the Slack channel
2. Type: `/invite @Team Management Bot`
3. Confirm the invitation

**Note:** The bot only needs to be invited to channels you want to import members from.

## Troubleshooting

### "Slack MCP not configured" Error

- Verify `mcp.json` exists at `~/.claude/mcp.json`
- Check that the Slack MCP entry is correct
- Restart Claude Code after modifying `mcp.json`

### "Permission Denied" Errors

- Verify your bot has all required OAuth scopes
- Reinstall the app to workspace if you added new scopes
- Ensure bot is invited to the channel

### No Email Addresses Found

- Verify `users:read.email` scope is enabled
- Check Slack workspace settings allow email visibility
- Some users may have hidden their email addresses

### "Channel Not Found"

- Ensure bot is invited to private channels
- Verify channel name spelling
- Check that channel hasn't been archived

## Security Best Practices

1. **Never commit tokens to git**
   - Add `.claude/mcp.json` to `.gitignore` if storing tokens there
   - Use environment variables for tokens

2. **Rotate tokens regularly**
   - Generate new bot tokens periodically
   - Revoke old tokens in Slack app settings

3. **Limit bot permissions**
   - Only add OAuth scopes you actually need
   - Review bot activity in Slack audit logs

4. **Share responsibly**
   - Don't share bot tokens via email or chat
   - Use secure secret management for team environments

## Additional Resources

- [Slack API Documentation](https://api.slack.com/)
- [MCP Documentation](https://modelcontextprotocol.io/)
- [Claude Code MCP Guide](https://docs.anthropic.com/claude/docs/mcp)

## Related Skills

- `/import-slack-channel` - Import team members from Slack channel

## Need Help?

If you encounter issues:
1. Check the troubleshooting section above
2. Review Slack app logs in the Slack API dashboard
3. Verify MCP server is running correctly
