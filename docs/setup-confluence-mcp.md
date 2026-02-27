# Confluence MCP Setup Guide

This guide explains how to configure the Confluence MCP (Model Context Protocol) integration for the team management system.

## Prerequisites

- Claude Code CLI installed
- Confluence Cloud or Confluence Server/Data Center access
- API token or OAuth credentials

## Overview

The Confluence MCP (or Atlassian MCP) integration enables:
- Linking projects to Confluence spaces (`/add-project`)
- Searching and selecting Confluence spaces by keyword
- Tracking Confluence space keys for documentation access

## Step 1: Create Confluence API Token

### For Confluence Cloud:

1. Go to [https://id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Click **"Create API token"**
3. Enter label: `Team Management MCP - Confluence`
4. Click **"Create"**
5. **Copy the token immediately** - you won't see it again!

**Note:** This is the same API token management page as Jira. You can use the same token for both Jira and Confluence.

### For Confluence Server/Data Center:

Use a Personal Access Token (PAT) or service account credentials. Contact your Confluence administrator for details.

## Step 2: Get Your Confluence Information

You'll need:
- **Confluence Site URL**: e.g., `https://your-company.atlassian.net/wiki`
- **Email Address**: Your Confluence Cloud email
- **API Token**: From Step 1

## Step 3: Configure Confluence MCP

Create or update your MCP configuration file:

**Location:** `~/.claude/mcp.json` (or project-specific `.claude/mcp.json`)

**If using separate Confluence MCP:**

```json
{
  "mcpServers": {
    "confluence": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-confluence",
        "--url",
        "https://your-company.atlassian.net/wiki",
        "--email",
        "your-email@example.com",
        "--token",
        "YOUR_API_TOKEN"
      ]
    }
  }
}
```

**If using combined Atlassian MCP (recommended):**

The Atlassian MCP can handle both Jira and Confluence:

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
        "YOUR_API_TOKEN",
        "--confluence-url",
        "https://your-company.atlassian.net/wiki",
        "--confluence-email",
        "your-email@example.com",
        "--confluence-token",
        "YOUR_API_TOKEN"
      ]
    }
  }
}
```

**Replace:**
- `your-company.atlassian.net` with your site URL
- `your-email@example.com` with your email
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
        "CONFLUENCE_URL": "https://your-company.atlassian.net/wiki",
        "CONFLUENCE_EMAIL": "your-email@example.com",
        "CONFLUENCE_TOKEN": "YOUR_API_TOKEN"
      }
    }
  }
}
```

Or set in your shell profile:
```bash
export CONFLUENCE_URL="https://your-company.atlassian.net/wiki"
export CONFLUENCE_EMAIL="your-email@example.com"
export CONFLUENCE_TOKEN="your-api-token"
```

## Step 4: Verify Installation

Restart Claude Code and verify Confluence/Atlassian MCP is loaded:

```bash
# Check if Confluence tools are available
# Atlassian MCP should provide tools for:
# - Searching spaces
# - Getting space details
# - Searching pages
```

Test the `/add-project` skill and try linking a Confluence space.

## Step 5: Test Confluence Integration

### Test Space Linking:
1. Run `/add-project --team=<your-team>`
2. Provide project details
3. Choose "Yes, link to external tools"
4. Select "Confluence"
5. Enter a search keyword
6. Verify Confluence spaces appear in search results
7. Select a space to link

## Troubleshooting

### "Confluence MCP not configured" Error

- Verify `mcp.json` exists at `~/.claude/mcp.json`
- Check that the Atlassian MCP entry is correct
- Restart Claude Code after modifying `mcp.json`

### "Authentication Failed" Errors

- Verify API token is correct and not expired
- Check email address matches your Confluence account
- Verify Confluence site URL is correct (include `https://` and `/wiki` suffix)
- Ensure your account has permissions to access spaces

### No Spaces Found

- Verify your Confluence account has access to spaces
- Check search keyword spelling
- Ensure spaces aren't archived
- Try searching with different keywords (space name, space key)

### "Forbidden" or "Access Denied"

- Verify your Confluence account has space view permissions
- Check that spaces aren't restricted to specific user groups
- Contact Confluence administrator to verify permissions

### Wrong Confluence Instance

- For Confluence Cloud: URL should end with `/wiki`
- For Confluence Server: URL is typically `https://confluence.company.com`
- Verify you're using the correct URL for your instance

## Confluence Permissions Required

Your Confluence account needs:
- **View Space** - See space content
- **View Pages** - Access pages within spaces

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
   - Review Confluence audit logs periodically
   - Revoke any suspicious or unused tokens

## Confluence Cloud vs Server

### Confluence Cloud:
- API endpoint: `https://your-company.atlassian.net/wiki`
- Uses email + API token authentication
- REST API v2

### Confluence Server/Data Center:
- API endpoint: `https://confluence.company.com`
- May use Basic Auth or Personal Access Tokens
- Check with administrator for authentication method

## Additional Resources

- [Confluence Cloud REST API Documentation](https://developer.atlassian.com/cloud/confluence/rest/v2/)
- [Atlassian API Tokens](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/)
- [MCP Documentation](https://modelcontextprotocol.io/)
- [Claude Code MCP Guide](https://docs.anthropic.com/claude/docs/mcp)

## Related Skills

- `/add-project` - Uses Confluence MCP to link projects to spaces

## Need Help?

If you encounter issues:
1. Check the troubleshooting section above
2. Verify API token in Atlassian account settings
3. Test API access using `curl`:
   ```bash
   curl -u your-email@example.com:your-api-token \
     https://your-company.atlassian.net/wiki/api/v2/spaces
   ```
