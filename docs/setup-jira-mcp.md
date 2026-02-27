# Jira MCP Setup Guide

This guide explains how to configure the Jira MCP (Model Context Protocol) integration for the team management system.

## Prerequisites

- Claude Code CLI installed
- Jira Cloud or Jira Server/Data Center access
- API token or OAuth credentials

## Overview

The Jira MCP (or Atlassian MCP) integration enables:
- Linking projects to Jira boards (`/add-project`)
- Searching and selecting Jira boards by keyword
- Tracking Jira board IDs for future sync features

## Step 1: Create Jira API Token

### For Jira Cloud:

1. Go to [https://id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Click **"Create API token"**
3. Enter label: `Team Management MCP`
4. Click **"Create"**
5. **Copy the token immediately** - you won't see it again!

### For Jira Server/Data Center:

Use a Personal Access Token (PAT) or service account credentials. Contact your Jira administrator for details.

## Step 2: Get Your Jira Information

You'll need:
- **Jira Site URL**: e.g., `https://your-company.atlassian.net`
- **Email Address**: Your Jira Cloud email
- **API Token**: From Step 1

## Step 3: Configure Jira MCP

Create or update your MCP configuration file:

**Location:** `~/.claude/mcp.json` (or project-specific `.claude/mcp.json`)

**Add Jira/Atlassian MCP configuration:**

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-atlassian",
        "--jira-url",
        "https://your-company.atlassian.net",
        "--jira-email",
        "your-email@example.com",
        "--jira-token",
        "YOUR_API_TOKEN"
      ]
    }
  }
}
```

**Replace:**
- `your-company.atlassian.net` with your Jira site URL
- `your-email@example.com` with your Jira email
- `YOUR_API_TOKEN` with your API token from Step 1

**Alternative: Environment Variables**

For better security, use environment variables:

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-atlassian"
      ],
      "env": {
        "JIRA_URL": "https://your-company.atlassian.net",
        "JIRA_EMAIL": "your-email@example.com",
        "JIRA_TOKEN": "YOUR_API_TOKEN"
      }
    }
  }
}
```

Or set in your shell profile:
```bash
export JIRA_URL="https://your-company.atlassian.net"
export JIRA_EMAIL="your-email@example.com"
export JIRA_TOKEN="your-api-token"
```

## Step 4: Verify Installation

Restart Claude Code and verify Jira/Atlassian MCP is loaded:

```bash
# Check if Jira tools are available
# Atlassian MCP should provide tools for:
# - Searching boards
# - Getting board details
# - Searching projects
```

Test the `/add-project` skill and try linking a Jira board.

## Step 5: Test Jira Integration

### Test Board Linking:
1. Run `/add-project --team=<your-team>`
2. Provide project details
3. Choose "Yes, link to external tools"
4. Select "Jira"
5. Enter a search keyword
6. Verify Jira boards appear in search results
7. Select a board to link

## Troubleshooting

### "Jira MCP not configured" Error

- Verify `mcp.json` exists at `~/.claude/mcp.json`
- Check that the Atlassian MCP entry is correct
- Restart Claude Code after modifying `mcp.json`

### "Authentication Failed" Errors

- Verify API token is correct and not expired
- Check email address matches your Jira account
- Verify Jira site URL is correct (include `https://`)
- Ensure your account has permissions to access boards

### No Boards Found

- Verify your Jira account has access to boards
- Check search keyword spelling
- Ensure boards aren't in archived projects
- Try searching with different keywords

### "Forbidden" or "Access Denied"

- Verify your Jira account has board view permissions
- Check that boards belong to projects you can access
- Contact Jira administrator to verify permissions

### Rate Limiting

- Jira Cloud has rate limits (10,000 requests/hour for paid plans)
- Wait a few minutes if you hit rate limits
- Consider using a dedicated service account

## Jira Permissions Required

Your Jira account needs:
- **Browse Projects** - View projects and their content
- **View Development Tools** - See boards (Jira Software)

Your API token inherits your account permissions.

## Security Best Practices

1. **Never commit tokens to git**
   - Add `.claude/mcp.json` to `.gitignore` if storing tokens there
   - Use environment variables for tokens

2. **Use dedicated service accounts** (for team use)
   - Create a service account with minimal permissions
   - Don't share personal API tokens

3. **Rotate tokens regularly**
   - Generate new API tokens periodically
   - Revoke old tokens in Atlassian account settings

4. **Limit token exposure**
   - Don't paste tokens in chat or email
   - Use secure secret management tools

5. **Monitor token usage**
   - Review Jira audit logs periodically
   - Revoke any suspicious or unused tokens

## Additional Resources

- [Jira Cloud REST API Documentation](https://developer.atlassian.com/cloud/jira/platform/rest/v3/)
- [Atlassian API Tokens](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/)
- [MCP Documentation](https://modelcontextprotocol.io/)
- [Claude Code MCP Guide](https://docs.anthropic.com/claude/docs/mcp)

## Related Skills

- `/add-project` - Uses Jira MCP to link projects to boards

## Need Help?

If you encounter issues:
1. Check the troubleshooting section above
2. Verify API token in Atlassian account settings
3. Test API access using `curl`:
   ```bash
   curl -u your-email@example.com:your-api-token \
     https://your-company.atlassian.net/rest/api/3/project
   ```
