# GitHub Organization Workflows

This repository contains reusable GitHub Actions workflows designed to automate project management tasks for the podaac organization. These workflows can be deployed across all repositories in the organization to ensure consistent handling of issues and pull requests.

## Workflow Naming Convention

Workflows in this repository use the `org-` prefix to indicate they are designed for organization-wide deployment:
- `org-add-to-project.yml` - Adds new issues/PRs to the project board
- `org-team-assignment.yml` - Assigns issues to team projects
- `org-close-pr-status.yml` - Updates status when PRs are closed

This naming helps distinguish between workflows meant for deployment vs. workflows that only run in this repository.

## Available Workflows

### 1. Add to Project Workflow (`org-add-to-project.yml`)

Automatically adds new issues and pull requests to the podaac organization project with a default status of "needs:triage".



### Important Note About Cross-Repository Workflows

⚠️ **GitHub Actions workflows cannot trigger across repositories.** This means:
- The workflow file must exist in **each repository** where you want it to run
- A workflow in the `.github` repository will NOT trigger for issues/PRs in other repositories
- You must deploy this workflow to all repositories where you want automatic project assignment

This repository provides automation scripts to help deploy the workflow across all your organization's repositories.

### Setup Instructions

1. **Find your project number:**
   - Go to your project URL: `https://github.com/orgs/podaac/projects/X`
   - The number `X` in the URL is your project number
   - Update line 24 in `.github/workflows/org-add-to-project.yml` with this number

2. **Create a Personal Access Token (PAT):**
   - Go to https://github.com/settings/tokens/new
   - Select "Generate new token (classic)" or use fine-grained tokens
   - Required scopes:
     - `repo` (Full control of private repositories)
     - `project` (Full control of projects)
     - `org:read` (Read org and team membership, read org projects)
   - Generate and copy the token

3. **Add the token as a secret:**
   - For organization-wide use:
     - Go to `https://github.com/organizations/podaac/settings/secrets/actions`
     - Click "New organization secret"
     - Name: `PROJECTS_PAT`
     - Value: Paste your token
     - Repository access: Set to "All repositories" or select specific repos

   - For a single repository:
     - Go to repository Settings > Secrets and variables > Actions
     - Click "New repository secret"
     - Name: `PROJECTS_PAT`
     - Value: Paste your token

4. **Verify the status field name:**
   - Open your project in GitHub
   - Check that you have a "Status" field with a "needs:triage" option
   - If the field or option has a different name, update the script accordingly

5. **Deploy the workflow:**

   **Option A: Automated deployment (Recommended)**

   Use the generalized deployment script to deploy to all repositories:

   ```bash
   # Deploy directly to main branch (faster, but no review)
   ./deploy-workflow-direct.sh org-add-to-project.yml "Add automatic project assignment workflow"
   ```

   Prerequisites:
   - GitHub CLI (`gh`) must be installed and authenticated
   - You need write access to all repositories in the organization

   **Option B: Manual deployment**

   Copy the workflow file to each repository:
   ```bash
   cd /path/to/your/repo
   mkdir -p .github/workflows
   cp /path/to/this/repo/.github/workflows/org-add-to-project.yml .github/workflows/
   git add .github/workflows/org-add-to-project.yml
   git commit -m "Add automatic project assignment workflow"
   git push
   ```

### How it works

- **Triggers:** When a new issue or pull request is opened
- **Actions:**
  1. Adds the item to the specified project using the `actions/add-to-project` action
  2. Sets the status field to "needs:triage" using the GitHub GraphQL API

### Troubleshooting

- If items aren't being added, check that the PAT has sufficient permissions
- If the status isn't being set, verify the field name and option name in your project
- Check the Actions tab in your repository for error logs
- Ensure the project number is correct in the workflow file

### Customization

To change the default status, modify line 35 in the workflow:
```javascript
const triageOption = statusField?.options.find(option => option.name === 'needs:triage');
```

Replace `'needs:triage'` with your desired status option name.

## Triage new tickets

All the new tickets are now automatically added to the podaac github project with a default status of "needs:triage". This allows the team to easily find and triage new issues and pull requests in one central location.

The action triage-report-to-slack sends a message to the #podaac-management channel in Slack whenever a new issue or pull request is created with the "needs:triage" status. This ensures that the team is immediately notified of new items that require attention and that no issue falls into cracks.

The Slack connection is configured using a webhook URL stored in the `SLACK_WEBHOOK_URL` secret. You can get the webhoob URL by creating an incoming webhook in your Slack workspace for a slack application, currently called "podaac issues needs triage".

### 2. Close PR Status Workflow (`org-close-pr-status.yml`)

