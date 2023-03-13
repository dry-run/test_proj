# Git clone --mirror
# Cd .. (repo name)
# git bundle create bundle.gitb
# Git remote show origin
# Git remote remove origin
# Git remote add origin https://username:pat@org/repo
# Git remote show origin
# Git push --all
#!/bin/bash
# Make sure this file is executable
# chmod a+x .github/script/migrate-git-repos-base-ghes2ghec.sh

help() {
    echo
    echo "Migrates a repo from Github Enterprise Server to Github Enterprise Cloud  Incremental Commits"
    echo
    echo "Usage: ./${0##*/} <GHES_Repo_to_migrate> <GHES_username> <GHES_password> <GHES_org_name> <GHES_host>" \
        "<GHEC_username> <GHEC_PersonalAccessToken> <GHEC_org_name> <GHEC_main_branch>"
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "" ]; then
    help
    exit 0
fi

START_TIME=$(date +%s)

# Echo commands as they're run, and expand variables
set -o xtrace

# Read all migration configuration
#unset $(grep -v '^#' ./migration-config | sed -E 's/(.*)=.*/\1/' | xargs)
#export $(grep -v '^#' ./migration-config | xargs)

configure_source_and_destination() {

    # Github Enterprise Server config
    export REPO_NAME="$1"
    export GHES_USER_NAME="$2"
    export GHES_USER_PASSWORD="$3"
    export GHES_ORG_NAME="$4"
    export GHES_HOST="$5"

    # Github Enterprise Cloud config
    export GHEC_USER_NAME="$6"
    export GHEC_USER_PAT="$7"
    export GHEC_ORG_NAME="$8"

    echo "Source: https://$GHES_USER_NAME:$GHES_USER_PASSWORD@$GHES_HOST/$GHES_ORG_NAME/$REPO_NAME.git"
    echo "Destination: https://$GHEC_USER_NAME:$GHEC_USER_PAT@github.com/$GHEC_ORG_NAME/$REPO_NAME.git"
}

clone_from_ghes() {
    # Clone repo from Github Enterprise Server
    #  SOURCE_REPO_URL=https://$GHES_USER_NAME:$GHES_USER_PASSWORD@$GHES_HOST/$GHES_ORG_NAME/$REPO_NAME.git

    # Use http for EF instead of https
    SOURCE_REPO_URL=http://$GHES_USER_NAME:$GHES_USER_PASSWORD@$GHES_HOST/$GHES_ORG_NAME/$REPO_NAME.git
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
    git bundle create bundle.gitb --all
    git remote remove origin
}

push_to_ghec() {

    DESTINATION_REPO_URL=https://$GHEC_USER_NAME:$GHEC_USER_PAT@github.com/$GHEC_ORG_NAME/$REPO_NAME.git

    git remote add origin "$DESTINATION_REPO_URL"
    git push --all
    GHEC_COMMITS_COUNT=$(curl -s -H "Authorization: token $GHEC_USER_PAT" -X HEAD -I "https://api.github.com/repos/$GHEC_ORG_NAME/$REPO_NAME/commits?per_page=1" | grep -i "link:" | awk '{print $4}' | sed 's/.*page=\([0-9]*\)>;.*/\1/')
    GHES_COMMITS_COUNT=$(curl -s -H "Authorization: token $GHES_USER_PASSWORD" -X HEAD -I "http://github.fleet.ad/api/v3/repos/$GHES_ORG_NAME/$REPO_NAME/commits?per_page=1" | grep -i 'link:' | awk '{print $4}' | sed 's/.*page=\([0-9]*\)>;.*/\1/')
    GHEC_BRANCH_COUNT=$(curl -s -H "Authorization: token $GHEC_USER_PAT" "https://api.github.com/repos/$GHEC_ORG_NAME/$REPO_NAME/branches" | jq '. | length')
    GHES_BRANCH_COUNT=$(curl -s -H "Authorization: token $GHES_USER_PASSWORD" "http://github.fleet.ad/api/v3/repos/$GHES_ORG_NAME/$REPO_NAME/branches" | jq '. | length')

    if [ $GHEC_COMMITS_COUNT -ne 0 ]; then
        if [ $GHEC_COMMITS_COUNT -ne $GHES_COMMITS_COUNT ]; then
            echo "ERROR: Commits not matched $REPO_NAME"
            exit 1
        fi
        if [ $GHEC_BRANCH_COUNT -ne $GHES_BRANCH_COUNT ]; then
            echo "ERROR: Branches count not matched $REPO_NAME"
            exit 1
        fi
    else
        echo "ERROR: Failed to push repo $DESTINATION_REPO_URL"
        exit 1
    fi

    # push_status=$?
    # if [ $push_status -ne 0 ]; then
    # echo "ERROR2: Failed to push repo $DESTINATION_REPO_URL"
    # exit 1
    # fi
    cd ..
}

configure_source_and_destination $*
rm -rf "$REPO_NAME".git
clone_from_ghes
push_to_ghec

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
