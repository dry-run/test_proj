#!/bin/bash 
GHES_HOST="<your-ghes-host>"
ORG_NAME="<your-org-name>"
ACCESS_TOKEN="<your-access-token>"
API_ENDPOINT="https://$GHES_HOST/api/v3/orgs/$ORG_NAME/repos?type=all&per_page=100&page=1"
# Retrieve a list of repositories with open pull requests
repos_with_prs=()
while read -r repo; do
    repo_name=$(echo "$repo" | jq -r '.name')
    pr_count=$(curl -s -H "Authorization: token $ACCESS_TOKEN" "https://$GHES_HOST/api/v3/repos/$ORG_NAME/$repo_name/pulls?state=open" | jq '. | length')
    if [ "$pr_count" -gt 0 ]; then
        repos_with_prs+=("$repo_name")   
 fi
 done < <(curl -s -H "Authorization: token $ACCESS_TOKEN" "$API_ENDPOINT" | jq -c '.[]')
  # Print the list of repositories with open pull requests
 printf '%s\n' "${repos_with_prs[@]}"