Automatically updates the status of pull requests to "closed" in the podaac project when they are closed or merged.

#### How it works

- **Trigger:** When a pull request is closed (merged or closed without merging)
- **Actions:**
  1. Finds the PR in the podaac project (project #75)
  2. Updates the status field to "closed"
  3. Logs whether the PR was merged or closed without merging

#### Deployment

```bash
./deploy-workflow-direct.sh org-close-pr-status.yml "Add automatic PR closure status update"
```

**Note:** Ensure your project has a "closed" status option in the Status field.

### 3. Team Assignment Workflow (`org-team-assignment.yml`)

Automates the process of assigning issues to specific teams when they are labeled with a `team:<team_name>` label (e.g., `team:tva`, `team:forge`, etc.).

### How it works

- **Trigger:** When an issue is labeled with a label matching the pattern `team:<team_name>`
- **Actions:**
  1. Updates the status in the podaac project (project #75) to "triaged"
  2. Searches for an organization project named exactly as the team name (e.g., a project named "tva" for the label "team:tva")
  3. If the team project exists:
     - Adds the issue to the team project (if not already there)
     - Status is managed by the team project's automation workflows
  4. If no matching team project is found, logs a notice and completes gracefully

### Setup Instructions

1. **Use the PAT configured for other workflows:**
   - This workflow uses the same `PROJECTS_PAT` secret as the other workflows
   - Ensure the PAT has the required permissions (see "Add to Project Workflow" section above)

2. **Configure your team projects:**
   - Create organization projects named after your teams (e.g., "tva", "pse", ...)
   - Configure project automation workflows in each team project to handle status assignments
   - The project name match is case-insensitive

3. **Create team labels:**
   - Create labels in your repositories following the pattern: `team:<team_name>`
   - Examples: `team:tva`, `team:pse`, `team:pde`, etc...
   - These can be created at the organization level or per-repository

4. **Deploy the workflow:**

   ```bash
   ./deploy-workflow-direct.sh org-team-assignment.yml "Add team assignment automation"
   ```

### Usage

1. An issue is created and automatically added to the podaac project with "needs:triage" status
2. A team lead reviews the issue and applies the appropriate team label (e.g., `team:tva`)
3. The workflow automatically:
   - Changes the status in podaac project from "needs:triage" to "triaged"
   - Adds the issue to the team's project (if it exists)
   - The team project's automation workflows handle status assignment

### Troubleshooting

- **Status not updating to "triaged":** Verify the issue is in the podaac project and has a "triaged" status option
- **Issue not added to team project:** Check that a project exists with the exact team name (case-insensitive)
- **Workflow not triggering:** Ensure the label matches the pattern `team:<team_name>` exactly

#### Example Flow

1. Issue #123 is created → automatically added to podaac project with status "needs:triage"
2. Team lead adds label `team:tva` to issue #123
3. Workflow runs:
   - ✅ Updates status to "triaged" in podaac project
   - ✅ Finds project named "tva"
   - ✅ Adds issue #123 to "tva" project
   - ✅ Team project automation handles status assignment

## Deployment Scripts

This repository includes automated scripts to deploy and manage workflows across all organization repositories.

### `deploy-workflow-direct.sh`

Deploys or updates a workflow to all non-archived repositories in the organization.

**Usage:**
```bash
./deploy-workflow-direct.sh <workflow-filename> [commit-message]
```

**Examples:**
```bash
# Deploy the add-to-project workflow
./deploy-workflow-direct.sh org-add-to-project.yml

# Deploy with custom commit message
./deploy-workflow-direct.sh org-team-assignment.yml "Update team assignment automation"
```

**Features:**
- Creates new workflows or updates existing ones
- Shows progress for each repository
- Provides summary of successes, updates, and failures
- Validates workflow file exists before deploying
- Lists available workflows if no filename provided

### `remove-workflow-direct.sh`

Removes a workflow from all repositories in the organization.

**Usage:**
```bash
./remove-workflow-direct.sh <workflow-filename> [commit-message]
```

**Examples:**
```bash
# Remove a deprecated workflow
./remove-workflow-direct.sh org-old-workflow.yml

# Remove with custom commit message
./remove-workflow-direct.sh org-deprecated.yml "Remove deprecated automation"
```

**Safety Features:**
- Requires typing "DELETE" to confirm (not just Enter)
- Only removes workflows that exist
- Shows which repos were skipped vs. successfully removed

**Prerequisites for both scripts:**
- GitHub CLI (`gh`) must be installed and authenticated
- You need write access to all repositories in the organization
- The scripts operate on the `podaac` organization (update `ORG` variable if different)