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

This project uses a **repository-local `.env`** file for MCP configuration.

**Important:** Confluence and Jira share the same `atlassian` MCP server configuration. If you've already configured Jira MCP, you can skip this step - the same configuration handles both services.

### Configuration File Location

**Location:** `.env` (in the repository root)

This file is gitignored to prevent accidental credential commits.

### Setup Instructions

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env`** and add your Confluence credentials:
   ```bash
   YOUR_JIRA_EMAIL_HERE=your-email@example.com
   YOUR_JIRA_CONFLUENCE_TOKEN_HERE=ATATT3xFfGF0xxxxxxxxxxxxx
   ```

3. **Replace the placeholder values:**
   - `YOUR_JIRA_EMAIL_HERE` → Your Confluence email address
   - `YOUR_JIRA_CONFLUENCE_TOKEN_HERE` → Your API token from Step 1

4. **Verify `.env` is gitignored:**
   ```bash
   git check-ignore .env  # Should output: .env
   ```

**Important:** The `.env` file is already in `.gitignore` to prevent accidentally committing credentials.

### How It Works

**Configuration Files:**
- **`.env`** - Contains your actual credentials (gitignored)
- **`.mcp.json`** - Contains MCP server configuration with environment variable placeholders (checked into git)

The `.mcp.json` file uses environment variable substitution with the `atlassian` MCP server:

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://mcp.atlassian.com/v1/sse"
      ],
      "env": {
        "ATLASSIAN_URL": "https://your-domain.atlassian.net",
        "ATLASSIAN_EMAIL": "${YOUR_JIRA_EMAIL_HERE}",
        "ATLASSIAN_API_TOKEN": "${YOUR_JIRA_CONFLUENCE_TOKEN_HERE}"
      }
    }
  }
}
```

**Note:**
- The `${...}` syntax reads values from your `.env` file
- The same API token works for both Jira and Confluence (Atlassian Cloud)
- You only need to edit the `ATLASSIAN_URL` if your domain differs

## Step 4: Manual Testing

After creating `.mcp.json`, verify the configuration is correct:

### 1. Verify File Exists
```bash
ls -la .mcp.json
```
Expected output: `-rw-r--r--  1 user  staff  XXX <date> .mcp.json`

### 2. Verify File is Gitignored
```bash
git check-ignore .mcp.json
```
Expected output: `.mcp.json`

If this doesn't output `.mcp.json`, the file is **not** gitignored. Add it to `.gitignore`:
```bash
echo ".mcp.json" >> .gitignore
```

### 3. Verify JSON is Valid
```bash
cat .mcp.json | jq .
```
Expected: JSON should parse without errors and display formatted configuration.

If `jq` is not installed:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### 4. Verify Configuration Values
```bash
cat .mcp.json | jq '.mcpServers.atlassian.args'
```
Expected: Should show your configured URLs, email, and token arguments.

**Note:** Confluence MCP connection testing (verifying API connectivity and authentication) will be available when Confluence-dependent skills are implemented. For now, verify that your configuration file is valid and properly formatted.

## Step 5: Restart Claude Code

Restart Claude Code to load the new MCP configuration:

```bash
# Exit Claude Code session
# Restart Claude Code in this directory
cd /path/to/team-management
claude
```

The Atlassian MCP server will be loaded automatically when Claude Code starts.

## Troubleshooting

### Configuration File Issues

#### `.mcp.json` Not Found
- Verify file exists: `ls -la .mcp.json`
- Copy from example: `cp mcp-config-example.json .mcp.json`
- Check you're in the repository root directory

#### Invalid JSON Syntax
- Test with: `cat .mcp.json | jq .`
- Common errors:
  - Missing commas between properties
  - Trailing commas in arrays/objects
  - Unquoted strings
  - Unclosed brackets or braces

#### File Not Gitignored
- Verify: `git check-ignore .mcp.json` should output `.mcp.json`
- If not gitignored: `echo ".mcp.json" >> .gitignore`
- Never commit credentials to git

### API Token Errors

#### "Authentication Failed" or "401 Unauthorized"
- **Verify API token is correct:** Copy token again from Atlassian account settings
- **Check token hasn't expired:** Regenerate token if old
- **Verify email matches:** Use the email associated with your Atlassian account
- **Test token manually:**
  ```bash
  curl -u your-email@example.com:your-api-token \
    https://your-company.atlassian.net/wiki/api/v2/spaces
  ```

