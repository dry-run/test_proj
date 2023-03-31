<h2>Script to Fetch list of Repositories</h2>

1.  Update this variable in script "$ghesHost" with GHES name.

        Example: $ghesHost = "github.abc.ad"

2.  Execute below line in powershell script

        $env:GITHUB_TOKEN = "<YOUR_GHES_TOKEN_HERE>"

3.  Run the script by executing

        ./fetch-list-of-repos

4.  Convert the Json file to csv file

    Once we get the data from above command after it is executed successfully then run below command to set $json variable

        $json = Get-Content -Raw -Path "C:\Users\<path>\org-repos-stats.json" | ConvertFrom-Json

5.  Execute below line of code to convert Json file to csv

        $csv = $json | Select-Object \* | Export-Csv -Path "C:\Users\<path>\<NameOfFile>.csv" -NoTypeInformation

<h2>Script to Fetch list of Repositories with Open Pull Request(s)</h2>

1.  Replace the below variables with the appropriate values for your GHES instance

        GHES_HOST="$1"
        ORG_NAME="$2"
        ACCESS_TOKEN="$3"

2.  Run the script by executing

        ./get-open-pull-requests.sh github.abc.ad demo-org1 123

<h2>Script to fetch list of Repositories and branches with latest commit date</h2>

1.  Update this variable in script "$timestamp" for fetching commits greater then this date.

        Example: $timestamp = "2023-03-28T23:28:01Z"

2.  Execute below line in powershell script

        $env:GITHUB_TOKEN = "<YOUR_GHES_TOKEN_HERE>"
        $env:GHES_HOSTNAME = "<YOUR_GHES_HOSTNAME_HERE>"

3.  Add the list of repositories to the "repo-list" file.

        vi repo_list

        Example: demo-org1/demo-repo1
                 demo-org1/demo-repo2

4.  Run the script by executing

        ./fetch-list-of-repos-branches-with-latest-commit-date

5.  It will show the output as shown below in "latest_commits.csv" file.
    ![Alt text](/latestcommitsdata.png "List commits of branches")
