# GitHub Organization Workflows

## Add to Project Workflow

This workflow automatically adds new issues and pull requests to the podaac organization project with a default status of "needs:triage".

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
   - Copy the `.github` folder to each repository in your organization, OR
   - Use this repository as a centralized workflow location if using organization-level workflows

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
