1.  Execute below line in git bash script

        $env:GITHUB_TOKEN = "<YOUR_TOKEN_HERE>"

2.  Run the script by executing

        ./fetch-list-of-repos

3.  <h3>Convert the Json file to csv file</h3>
    Once we get the data from above command after it is executed successfully then run below command to set $json variable

        $json = Get-Content -Raw -Path "C:\Users\<path>\org-repos-stats.json" | ConvertFrom-Json

4.  Execute below line of code to convert Json file to csv

        $csv = $json | Select-Object \* | Export-Csv -Path "C:\Users\<path>\<NameOfFile>.csv" -NoTypeInformation
