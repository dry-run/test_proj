#!/bin/bash
# Make sure this file is executable
# chmod a+x ./migrate-git-repos-base-ghec2ghec.sh

help() {
    echo
    echo "Migrates a repo from Github Enterprise Cloud Org1 to Github Enterprise Cloud Org2"
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

    # Github Enterprise Cloud config
    export REPO_NAME="$1"
    export GHEC_USER_NAME="$2"
    export GHEC_USER_PAT="$3"
    export GHEC_SOURCE_ORG_NAME="$4"
    export GHEC_DEST_ORG_NAME="$5"
    export GHEC_MAIN_BRANCH="$6"
    echo "Source: https://$GHEC_USER_NAME@github.com/$GHEC_SOURCE_ORG_NAME/$REPO_NAME.git"
    echo "Destination: https://$GHEC_USER_NAME@github.com/$GHEC_DEST_ORG_NAME/$REPO_NAME.git"
}

clone_from_source_ghec() {

    # Use http for EF instead of https
    SOURCE_REPO_URL="https://github.com/$GHEC_SOURCE_ORG_NAME/$REPO_NAME.git"
    git clone --mirror "$SOURCE_REPO_URL"
    clone_status=$?
    if [ $clone_status -ne 0 ]; then
        echo "ERROR: Failed to clone repo $SOURCE_REPO_URL"
        exit 1
    fi
    cd "$REPO_NAME".git || {
        echo "ERROR: Unable to cd into the repo"
        exit 1
    }
}

delete_existing_ghec_repo_targetOrg() {
    # Delete existing repo in Github Enterprise Cloud
    if [ "$GHEC_DELETE_REPO_BEFORE_CREATE" == "true" ]; then
        gh repo delete "$GHEC_DEST_ORG_NAME"/"$REPO_NAME" --yes || true
    fi
}

push_to_dest_ghec() {

    delete_existing_ghec_repo_targetOrg

    DESTINATION_REPO_URL=https://$GHEC_USER_NAME:$GHEC_USER_PAT@github.com/$GHEC_DEST_ORG_NAME/$REPO_NAME.git
    #  gh repo create "$GHEC_DEST_ORG_NAME"/"$REPO_NAME" --internal

    # Use Curl if you don't have gh cli installed
    API_URL="https://api.github.com/$GHEC_DEST_ORG_NAME/$REPO_NAME"
    curl -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $GHEC_USER_PAT" -H "X-GitHub-Api-Version: 2022-11-28" -d '{"visibility":"internal","name":"'"$REPO_NAME"'"}' $API_URL

    create_status=$?
    if [ $create_status -ne 0 ]; then
        echo "ERROR: Failed to create repo $DESTINATION_REPO_URL"
        exit 1
    fi
    git remote set-url origin "$DESTINATION_REPO_URL"
    git push
    GHEC_DEST_COMMITS_COUNT=$(curl -s -H "Authorization: token $GHEC_USER_PAT" -X HEAD -I "https://api.github.com/repos/$GHEC_DEST_ORG_NAME/$REPO_NAME/commits?per_page=1" | grep -i "link:" | awk '{print $4}' | sed 's/.*page=\([0-9]*\)>;.*/\1/')
    GHEC_SOURCE_COMMITS_COUNT=$(curl -s -H "Authorization: token $GHEC_USER_PAT" -X HEAD -I "https://api.github.com/repos/$GHEC_SOURCE_ORG_NAME/$REPO_NAME/commits?per_page=1" | grep -i 'link:' | awk '{print $4}' | sed 's/.*page=\([0-9]*\)>;.*/\1/')
    GHEC_DEST_BRANCH_COUNT=$(curl -s -H "Authorization: token $GHEC_USER_PAT" "https://api.github.com/repos/$GHEC_DEST_ORG_NAME/$REPO_NAME/branches" | jq '. | length')
    GHEC_SOURCE_BRANCH_COUNT=$(curl -s -H "Authorization: token $GHEC_USER_PAT" "https://api.github.com/repos/$GHEC_SOURCE_ORG_NAME/$REPO_NAME/branches" | jq '. | length')

    if [ $GHEC_DEST_COMMITS_COUNT -ne 0 ]; then
        if [ $GHEC_DEST_COMMITS_COUNT -ne $GHEC_SOURCE_COMMITS_COUNT ]; then
            echo "ERROR: Commits not matched $REPO_NAME"
            exit 1
        fi
        if [ $GHEC_DEST_BRANCH_COUNT -ne $GHEC_SOURCE_BRANCH_COUNT ]; then
            echo "ERROR: Branches count not matched $REPO_NAME"
            exit 1
        fi
    else
        echo "ERROR: Failed to push repo $DESTINATION_REPO_URL"
        exit 1
    fi

    cd ..
}

configure_source_and_destination $*
rm -rf "$REPO_NAME".git
clone_from_source_ghec
push_to_dest_ghec

REPO_SIZE=$(du -sh | awk '{print $1}')
rm -rf "$REPO_NAME".git

END_TIME=$(date +%s)
if [[ -z $MIGRATION_LOG_FILE_NAME ]]; then
    TIMESTAMP=$(date)
    TIMESTAMP=${TIMESTAMP// /_}
    TIMESTAMP=${TIMESTAMP//:/_}
    export MIGRATION_LOG_FILE_NAME="$TIMESTAMP.log"
fi
touch "$MIGRATION_LOG_FILE_NAME"
echo "$REPO_NAME Size:$REPO_SIZE Duration:$((END_TIME - START_TIME))" | tee -a "$MIGRATION_LOG_FILE_NAME"
