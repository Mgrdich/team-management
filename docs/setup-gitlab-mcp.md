# GitLab MCP Setup Guide

This guide explains how to configure the GitLab MCP (Model Context Protocol) integration for the team management system.

## Prerequisites

- Claude Code CLI installed
- GitLab account (GitLab.com or self-hosted)
- Personal Access Token or OAuth token

## Overview

The GitLab MCP integration enables:
- Auto-detecting Git information when adding team members (`/add-team-members`)
- Linking projects to GitLab repositories (`/add-project`)
- Searching and selecting GitLab projects by name

## Step 1: Create GitLab Personal Access Token

### For GitLab.com:

1. Go to [https://gitlab.com/-/profile/personal_access_tokens](https://gitlab.com/-/profile/personal_access_tokens)
2. Click **"Add new token"**
3. Enter token name: `Team Management MCP`
4. Set expiration date (optional, but recommended)
5. Select scopes:
   - ✅ `read_api` - Read-only API access
   - ✅ `read_user` - Read user information
   - ✅ `read_repository` - Read repository information
6. Click **"Create personal access token"**
7. **Copy the token immediately** - you won't see it again!

### For Self-Hosted GitLab:

Same steps, but use your GitLab instance URL:
`https://your-gitlab.com/-/profile/personal_access_tokens`

## Step 2: Configure GitLab MCP

Create or update your MCP configuration file:

**Location:** `~/.claude/mcp.json` (or project-specific `.claude/mcp.json`)

**Add GitLab MCP configuration:**

```json
{
  "mcpServers": {
    "gitlab": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-gitlab",
        "--token",
        "YOUR_PERSONAL_ACCESS_TOKEN",
        "--url",
        "https://gitlab.com"
      ]
    }
  }
}
```

**For self-hosted GitLab**, change the URL:
```json
"--url",
"https://your-gitlab.com"
```

**Replace `YOUR_PERSONAL_ACCESS_TOKEN`** with your token from Step 1.

**Alternative: Environment Variable**

For better security, use an environment variable:

```json
{
  "mcpServers": {
    "gitlab": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-gitlab"
      ],
      "env": {
        "GITLAB_TOKEN": "YOUR_PERSONAL_ACCESS_TOKEN",
        "GITLAB_URL": "https://gitlab.com"
      }
    }
  }
}
```

Or set in your shell profile:
```bash
export GITLAB_TOKEN="glpat-your-token-here"
export GITLAB_URL="https://gitlab.com"
```

## Step 3: Verify Installation

Restart Claude Code and verify GitLab MCP is loaded:

```bash
# Check if GitLab tools are available
# GitLab MCP should provide tools like:
# - search_users
# - search_projects
# - get_project
```

Test the `/add-team-members` skill with a member name to verify GitLab user search works.

## Step 4: Test GitLab Integration

### Test User Search:
1. Run `/add-team-members --team=<your-team>`
2. Enter a team member's name
3. Verify GitLab presents matching user accounts

### Test Project Linking:
1. Run `/add-project --team=<your-team>`
2. Choose "Yes, link to external tools"
3. Select "GitLab"
4. Search for a project
5. Verify GitLab projects appear in search results

## Troubleshooting

### "GitLab MCP not configured" Error

- Verify `mcp.json` exists at `~/.claude/mcp.json`
- Check that the GitLab MCP entry is correct
- Restart Claude Code after modifying `mcp.json`

### "Authentication Failed" Errors

- Verify your Personal Access Token is correct
- Check token hasn't expired
- Ensure token has required scopes (`read_api`, `read_user`, `read_repository`)
- For self-hosted: verify GitLab URL is correct

### No Users/Projects Found

- Verify your GitLab account has access to the users/projects
- Check search keyword spelling
- For private projects: ensure token has appropriate access
- Verify the GitLab instance is accessible

### "Rate Limit Exceeded"

- GitLab API has rate limits (varies by plan)
- Wait a few minutes and try again
- Consider creating a dedicated service account with higher limits

## GitLab API Limits

### GitLab.com:
- **Free tier**: 2,000 requests per minute
- **Paid tiers**: Higher limits based on plan

### Self-Hosted:
- Default: 600 requests per minute per user
- Configurable by GitLab administrators

## Security Best Practices

1. **Never commit tokens to git**
   - Add `.claude/mcp.json` to `.gitignore` if storing tokens there
   - Use environment variables for tokens

2. **Use minimal scope tokens**
   - Only enable `read_*` scopes
   - Don't use tokens with `write_*` or `api` (full access) scopes

3. **Set token expiration**
   - Configure tokens to expire after reasonable period
   - Rotate tokens regularly (e.g., every 90 days)

4. **Monitor token usage**
   - Review GitLab audit logs periodically
   - Revoke unused or suspicious tokens

5. **Dedicated service account** (for team use)
   - Create a service account for shared team access
   - Don't use personal accounts for shared integrations

## Additional Resources

- [GitLab API Documentation](https://docs.gitlab.com/ee/api/)
- [GitLab Personal Access Tokens](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)
- [MCP Documentation](https://modelcontextprotocol.io/)
- [Claude Code MCP Guide](https://docs.anthropic.com/claude/docs/mcp)

## Related Skills

- `/add-team-members` - Uses GitLab MCP to auto-detect git info
- `/add-project` - Uses GitLab MCP to link projects to repositories

## Need Help?

If you encounter issues:
1. Check the troubleshooting section above
2. Verify token permissions in GitLab settings
3. Test API access using `curl`:
   ```bash
   curl --header "PRIVATE-TOKEN: your-token" \
     "https://gitlab.com/api/v4/users?search=name"
   ```
