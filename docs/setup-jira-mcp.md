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

**Important:** Jira and Confluence both use the same `atlassian` MCP server configuration. If you've already configured Confluence MCP, your Jira integration is already set up and you can skip to the verification steps.

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

### Using the Environment File

This project uses a `.env` file to store MCP credentials securely:

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env`** and add your Jira credentials:
   ```bash
   YOUR_JIRA_EMAIL_HERE=your-email@example.com
   YOUR_JIRA_CONFLUENCE_TOKEN_HERE=ATATT3xFfGF0xxxxxxxxxxxxx
   ```

3. **Replace the placeholder values:**
   - `YOUR_JIRA_EMAIL_HERE` → Your Jira email address
   - `YOUR_JIRA_CONFLUENCE_TOKEN_HERE` → Your API token from Step 1

4. **Verify `.env` is gitignored:**
   ```bash
   git check-ignore .env  # Should output: .env
   ```

**Important:** The `.env` file is already in `.gitignore` to prevent accidentally committing credentials. The `.mcp.json` file uses environment variable substitution to read secrets from `.env`.

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
- Jira and Confluence share the same credentials when using Atlassian Cloud
- You only need to edit the `ATLASSIAN_URL` if your domain differs

**Alternative: Direct Configuration**

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
        "JIRA_TOKEN": "YOUR_API_TOKEN",
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
export JIRA_URL="https://your-company.atlassian.net"
export JIRA_EMAIL="your-email@example.com"
export JIRA_TOKEN="your-api-token"
export CONFLUENCE_URL="https://your-company.atlassian.net/wiki"
export CONFLUENCE_EMAIL="your-email@example.com"
export CONFLUENCE_TOKEN="your-api-token"
```

## Step 4: Manual Testing

Before using the Jira integration, verify your configuration is valid:

### 1. Verify Configuration File Exists
```bash
# Check that .mcp.json exists in repository root
ls -la .mcp.json
```

Expected output: Should show the `.mcp.json` file with appropriate permissions.

### 2. Verify Gitignore Protection
```bash
# Verify the file is gitignored to prevent committing credentials
git check-ignore .mcp.json
```

Expected output: `.mcp.json` (confirms the file is properly ignored)

### 3. Verify JSON Syntax
```bash
# Validate JSON is properly formatted
cat .mcp.json | jq .
```

Expected output: Formatted JSON configuration without syntax errors. If `jq` is not installed, you can use:
```bash
python3 -m json.tool .mcp.json
```

### 4. Verify Configuration Values
Manually review `.mcp.json` to ensure:
- ✓ Jira URL is correct (e.g., `https://your-company.atlassian.net`)
- ✓ Email address matches your Jira account
- ✓ API token is the full token string (not a placeholder)
- ✓ No placeholder text remains (`YOUR_*` values replaced)

**Note:** Full Jira MCP connection testing (verifying API access, searching boards, etc.) will be available once Jira-dependent skills are implemented. For now, these manual validation steps ensure your configuration is properly formatted and ready for use.

## Step 5: Restart Claude Code

Restart Claude Code to load the new MCP configuration:

```bash
# Exit current session
exit

# Start new session
claude code
```

The Atlassian MCP server will be automatically loaded from `.mcp.json`.

## Step 6: Test Jira Integration (Future)

**Note:** Full integration testing will be available once Jira-dependent skills are implemented. Future testing will include:

### Test Board Linking:
1. Run `/add-project --team=<your-team>`
2. Provide project details
3. Choose "Yes, link to external tools"
4. Select "Jira"
5. Enter a search keyword
6. Verify Jira boards appear in search results
7. Select a board to link

For now, you can verify basic API connectivity using `curl` (see "Need Help?" section below).

## Troubleshooting

### Configuration File Issues

#### `.mcp.json` not found
- Verify you're in the repository root directory
- Copy from example: `cp mcp-config-example.json .mcp.json`
- Check file isn't hidden: `ls -la .mcp.json`

#### Invalid JSON syntax
- Run validation: `cat .mcp.json | jq .`
- Common issues:
  - Missing commas between entries
  - Unclosed quotes or brackets
  - Trailing commas (not allowed in JSON)
- Use a JSON validator or editor with syntax highlighting

#### Configuration not loaded
- Restart Claude Code after modifying `.mcp.json`
- Check Claude Code looks for `.mcp.json` in current directory
- Verify no syntax errors in JSON

