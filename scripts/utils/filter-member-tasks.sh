#!/bin/bash
# Filter Jira tasks by member email
# Usage: filter-member-tasks.sh <jira-json-file> <member-email> <member-name>

set -euo pipefail

json_file="${1:?Jira JSON file required}"
member_email="${2:?Member email required}"
member_name="${3:?Member name required}"

# Extract and filter tasks for specific member
cat "$json_file" | \
jq -r '.[0].text' | \
jq -r --arg email "$member_email" \
  '.issues[] | 
   select(.assignee.email == $email) |
   [.key, .summary, .status.name] | @tsv' | \
while IFS=$'\t' read -r key summary task_status; do
  # Truncate summary to 40 chars
  if [ ${#summary} -gt 40 ]; then
    summary="${summary:0:37}..."
  fi
  
  echo "$key|$summary|$task_status"
done
