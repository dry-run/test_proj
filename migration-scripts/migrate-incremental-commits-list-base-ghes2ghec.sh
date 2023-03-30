#!/bin/bash
# Make sure this file is executable
# chmod a+x .github/script/migrate-repos-from-list.sh

help() {
    echo
    echo "Migrates multiple repos from Github Enterprise Server to Github Enterprise Cloud."
    echo "Repos list should be mentioned in 'repo-list' file"
    echo
    echo "Usage: ./${0##*/} <GHES_username> <GHES_password> <GHES_org_name> <GHES_host>" \
        "<GHEC_username> <GHEC_PersonalAccessToken> <GHEC_org_name> <GHEC_main_branch>"
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

    # Github Enterprise Server config
    export GHES_USER_NAME="$1"
    export GHES_USER_PASSWORD="$2"
    export GHES_ORG_NAME="$3"
    export GHES_HOST="$4"

    # Github Enterprise Cloud config
    export GHEC_USER_NAME="$5"
    export GHEC_USER_PAT="$6"
    export GHEC_ORG_NAME="$7"
}
FAILED_REPOS=()
migrate_multiple_repos() {
    printf '=%.0s' {1..100} >>"$MIGRATION_LOG_FILE_NAME"
    echo -e "\n" >>"$MIGRATION_LOG_FILE_NAME"
    while IFS= read -r REPO_NAME; do
        ./Incremental_commits.sh $REPO_NAME $GHES_USER_NAME $GHES_USER_PASSWORD $GHES_ORG_NAME $GHES_HOST $GHEC_USER_NAME $GHEC_USER_PAT $GHEC_ORG_NAME $GHEC_MAIN_BRANCH
        MIGRATE_STATUS=$?
        if [ $MIGRATE_STATUS -ne 0 ]; then
            FAILED_REPOS+=("$REPO_NAME")
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