### API Token and Authentication Issues

#### "Authentication Failed" or "401 Unauthorized"
- **API token incorrect:** Regenerate token at [https://id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
- **Token expired:** Tokens don't expire automatically, but can be revoked. Create a new token.
- **Email mismatch:** Email in `.mcp.json` must exactly match your Atlassian account email
- **Test with curl:**
  ```bash
  curl -u your-email@example.com:your-api-token \
    https://your-company.atlassian.net/rest/api/3/myself
  ```
  Should return your account information if credentials are valid.

#### "403 Forbidden" or "Access Denied"
- **Insufficient permissions:** Your Jira account needs "Browse Projects" and "View Development Tools" permissions
- **Private boards:** Ensure you have access to the boards/projects you're trying to view
- **Contact admin:** Ask your Jira administrator to verify your permissions

### Domain URL Format Issues

#### Invalid Jira URL
- **Must include protocol:** Use `https://your-company.atlassian.net` (not `your-company.atlassian.net`)
- **No trailing slash:** Use `https://your-company.atlassian.net` (not `https://your-company.atlassian.net/`)
- **Correct subdomain:** For Jira Cloud, use `*.atlassian.net` format
- **For Jira Server/Data Center:** Use your custom domain (e.g., `https://jira.yourcompany.com`)

#### Confluence URL different from Jira
- If Confluence is hosted separately, use different URLs:
  ```json
  "--jira-url", "https://your-company.atlassian.net",
  "--confluence-url", "https://your-company.atlassian.net/wiki"
  ```

### Permission Scope Problems

#### Missing board access
- **Board visibility:** Boards inherit permissions from their projects
- **Project access:** Ensure you have "Browse Projects" on the board's project
- **Board filters:** Some boards use JQL filters that may restrict visibility
- **Archived projects:** Boards in archived projects may not be accessible

#### Unable to search or list boards
- **Jira Software license:** Board features require Jira Software (not just Jira Core)
- **Permission level:** You need at least "Browse Projects" permission
- **Rate limiting:** Wait a few minutes and retry if you're hitting rate limits

### Rate Limiting

- **Jira Cloud limits:** 10,000 requests/hour for paid plans, lower for free plans
- **Symptoms:** HTTP 429 errors or "Rate limit exceeded" messages
- **Solutions:**
  - Wait 10-15 minutes before retrying
  - Reduce request frequency
  - Use a dedicated service account with higher limits

### MCP Server Issues

#### Atlassian MCP server not starting
- **npx not found:** Ensure Node.js and npm are installed: `node --version`
- **Network issues:** Check internet connectivity for downloading MCP server
- **Package install fails:** Clear npm cache: `npm cache clean --force`

#### MCP server crashes or timeouts
- **Check logs:** Look for error messages in Claude Code output
- **Restart Claude Code:** Exit and restart to reload MCP servers
- **Update MCP server:** npx automatically uses latest version, but you can clear cache: `rm -rf ~/.npm/_npx`

### No Boards Found

- Verify your Jira account has access to boards
- Check search keyword spelling
- Ensure boards aren't in archived projects
- Try searching with different keywords
- Verify you have Jira Software (boards not available in Jira Core)

## Jira Permissions Required

Your Jira account needs:
- **Browse Projects** - View projects and their content
- **View Development Tools** - See boards (Jira Software)

Your API token inherits your account permissions.

## Security Best Practices

1. **Never commit tokens to git**
   - `.mcp.json` is already in `.gitignore` to prevent accidental commits
   - Verify before committing: `git check-ignore .mcp.json`
   - Alternatively, use environment variables for tokens

2. **Use dedicated service accounts** (for team use)
   - Create a service account with minimal permissions
   - Don't share personal API tokens
   - Service accounts provide better audit trails

3. **Rotate tokens regularly**
   - Generate new API tokens periodically (e.g., every 90 days)
   - Revoke old tokens in Atlassian account settings
   - Keep track of where tokens are used

4. **Limit token exposure**
   - Don't paste tokens in chat, email, or documentation
   - Use secure secret management tools for team sharing
   - Never commit `.mcp.json` to version control

5. **Monitor token usage**
   - Review Jira audit logs periodically
   - Revoke any suspicious or unused tokens
   - Set up alerts for unusual API activity

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
