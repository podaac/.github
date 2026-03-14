# GitHub Organization Workflows

This project contains GitHub Actions workflows designed to automate project management tasks for the podaac organization. These workflows can be deployed across all repositories in the organization to ensure consistent handling of issues and pull requests.


## Add to Project Workflow

This workflow automatically adds new issues and pull requests to the podaac organization project with a default status of "needs:triage".

When an issue or pull request is closed, the "closed" status is automatically assigned in the podaac project. It does not matter that it has not been assigned to a team as the ticket is closed and no work is expected on it anymore.



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
   - Update line 20 in `.github/workflows/add-to-project.yml` with this number

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

   Use the provided scripts to deploy to all repositories:

   ```bash
   # Deploy via Pull Requests (safer, allows review)
   ./deploy-workflow.sh

   # OR deploy directly to main branch (faster, but no review)
   ./deploy-workflow-direct.sh
   ```

   Prerequisites:
   - GitHub CLI (`gh`) must be installed and authenticated
   - You need write access to all repositories in the organization

   **Option B: Manual deployment**

   Copy the workflow file to each repository:
   ```bash
   cd /path/to/your/repo
   mkdir -p .github/workflows
   cp /path/to/this/repo/.github/workflows/add-to-project.yml .github/workflows/
   git add .github/workflows/add-to-project.yml
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

## Team Assignment Workflow

This workflow automates the process of assigning issues to specific teams when they are labeled with a `team:<team_name>` label (e.g., `team:tva`, `team:forge`, etc.).

### How it works

- **Trigger:** When an issue is labeled with a label matching the pattern `team:<team_name>`
- **Actions:**
  1. Updates the status in the podaac project (project #75) to "triaged"
  2. Searches for an organization project named exactly as the team name (e.g., a project named "tva" for the label "team:tva")
  3. If the team project exists:
     - Adds the issue to the team project
     - Sets the status to "New" in the team project
  4. If no matching team project is found, logs a notice and completes gracefully

### Setup Instructions

1. **Use the PAT configured for other workflows:**
   - This workflow uses the same `PROJECTS_PAT` secret as the other workflows
   - Ensure the PAT has the required permissions (see "Add to Project Workflow" section above)

2. **Configure your team projects:**
   - Create organization projects named after your teams (e.g., "tva", "pse", ...)
   - Ensure each team project has a "Status" field with a "New" option
   - The project name match is case-insensitive

3. **Create team labels:**
   - Create labels in your repositories following the pattern: `team:<team_name>`
   - Examples: `team:tva`, `team:pse`, `team:pde`, etc...
   - These can be created at the organization level or per-repository

4. **Deploy the workflow:**

    ```
    chmod +x deploy-team-assignment-direct.sh
    ./deploy-team-assignment-direct.sh
     ```

### Usage

1. An issue is created and automatically added to the podaac project with "needs:triage" status
2. A team lead reviews the issue and applies the appropriate team label (e.g., `team:tva`)
3. The workflow automatically:
   - Changes the status in podaac project from "needs:triage" to "triaged"
   - Adds the issue to the team's project (if it exists)
   - Sets the status to "New" in the team project

### Troubleshooting

- **Status not updating to "triaged":** Verify the issue is in the podaac project and has a "triaged" status option
- **Issue not added to team project:** Check that a project exists with the exact team name (case-insensitive)
- **Status not set to "New" in team project:** Verify the team project has a "Status" field with a "New" option
- **Workflow not triggering:** Ensure the label matches the pattern `team:<team_name>` exactly

### Example Flow

1. Issue #123 is created → automatically added to podaac project with status "needs:triage"
2. Team lead adds label `team:tva` to issue #123
3. Workflow runs:
   - ✅ Updates status to "triaged" in podaac project
   - ✅ Finds project named "tva"
   - ✅ Adds issue #123 to "tva" project
   - ✅ Sets status to "New" in "tva" project