#!/bin/bash

# Script to deploy the team-assignment workflow directly to main branch (no PR)
# Usage: ./deploy-workflow-direct.sh
# WARNING: This commits directly to the default branch. Use with caution!

set -e

ORG="podaac"
WORKFLOW_FILE=".github/workflows/team-assignment.yml"
COMMIT_MESSAGE="Add automatic team/project assignment workflow

This workflow automatically, when team label is assigned to an issue:
- Set podaac project status to triage
- Assign to the team github project when it exists, with a New status.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚠️  WARNING: This will commit directly to the default branch!${NC}"
echo -e "${YELLOW}Press Ctrl+C to cancel, or Enter to continue...${NC}"
read

echo -e "${GREEN}Fetching all repositories in the $ORG organization...${NC}"

# Get all repositories in the organization (excluding archived repos)
REPOS=$(gh repo list "$ORG" --limit 1000 --json name,isArchived --jq '.[] | select(.isArchived == false) | .name')

if [ -z "$REPOS" ]; then
    echo -e "${RED}No repositories found or you don't have access to the organization${NC}"
    exit 1
fi

echo -e "${GREEN}Found $(echo "$REPOS" | wc -l | xargs) repositories${NC}\n"

# Read the workflow file content
if [ ! -f "$WORKFLOW_FILE" ]; then
    echo -e "${RED}Error: Workflow file not found at $WORKFLOW_FILE${NC}"
    exit 1
fi

# Counter for tracking
SUCCESS_COUNT=0
UPDATE_COUNT=0
FAIL_COUNT=0

# Process each repository
while IFS= read -r REPO; do
    echo -e "${YELLOW}Processing: $ORG/$REPO${NC}"

    # Get base64 encoded content
    CONTENT_BASE64=$(base64 -i "$WORKFLOW_FILE")

    # Check if workflow already exists and get its SHA
    EXISTING_FILE=$(gh api "repos/$ORG/$REPO/contents/.github/workflows/team-assignment.yml" 2>/dev/null || echo "")

    if [ -n "$EXISTING_FILE" ]; then
        # Workflow exists, get its SHA for updating
        FILE_SHA=$(echo "$EXISTING_FILE" | jq -r '.sha')
        echo -e "  🔄 Workflow exists, updating..."

        # Update the file via API
        if gh api \
            --method PUT \
            -H "Accept: application/vnd.github+json" \
            "/repos/$ORG/$REPO/contents/.github/workflows/team-assignment.yml" \
            -f "message=$COMMIT_MESSAGE" \
            -f "content=$CONTENT_BASE64" \
            -f "sha=$FILE_SHA" &>/dev/null; then
            echo -e "  ${GREEN}✅ Workflow updated successfully${NC}"
            ((UPDATE_COUNT++))
        else
            echo -e "  ${RED}❌ Failed to update workflow${NC}"
            ((FAIL_COUNT++))
        fi
    else
        # Workflow doesn't exist, create it
        echo -e "  ➕ Creating new workflow..."

        if gh api \
            --method PUT \
            -H "Accept: application/vnd.github+json" \
            "/repos/$ORG/$REPO/contents/.github/workflows/team-assignment.yml" \
            -f "message=$COMMIT_MESSAGE" \
            -f "content=$CONTENT_BASE64" &>/dev/null; then
            echo -e "  ${GREEN}✅ Workflow added successfully${NC}"
            ((SUCCESS_COUNT++))
        else
            echo -e "  ${RED}❌ Failed to add workflow${NC}"
            ((FAIL_COUNT++))
        fi
    fi

    echo ""

done <<< "$REPOS"

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Summary:${NC}"
echo -e "  ${GREEN}✅ Successfully added: $SUCCESS_COUNT repos${NC}"
echo -e "  ${GREEN}🔄 Successfully updated: $UPDATE_COUNT repos${NC}"
echo -e "  ${RED}❌ Failed: $FAIL_COUNT repos${NC}"
echo -e "${GREEN}========================================${NC}"

TOTAL_SUCCESS=$((SUCCESS_COUNT + UPDATE_COUNT))
if [ $TOTAL_SUCCESS -gt 0 ]; then
    echo -e "\n${GREEN}Next steps:${NC}"
    echo "1. Verify the workflows are active in each repository"
    echo "2. Ensure the PROJECTS_PAT secret is configured at:"
    echo "   https://github.com/organizations/podaac/settings/secrets/actions"
    echo "3. Test by applying a team label to an issue in any repository"
fi
