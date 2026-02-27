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

Configure MCP credentials using the repository-local `.env` file.

**Location:** `.env` in repository root

**Setup Instructions:**

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env`** and add your GitLab credentials:
   ```bash
   YOUR_GITLAB_TOKEN_HERE=glpat-xxxxxxxxxxxxxxxxxxxx
   ```

3. **Replace the placeholder value:**
   - `YOUR_GITLAB_TOKEN_HERE` → Your personal access token from Step 1

4. **(Optional) For self-hosted GitLab:**

   The `.mcp.json` file is pre-configured for GitLab.com. If using self-hosted GitLab, edit `.mcp.json` and change the API URL:
   ```json
   "GITLAB_API_URL": "https://your-gitlab.com/api/v4"
   ```

5. **Verify `.env` is gitignored:**
   ```bash
   git check-ignore .env
   # Should output: .env
   ```

**Important:** The `.env` file is already in `.gitignore` to prevent accidentally committing credentials. The `.mcp.json` file uses environment variable substitution (`${YOUR_GITLAB_TOKEN_HERE}`) to read secrets from `.env`.

## Step 3: Manual Testing

After configuring GitLab MCP, verify your setup is correct before using it:

### Configuration Validation

Run these commands to verify your configuration:

```bash
# 1. Verify .env file exists
ls -la .env

# 2. Verify it's gitignored
git check-ignore .env
# Should output: .env

# 3. Verify .env contains your GitLab token
grep YOUR_GITLAB_TOKEN_HERE .env
# Should show: YOUR_GITLAB_TOKEN_HERE=glpat-...
```

### GitLab MCP Connection Test

Test the GitLab MCP integration to ensure authentication works:

1. **Open Claude Code** in the repository directory
2. **Run the add-team-members skill:**
   ```
   /add-team-members --team=<any-team>
   ```
3. **Enter a member name** that exists in your GitLab instance (e.g., your own username or a colleague's name)
4. **Verify GitLab search works:** Claude should search GitLab and present user options matching your search
5. **If an error appears:**
   - Check your token permissions (see Step 1)
   - Verify the API URL is correct (Step 2)
   - See the Troubleshooting section below

### Test Project Linking (Optional)

If you plan to link projects to GitLab repositories:

1. Run `/add-project --team=<your-team>`
2. Choose "Yes, link to external tools"
3. Select "GitLab"
4. Search for a project by name
5. Verify GitLab projects appear in search results

## Troubleshooting

### "GitLab MCP not configured" Error

**Symptoms:** Error message when running `/add-team-members` or skills fail to detect GitLab information

**Solutions:**
- Verify `.env` exists in the repository root and contains `YOUR_GITLAB_TOKEN_HERE=...`
- Check that `.mcp.json` exists in the repository root with the `gitlab` section
- Restart Claude Code after modifying `.env`
- Verify your GitLab token is set correctly: `grep YOUR_GITLAB_TOKEN_HERE .env`

### "Authentication Failed" Errors

**Symptoms:** GitLab API returns authentication errors, unable to search users/projects

**Solutions:**
- Verify your Personal Access Token is correct (check for typos when copying)
- Check token hasn't expired (go to GitLab → Settings → Access Tokens)
- Ensure token has required scopes:
  - ✅ `read_api` - Read-only API access
  - ✅ `read_user` - Read user information
  - ✅ `read_repository` - Read repository information
- For self-hosted GitLab: verify the `GITLAB_API_URL` is correct (must end with `/api/v4`)

### API URL Errors

**Symptoms:** Connection errors, "Cannot reach GitLab API", or incorrect API responses

**Solutions:**
- **For GitLab.com:** Use `https://gitlab.com/api/v4` (not `https://gitlab.com`)
- **For self-hosted GitLab:** Use `https://your-gitlab-domain.com/api/v4`
- Verify the URL is reachable:
  ```bash
  curl --header "PRIVATE-TOKEN: your-token" \
    "https://gitlab.com/api/v4/users?search=name"
  ```
- Check for typos in the domain name
- Ensure your network can reach the GitLab instance (firewall/VPN issues)

### Token Permission Issues

**Symptoms:** "403 Forbidden" errors, unable to access certain users or projects

**Solutions:**
- Check token scopes in GitLab settings (Settings → Access Tokens)
- Ensure token has `read_api`, `read_user`, and `read_repository` scopes
- For private repositories: verify your GitLab account has access
- Try creating a new token with the correct scopes if unsure

### No Users/Projects Found

**Symptoms:** Search returns empty results even though users/projects exist

**Solutions:**
- Verify your GitLab account has access to the users/projects you're searching for
- Check search keyword spelling (try searching for your own username first)
- For private projects: ensure your token has appropriate access rights
- Verify the GitLab instance is accessible and responding
- Try searching with a different keyword or partial name

### "Rate Limit Exceeded"

**Symptoms:** API requests fail with rate limit error messages

**Solutions:**
- GitLab API has rate limits that vary by plan:
  - GitLab.com Free: 2,000 requests per minute
  - GitLab.com Paid: Higher limits based on plan
  - Self-hosted: Default 600 requests per minute (configurable)
- Wait a few minutes and try again
- Consider creating a dedicated service account with higher limits
- Contact your GitLab administrator to increase rate limits (self-hosted only)

## GitLab API Limits

### GitLab.com:
- **Free tier**: 2,000 requests per minute
- **Paid tiers**: Higher limits based on plan

### Self-Hosted:
- Default: 600 requests per minute per user
- Configurable by GitLab administrators

## Security Best Practices

1. **Never commit tokens to git**
   - The `.env` file is already in `.gitignore` to prevent credential leaks
   - Always verify `.env` is gitignored before committing: `git check-ignore .env`
   - The `.mcp.json` file only contains placeholders (`${...}`) and is safe to commit

2. **Use minimal scope tokens**
   - Only enable `read_*` scopes (`read_api`, `read_user`, `read_repository`)
   - Don't use tokens with `write_*` or `api` (full access) scopes
   - The team management system only needs read access to GitLab

3. **Set token expiration**
   - Configure tokens to expire after a reasonable period (e.g., 90 days)
   - Rotate tokens regularly before they expire
   - Set calendar reminders for token rotation

4. **Monitor token usage**
   - Review GitLab audit logs periodically
   - Revoke unused or suspicious tokens immediately
   - Check active tokens in GitLab Settings → Access Tokens

5. **Dedicated service account** (for team use)
   - Create a service account for shared team access
   - Don't use personal accounts for shared integrations
   - Service accounts provide better audit trails and access control

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
1. **Check the troubleshooting section above** for common problems and solutions
2. **Verify token permissions** in GitLab settings (Settings → Access Tokens)
3. **Test API access directly** using `curl` to rule out network/authentication issues:
   ```bash
   curl --header "PRIVATE-TOKEN: your-token" \
     "https://gitlab.com/api/v4/users?search=name"
   ```
   Replace `your-token` with your actual token and adjust the URL for self-hosted instances.
4. **Verify `.env` file exists:** Must be in the repository root with your GitLab token
5. **Check token is set:** Run `grep YOUR_GITLAB_TOKEN_HERE .env` to verify
