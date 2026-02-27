# Claude Team Manager - Product Summary

## Project Vision

To provide engineering managers with real-time visibility into team velocity and progress entirely within the Claude Code environment, enabling them to track team progress during coding sessions without meetings or context switching.

## Target Audience

Tech leads and engineering managers who use Claude Code and oversee development teams (5-15 developers), responsible for tracking sprint progress, identifying blockers, and reporting team velocity—all without leaving their CLI.

## Core Features

- **Claude Code Native Commands** - Dedicated commands for team management (e.g., `/team-status`, `/create-task`, `/sprint-create`)
- **Individual Member Progress Tracking** - View specific team member's work, activity, and contributions via `/member-progress`
- **GitLab Integration** - Sync with GitLab issues, merge requests, commits, and pipeline status
- **Jira Integration** - Bi-directional sync with Jira tickets, status updates, and sprint planning
- **Confluence Integration** - Access team documentation and project pages without leaving Claude Code
- **MCP Agent Integration** - Leverage Claude's MCP agents to automate task tracking and status updates
- **Repository-Based Storage** - All team data stored locally in version-controlled JSON/markdown files
- **Real-time Status Commands** - Instant team dashboard, task lists, and blocker visualization via dedicated CLI commands
- **Natural Language Task Management** - Create, assign, and update tasks through conversational commands
- **Blocker and Dependency Tracking** - Mark and visualize task dependencies through dedicated commands
- **Sprint/Milestone Planning** - Group tasks into sprints and track velocity via dedicated commands
- **Git-Based Team Discovery** - Automatically discover team members from git commit history

## Success Metrics

- **Primary:** 90% of team progress visible without meetings, entirely within Claude Code
- **Secondary:** Reduce developer interruptions, increase adoption rate across teams, accelerate new manager onboarding, improve dependency visibility

## Key Constraints

- **Claude Code only** - No web interfaces, external services, or standalone applications
- **Repository-based** - All data lives in git-versioned files, synchronized through normal git workflows
- **CLI-first** - Text-based terminal interface, no GUI components
- **Command-based** - Each operation is a dedicated command, not parameters to a single command
- **External tool integration** - Syncs with GitLab, Jira, and Confluence but all interactions happen via CLI