#### "API Token Invalid" on Token Creation
- Token must be copied immediately after creation
- If you missed it, delete the old token and create a new one
- Don't confuse Jira tokens with Confluence tokens - use the same Atlassian API token for both

### Domain URL Format Issues

#### Wrong Confluence URL Format
**Confluence Cloud:**
- Correct: `https://your-company.atlassian.net/wiki`
- Incorrect: `https://your-company.atlassian.net` (missing `/wiki`)
- Incorrect: `http://your-company.atlassian.net/wiki` (use `https://`)

**Confluence Server/Data Center:**
- Correct: `https://confluence.company.com`
- Incorrect: `https://confluence.company.com/wiki` (don't add `/wiki` for server)

#### Cannot Connect to Confluence URL
- Verify URL in browser - you should be able to access it
- Check for typos in domain name
- Ensure you're using the correct instance (Cloud vs Server)
- Verify network access (VPN required?)

### Permission Scope Problems

#### "403 Forbidden" or "Access Denied"
- **Verify space permissions:** Your account must have "View Space" permission
- **Check restricted spaces:** Some spaces are restricted to specific groups
- **Contact Confluence admin:** Request necessary permissions
- **Test API access:**
  ```bash
  curl -u your-email@example.com:your-api-token \
    https://your-company.atlassian.net/wiki/api/v2/spaces/<SPACE_KEY>
  ```

#### No Spaces Found
- **Verify account has access:** Check Confluence web UI for visible spaces
- **Check search keyword:** Try space key instead of space name
- **Archived spaces:** Archived spaces won't appear in search
- **Private spaces:** Only spaces you can view will appear

### Atlassian MCP Server Issues

#### "MCP Server Failed to Start"
- **Check Node.js installed:** `node --version` (requires Node.js 16+)
- **Check npx works:** `npx --version`
- **Network issues:** MCP server needs to download on first run
- **Clear npm cache:** `npm cache clean --force`

#### "MCP Tools Not Available"
- **Restart Claude Code:** MCP servers load on startup
- **Verify configuration:** `cat .mcp.json | jq '.mcpServers.atlassian'`
- **Check server name:** Must be `atlassian` not `confluence` or `jira`
- **Review logs:** Check Claude Code output for MCP errors

### Shared Configuration (Jira + Confluence)

#### Jira Works But Confluence Doesn't
- **Verify `--confluence-url` argument:** Must include `/wiki` suffix for Cloud
- **Check separate tokens:** Ensure both `--jira-token` and `--confluence-token` are set
- **Test Confluence API separately:** Use `curl` to verify Confluence access

#### Confluence Works But Jira Doesn't
- **Verify `--jira-url` argument:** Should NOT include `/wiki` suffix
- **Check Jira permissions:** Ensure account has Jira access
- **Review URL format:** Jira and Confluence use different URL patterns

## Confluence Permissions Required

Your Confluence account needs:
- **View Space** - See space content
- **View Pages** - Access pages within spaces

Your API token inherits your account permissions.

## Security Best Practices

1. **Never commit tokens to git**
   - `.mcp.json` is gitignored by default - verify with `git check-ignore .mcp.json`
   - Use environment variables for tokens (preferred method)
   - If `.mcp.json` is accidentally committed, immediately:
     - Revoke the token in Atlassian account settings
     - Remove from git history: `git filter-branch` or BFG Repo-Cleaner
     - Generate new token

2. **Use dedicated service accounts** (for team use)
   - Create a service account with minimal permissions
   - Don't share personal API tokens
   - Service accounts provide better audit trails

3. **Rotate tokens regularly**
   - Generate new API tokens periodically (e.g., every 90 days)
   - Revoke old tokens in Atlassian account settings
   - Update `.mcp.json` with new token

4. **Limit token exposure**
   - Don't paste tokens in chat or email
   - Use secure secret management tools (e.g., 1Password, AWS Secrets Manager)
   - Avoid storing tokens in shell history

5. **Monitor token usage**
   - Review Confluence audit logs periodically
   - Revoke any suspicious or unused tokens
   - Set up alerts for unusual API activity

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
