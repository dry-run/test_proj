$timestamp = "2023-03-28T23:28:01Z"

$GITHUB_TOKEN = $env:GITHUB_TOKEN
$GHES_HOSTNAME = $env:GHES_HOSTNAME
$TOKEN_HEADER = "token $GITHUB_TOKEN"
$HEADERS = @{ 'Authorization' = $TOKEN_HEADER; 'Accept' = 'application/vnd.github+json' }

$repo_branch_latest_commits = @()

Get-Content "./repo_list.txt" | ForEach-Object {
    $repoId = $_

    $url = "http://$GHES_HOSTNAME/api/v3/repos/$repoId/branches"
    $response = Invoke-RestMethod -Method Get $url -Headers $HEADERS 
    if ($response) {
        $branches = @()
        foreach ($branch in $response) {
            $branchName = $branch.name
            $commitUrl = $branch.commit.url
            $commitResponse = Invoke-RestMethod -Method Get -Uri $commitUrl -Headers $HEADERS
            $latestCommitDate = $commitResponse.commit.author.date
            $branches += [PSCustomObject]@{
                BranchName = $branchName
                LatestCommitDate = $latestCommitDate
            }
        }
        Write-Output "Remote branches and their latest commit dates for $repoId"
        $branches | Format-Table -AutoSize
    }
    else {
        Write-Output "Failed to get information for $repoId"
    }

    $newCommits = 0

    foreach ($branch in $branches) {
        $commit_date = $branch.LatestCommitDate
        if ($commit_date -gt $timestamp){
            Write-Output "New commits made on $repoId/$($branch.BranchName) - $commit_date"
            $newCommits += 1
            $repo_branch_latest_commits += [PSCustomObject]@{
                Repo = $repoId
                BranchName = $branch.BranchName
                LatestCommitDate = $branch.LatestCommitDate
            }
        }
    }
    if ($newCommits -eq 0){
        Write-Output "No new commits on any branch after $timestamp for $repoId"
    }
}

$repo_branch_latest_commits | Format-Table -AutoSize
$repo_branch_latest_commits | Export-Csv -Path "latest_commits.csv" -Delimiter "|" -NoTypeInformation
