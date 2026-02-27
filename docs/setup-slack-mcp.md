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

Configure MCP credentials using the repository-local `.env` file.

**Location:** `.env` in repository root

**Setup Instructions:**

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env`** and add your Slack credentials:
   ```bash
   YOUR_SLACK_BOT_TOKEN_HERE=xoxb-xxxxxxxxxxxx-xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx
   YOUR_SLACK_TEAM_ID_HERE=T01XXXXXXXXX
   ```

3. **Replace the placeholder values:**
   - `YOUR_SLACK_BOT_TOKEN_HERE` → Your Bot User OAuth Token from Step 3
   - `YOUR_SLACK_TEAM_ID_HERE` → Your Slack workspace Team ID

4. **Verify `.env` is gitignored:**
   ```bash
   git check-ignore .env  # Should output: .env
   ```

**Important:** The `.env` file is already in `.gitignore` to prevent accidentally committing credentials. The `.mcp.json` file uses environment variable substitution (`${...}`) to read secrets from `.env`.

**Finding Your Slack Team ID:**

Your Team ID can be found in several ways:
- In Slack web app: Click workspace name → Settings & Administration → Workspace Settings (URL contains Team ID)
- In your Slack app settings at [https://api.slack.com/apps](https://api.slack.com/apps) under "App Credentials"
- Via API: `https://slack.com/api/auth.test` with your bot token

**How it works:**

The `.mcp.json` file is pre-configured with environment variable placeholders:

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "${YOUR_SLACK_BOT_TOKEN_HERE}",
        "SLACK_TEAM_ID": "${YOUR_SLACK_TEAM_ID_HERE}"
      }
    }
  }
}
```

The `${...}` syntax automatically reads values from your `.env` file.

**Security Note:** The `.env` file is gitignored to prevent credential leaks. The `.mcp.json` file (with placeholders) is safe to commit to version control.

## Step 5: Manual Testing

After configuring `.env`, verify the setup is correct:

### 5.1 Configuration Validation

Run these commands to verify your configuration:

```bash
# Verify .env file exists
ls -la .env

# Verify it's gitignored (prevents accidental commits)
git check-ignore .env  # Should output: .env

# Verify JSON syntax is valid
cat .mcp.json | jq .  # Should parse without errors
```

If `jq` is not installed, you can use Python instead:
```bash
python3 -c "import json; json.load(open('.mcp.json'))" && echo "Valid JSON"
```

### 5.2 Slack MCP Connection Test

Test the Slack MCP integration to ensure it's working:

1. **Restart Claude Code** in the repository directory to load `.mcp.json`
   ```bash
   cd /path/to/team-management
   claude
   ```

2. **Run the import skill** with any team name:
   ```
   /import-slack-channel --team=test-team
   ```

3. **Enter a channel search keyword** when prompted (e.g., "general")

4. **Verify the results:**
   - Claude should list Slack channels matching your search
   - If successful, the Slack MCP connection is working correctly
   - You can cancel the import after verification (Ctrl+C)

5. **Check for errors:**
   - If you see "Slack MCP not configured", check your `.mcp.json` file location and syntax
   - If you see authentication errors, verify your bot token and team ID
   - If you see permission errors, check OAuth scopes in Step 2

## Step 6: Invite Bot to Channels

For the bot to access channel members, invite it to the channels you want to import:

1. Open the Slack channel
2. Type: `/invite @Team Management Bot`
3. Confirm the invitation

**Note:** The bot only needs to be invited to channels you want to import members from.

## Troubleshooting

### "Slack MCP not configured" Error

**Symptoms:**
- Error message when running `/import-slack-channel`
- Claude cannot find Slack MCP tools

**Solutions:**
- Verify `.mcp.json` exists in the repository root (not `~/.claude/mcp.json`)
- Check that the file contains the `slack` entry under `mcpServers`
- Verify JSON syntax is valid using `cat .mcp.json | jq .`
- Restart Claude Code after modifying `.mcp.json`
- Ensure you're running Claude Code from the repository directory

### Bot Token Errors

**Symptoms:**
- "Invalid authentication" or "invalid_auth" errors
- 401 Unauthorized responses
- "Token revoked" messages

**Solutions:**
- Verify your bot token in `.mcp.json` starts with `xoxb-`
- Check for extra spaces or quotes around the token
- Regenerate the bot token in Slack app settings
- Ensure the token hasn't been revoked
- Verify the bot is still installed to the workspace

### Team ID Issues

**Symptoms:**
- "Team not found" errors
- Cannot list channels or users
- MCP connection fails silently

**Solutions:**
- Verify your Team ID in `.mcp.json` (format: `T01234ABCDE`)
- Check Team ID in Slack workspace settings URL
- Use the correct Team ID for your workspace (not channel ID)
- Ensure the bot token belongs to the specified team

### "Permission Denied" Errors

**Symptoms:**
- "missing_scope" error messages
- Cannot access channel members
- Cannot read user information

**Solutions:**
- Verify your bot has all required OAuth scopes (see Step 2)
- Go to Slack app settings → OAuth & Permissions → Bot Token Scopes
- Add any missing scopes: `channels:read`, `groups:read`, `users:read`, `users:read.email`
- **Reinstall the app to workspace** after adding new scopes
- Ensure bot is invited to the channel (`/invite @Team Management Bot`)

### No Email Addresses Found

**Symptoms:**
- Team members imported without email addresses
- Email field is empty in member profiles

**Solutions:**
- Verify `users:read.email` scope is enabled
- Check Slack workspace settings allow email visibility
- Some users may have hidden their email addresses (workspace setting)
- Workspace admins can control email visibility in Slack settings

### "Channel Not Found"

**Symptoms:**
- Cannot find channel by name
- Empty channel list returned

**Solutions:**
- Ensure bot is invited to private channels (`/invite @Team Management Bot`)
- Verify channel name spelling (try partial matches)
- Check that channel hasn't been archived
- Use channel ID instead of name if issues persist
- Verify bot has `groups:read` scope for private channels

### JSON Parsing Errors

**Symptoms:**
- "Invalid JSON" or syntax errors
- `.mcp.json` fails validation

**Solutions:**
- Use `cat .mcp.json | jq .` to identify syntax errors
- Check for missing commas, quotes, or braces
- Compare with `mcp-config-example.json` for correct format
- Use a JSON validator or editor with syntax highlighting
- Ensure no trailing commas after last object properties

## Security Best Practices

1. **Never commit tokens to git**
   - `.mcp.json` is automatically gitignored in this repository
   - Verify with: `git check-ignore .mcp.json`
   - Never commit credentials to version control

2. **Rotate tokens regularly**
   - Generate new bot tokens periodically
   - Revoke old tokens in Slack app settings
   - Update `.mcp.json` with new tokens

3. **Limit bot permissions**
   - Only add OAuth scopes you actually need
   - Review bot activity in Slack audit logs
   - Remove unused scopes to minimize risk

4. **Share responsibly**
   - Don't share bot tokens via email or chat
   - Use secure secret management for team environments
   - Each team member should create their own `.mcp.json`

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
