Used below article for ghe-importer

    https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-organizations-with-github-enterprise-importer/migrating-organizations-from-githubcom-to-github-enterprise-cloud#step-1-install-the-gei-extension-of-the-github-cli

Steps from above article :

Step 1: Install the GEI extension of the GitHub CLI

    gh extension install github/gh-gei

Step 2: Update the GEI extension of the GitHub CLI

    gh extension upgrade github/gh-gei

Step 3: Set environment variables

    If you're using Terminal, use the export command.
    export GH_PAT="TOKEN"
    export GH_SOURCE_PAT="TOKEN"

    If you're using PowerShell, use the $env command.
    $env:GH_PAT="TOKEN"
    $env:GH_SOURCE_PAT="TOKEN"

Step 4: Migrate your organization

    To migrate an organization, use the gh gei migrate-org command

    gh gei migrate-org --github-source-org SOURCE --github-target-org DESTINATION --github-target-enterprise ENTERPRISE --wait
