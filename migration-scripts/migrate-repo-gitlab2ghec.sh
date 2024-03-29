#!/bin/bash
# Make sure this file is executable
# chmod a+x ./migrate-repo-gitlab2ghec.sh

help() {
    echo
    echo "Migrates a repo from a GitLab Organization to a Github Enterprise Cloud organization"
    echo
    echo "Usage: ./${0##*/} <GHEC_USER_NAME> <GHEC_USER_PAT> <GHEC_SOURCE_ORG_NAME> <GHEC_DEST_ORG_NAME> <GHEC_main_branch>"
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "" ]; then
    help
    exit 0
fi

START_TIME=$(date +%s)

# Echo commands as they're run, and expand variables
set -o xtrace

# Read all migration configuration
chmod a+x ./migration-scripts/migration-config
unset $(grep -v '^#' ./migration-scripts/migration-config | sed -E 's/(.*)=.*/\1/' | xargs)
export $(grep -v '^#' ./migration-scripts/migration-config | xargs)

configure_source_and_destination() {

    # GL to GH Environment Variables
    export GL_REPO_NAME="$1"
    export GHEC_USER_NAME="$2"
    export GHEC_USER_PAT="$3"
    export GL_SOURCE_ORG_NAME="$4"
    export GL_SOURCE_USER_NAME="$5"
    export GL_PAT="$6"
    export GHEC_DEST_ORG_NAME="$7"
    export GHEC_MAIN_BRANCH="$8"

    # Print the URLs of the source and destination repositories to the console for verification and record-keeping.
    # The source URL is constructed using the GitLab username, organization name, and repository name.
    # The destination URL is constructed using the GitHub username, organization name, and repository name.
    echo "Source: https://$GL_SOURCE_USER_NAME@gitlab.com/$GL_SOURCE_ORG_NAME/$GL_REPO_NAME.git"
    echo "Destination: https://$GHEC_USER_NAME@github.com/$GHEC_DEST_ORG_NAME/$GL_REPO_NAME.git"
}

clone_from_gitlab() {

    # Use http for EF instead of https
    SOURCE_REPO_URL="https://gitlab.gh-services-partners.com/$GL_SOURCE_ORG_NAME/$GL_REPO_NAME.git"
    git clone --mirror "$SOURCE_REPO_URL"
    clone_status=$?
    if [ $clone_status -ne 0 ]; then
        echo "ERROR: Failed to clone repo $SOURCE_REPO_URL"
        exit 1
    fi
    cd "$GL_REPO_NAME".git || {
        echo "ERROR: Unable to cd into the repo"
        exit 1
    }
}

delete_existing_ghec_repo_targetOrg() {
    # Delete existing repo in Github Enterprise Cloud
    if [ "$GHEC_DELETE_REPO_BEFORE_CREATE" == "true" ]; then
        gh repo delete "$GHEC_DEST_ORG_NAME"/"$GL_REPO_NAME" --yes || true
    fi
}

