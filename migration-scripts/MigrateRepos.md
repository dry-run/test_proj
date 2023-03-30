> <h2>To fetch list of repositories in an Organization on GHES with Open Pull requests</h2>

Replace the GHES_HOST, ORG_NAME variables with the appropriate values for your GHES instance.

    GHES_HOST="$1"
    ORG_NAME="$2"

Execute below line in bash script

    ./get-open-pull-requests.sh demo.ghes demoorg1

> <h2> Migrate the repositories from GHES to GHEC</h2>

    # Github Enterprise Server details
    export GHES_USER_NAME="$1"
    export GHES_USER_PASSWORD="$2"
    export GHES_ORG_NAME="$3"
    export GHES_HOST="$4"

    # Github Enterprise Cloud details
    export GHEC_USER_NAME="$5"
    export GHEC_USER_PAT="$6"
    export GHEC_ORG_NAME="$7"
    export GHEC_MAIN_BRANCH="$8"

Replace the GHES_USER_NAME, GHES_USER_PASSWORD, GHES_ORG_NAME, GHES_HOST, GHEC_USER_NAME, GHEC_USER_PAT, GHEC_ORG_NAME, GHEC_MAIN_BRANCH variables with the appropriate values for your GHES,GHEC instance.

    ./migrate-repos-from-list-base-ghes2ghec.sh ghesuser1 pwd1 demoorg1 github.abc.ad ghecuser1 pwd2 demoorg2 main

> <h2>Incremental commits to Repository</h2>

One option to do incremental commits is to use the git bundles, we followed this article [here](https://stackoverflow.com/questions/66247810/how-can-i-incrementally-mirror-a-git-repository-via-bundle-files)

    # Github Enterprise Server config
    export GHES_USER_NAME="$1"
    export GHES_USER_PASSWORD="$2"
    export GHES_ORG_NAME="$3"
    export GHES_HOST="$4"

    # Github Enterprise Cloud config
    export GHEC_USER_NAME="$5"
    export GHEC_USER_PAT="$6"
    export GHEC_ORG_NAME="$7"

Replace the GHES_USER_NAME, GHES_USER_PASSWORD, GHES_ORG_NAME, GHES_HOST, GHEC_USER_NAME, GHEC_USER_PAT, GHEC_ORG_NAME variables with the appropriate values for your GHES,GHEC instance.

    ./migrate-incremental-commits-list-base-ghes2ghec.sh ghesuser1 pwd1 demoorg1 github.abc.ad ghecuser1 pwd2 demoorg2
