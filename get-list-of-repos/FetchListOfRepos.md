<h2>Script to Fetch list of Repositories</h2>
1.  Update this variable in script "$ghesHost" with GHES name.

        Example: $ghesHost = "github.abc.ad"

2.  Execute below line in powershell script

        $env:GITHUB_TOKEN = "<YOUR_GHES_TOKEN_HERE>"

3.  Run the script by executing

        ./fetch-list-of-repos

4.  <h3>Convert the Json file to csv file</h3>
    Once we get the data from above command after it is executed successfully then run below command to set $json variable

        $json = Get-Content -Raw -Path "C:\Users\<path>\org-repos-stats.json" | ConvertFrom-Json

5.  Execute below line of code to convert Json file to csv

        $csv = $json | Select-Object \* | Export-Csv -Path "C:\Users\<path>\<NameOfFile>.csv" -NoTypeInformation

<h2>Script to Fetch list of Repositories with Open Pull Request(s)</h2>

1.  Execute below line in bash script

        export GHES_TOKEN="<YOUR_GHES_TOKEN_HERE>"

2.  Run the script by executing

        ./get-repos-list-of-open-PR.sh
