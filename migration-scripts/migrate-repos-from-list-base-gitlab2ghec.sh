#!/bin/bash
# Make sure this file is executable
# chmod a+x .github/script/migrate-repos-from-list.sh

help() {
  echo
  echo "Migrates multiple repos from Github Enterprise Server to Github Enterprise Cloud."
  echo "Repos list should be mentioned in 'repo-list' file"
  echo
  echo "Usage: ./${0##*/} <GL_USERNAME> <GHEC_USER_PAT> <GL_SOURCE_ORG_NAME> <GHEC_DEST_ORG_NAME> <GHEC_main_branch>"
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "" ]; then
  help
  exit 0
fi

# Set MIGRATION_LOG_FILE name
TIMESTAMP=$(date)
TIMESTAMP=${TIMESTAMP// /_}
TIMESTAMP=${TIMESTAMP//:/_}
export MIGRATION_LOG_FILE_NAME="$TIMESTAMP.log"

START_TIME=$(date +%s)

configure_source_and_destination() {

  # Github Enterprise Cloud config
  export GL_USERNAME="$1"
  export GL_USER_PAT="$2"
  export GL_SOURCE_ORG_NAME="$3"
  export GHEC_DEST_ORG_NAME="$4"
  export GHEC_MAIN_BRANCH="$5"
}
FAILED_REPOS=()
migrate_multiple_repos() {
  printf '=%.0s' {1..100} >>"$MIGRATION_LOG_FILE_NAME"
  echo -e "\n" >>"$MIGRATION_LOG_FILE_NAME"
  while IFS= read -r GL_REPO_NAME; do
    echo "Migrating repository: $GL_REPO_NAME"
    # You need to modify this line to fetch the repository details from GitLab
    # For example, you can use GitLab API to get the details of each repository
    # Replace <YOUR_GITLAB_API_ENDPOINT> and <YOUR_GITLAB_ACCESS_TOKEN> with appropriate values
    GITLAB_REPO_DETAILS=$(curl -s --header "Authorization: Bearer <YOUR_GITLAB_ACCESS_TOKEN>" "https://<YOUR_GITLAB_API_ENDPOINT>/projects?search=$GL_REPO_NAME")
    # Extract the GitLab repository URL from the response
    SOURCE_REPO_URL=$(echo "$GITLAB_REPO_DETAILS" | jq -r '.[0].ssh_url_to_repo')
    # Migrate the repository using the migration script
    ./migration-scripts/migrate-repo-gitlab2ghec.sh "$GL_REPO_NAME" "$GL_USERNAME" "$GHEC_USER_PAT" "$GL_SOURCE_ORG_NAME" "$GHEC_DEST_ORG_NAME" "$GHEC_MAIN_BRANCH" "$SOURCE_REPO_URL"
    MIGRATE_STATUS=$?
    if [ $MIGRATE_STATUS -ne 0 ]; then
      echo "Failed to migrate repository: $GL_REPO_NAME"
      FAILED_REPOS+=("$GL_REPO_NAME")
    fi
  done <./repo-list
}

configure_source_and_destination $*
migrate_multiple_repos

END_TIME=$(date +%s)
echo "Migration duration:$((END_TIME - START_TIME))" >>"$MIGRATION_LOG_FILE_NAME"
echo "Failed to migrate repos:" >>"$MIGRATION_LOG_FILE_NAME"
printf '%s\n' "${FAILED_REPOS[@]}" >>"$MIGRATION_LOG_FILE_NAME"
printf "\nMake sure:\n1. The repo exists. \n2. There are no open pull requests in repos\n3. The repo is not archived or locked." >>"$MIGRATION_LOG_FILE_NAME"
export MIGRATION_LOG_FILE_NAME=