push_to_dest_ghec() {

    #delete_existing_ghec_repo_targetOrg

    DESTINATION_REPO_URL="https://$GHEC_USER_NAME:$GHEC_USER_PAT@github.com/$GHEC_DEST_ORG_NAME/$GL_REPO_NAME.git"

    #create repo in GHEC
    #gh repo create "$GHEC_DEST_ORG_NAME"/"$GL_REPO_NAME" --internal

    # Use Curl if you don't have gh cli installed
    API_URL="https://api.github.com/orgs/$GHEC_DEST_ORG_NAME/repos"
    echo "API_URL: $API_URL"

    curl -L -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $GHEC_USER_PAT" -H "X-GitHub-Api-Version: 2022-11-28" $API_URL -d '{"name":"'"$GL_REPO_NAME"'"}'

    # curl -H "Authorization: Bearer $GHEC_USER_PAT" $API_URL -d '{"name":"'"$GL_REPO_NAME"'"}'

    create_status=$?
    if [ $create_status -ne 0 ]; then
        echo "ERROR: Failed to create repo $DESTINATION_REPO_URL"
        exit 1
    fi
    git remote set-url origin "$DESTINATION_REPO_URL"
    git push
    GHEC_DEST_COMMITS_COUNT=$(curl -s -H "Authorization: Bearer $GHEC_USER_PAT" -X HEAD -I "https://api.github.com/repos/$GHEC_DEST_ORG_NAME/$GL_REPO_NAME/commits?per_page=1" | grep -i "link:" | awk '{print $4}' | sed 's/.*page=\([0-9]*\)>;.*/\1/')
    GitLab_SOURCE_COMMITS_COUNT=$(curl -s --header "PRIVATE-TOKEN: YOUR_PRIVATE_TOKEN" "https://your-gitlab-url/api/v4/projects/PROJECT_ID/repository/commits?per_page=1" | jq '. | length')
    GHEC_DEST_BRANCH_COUNT=$(curl -s -H "Authorization: Bearer $GHEC_USER_PAT" "https://api.github.com/repos/$GHEC_DEST_ORG_NAME/$GL_REPO_NAME/branches" | jq '. | length')
    GitLab_SOURCE_BRANCH_COUNT=$(curl -s --header "Private-Token: Your-Private-Token" "https://your-gitlab-url/api/v4/projects/:id/repository/branches" | jq 'length')

    if [ $GHEC_DEST_COMMITS_COUNT -ne 0 ]; then
        if [ $GHEC_DEST_COMMITS_COUNT -ne $GHEC_SOURCE_COMMITS_COUNT ]; then
            echo "ERROR: Commits not matched $GL_REPO_NAME"
            exit 1
        fi
        if [ $GHEC_DEST_BRANCH_COUNT -ne $GHEC_SOURCE_BRANCH_COUNT ]; then
            echo "ERROR: Branches count not matched $GL_REPO_NAME"
            exit 1
        fi
    else
        echo "ERROR: Failed to push repo $DESTINATION_REPO_URL"
        exit 1
    fi

    cd ..
}

# Main Flow

# Call the configure_source_and_destination function and pass all the arguments given to the script to this function. 
# $* in bash is a special variable that holds all the arguments as a list.
configure_source_and_destination $*

# Remove the local directory of the repository if it exists from a previous run. 
# This is to ensure that the script starts with a clean state.
rm -rf "$GL_REPO_NAME".git

# Call the clone_from_source_ghec function to clone the repository from the source GitLab instance. 
# It clones a bare repository (including all branches and tags) and then navigates into the cloned repository directory.
clone_from_source_ghec

# Call the push_to_dest_ghec function to push the cloned repository to the destination GitHub Enterprise Cloud instance. 
# It first creates a new repository on the destination GitHub, then changes the origin of the local repository to point to this new GitHub repository, 
# and finally pushes all the cloned data to the new repository.
push_to_dest_ghec

# Calculate the size of the repository and store it in the REPO_SIZE variable. 
# du -sh calculates the size of the current directory and awk '{print $1}' extracts the size value.
REPO_SIZE=$(du -sh | awk '{print $1}')

# Remove the local repository directory after the migration is done.
rm -rf "$GL_REPO_NAME".git

# Capture the end time of the script.
END_TIME=$(date +%s)

# Check if a log file name is provided. If not, generate a log file name based on the current timestamp.
if [[ -z $MIGRATION_LOG_FILE_NAME ]]; then
    TIMESTAMP=$(date)
    TIMESTAMP=${TIMESTAMP// /_}
    TIMESTAMP=${TIMESTAMP//:/_}
    export MIGRATION_LOG_FILE_NAME="$TIMESTAMP.log"
fi

# Create a new log file with the name stored in MIGRATION_LOG_FILE_NAME.
touch "$MIGRATION_LOG_FILE_NAME"

# Log the name of the repository, its size, and the duration of the migration process to both the console and the log file. 
# The tee -a command is used to append the output to the log file.
echo "$GL_REPO_NAME Size:$REPO_SIZE Duration:$((END_TIME - START_TIME))" | tee -a "$MIGRATION_LOG_FILE_NAME"

