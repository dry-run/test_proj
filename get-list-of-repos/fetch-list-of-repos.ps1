# Gets metadata about all repos in all orgs in a Github Enterprise Server

$allOrgs = @()
# Get all organizations
$userId = 0
#keep getting repos until the count comes back zero
$githubToken = $env:GITHUB_TOKEN
$ghesHost = "github.fleet.ad"
$tokenheader = "token $githubToken"
$headers = @{ 'Authorization' = $tokenheader; 'Accept' = 'application/vnd.github+json' }
do {
    Write-Output "Processing since user $userId for users/orgs"
    $url = "http://$ghesHost/api/v3/users?since=$userId&per_page=100"
    $orgs = curl -Headers $headers $url | ConvertFrom-Json
    $allOrgs += $orgs
    $orgCount = $orgs.count
    $userId = $orgs[$orgsCount - 1].id
    Write-Output $userId
} while ($orgCount -gt 0)

$organizations = $allOrgs
$orgCount = $organizations.count
Write-Output "Processing $orgCount organizations"

$orgRepoStats = @()
$orgRepos = @()
# Loop through each object in the array
$orgIndex = 0
foreach ($org in $organizations) {

    $orgType = $org.type
    $orgName = $org.login
    $orgIndex += 1
    if ($orgName) {
        Write-Output "Processing org $orgIndex/$orgCount"
        Write-Output "Processing repos for organization/user: $orgName"
        $page = 0
        #keep getting repos until the count comes back zero
        do {
            $page += 1
            if ($orgType -eq 'Organization') {
                $url = "http://$ghesHost/api/v3/orgs/$orgName/repos?page=$page&per_page=100"
            }
            else {
                $url = "http://$ghesHost/api/v3/users/$orgName/repos?page=$page&per_page=100"
            }
            Write-Output "Processing url $url"
            $repos = curl -Headers $headers $url | ConvertFrom-Json
            $orgRepos += $repos
            $repoCount = $repos.Count
        } while ($repoCount -gt 0)
    }
}

$orgReposCount = $orgRepos.count
Write-Output "Processing $orgReposCount repos"
for ($index = 0; $index -lt $orgReposCount; $index++) {
    $repo = $orgRepos[$index]
    $repoId = $orgRepos[$index].full_name
    Write-Output "Processing repo $index / $orgReposCount"
    $url = "http://$ghesHost/api/v3/repos/$repoId/commits"
    Write-Output "Processing $url"
    $repoCommits = curl -Headers $headers $url | ConvertFrom-Json
    $orgRepoStats += @{
        type         = $repo.owner.type;
        login        = $repo.owner.login;
        orgRepo      = $repoId;
        name         = $repo.name;
        repoId       = $repoId;
        commit_date  = $repoCommits[0].commit.author.date;
        size         = $repo.size;
        commit_count = $repoCommits.count
    }
}

$jsonOrgRepoStats = $orgRepoStats | ConvertTo-Json
$jsonOrgRepoStats | Out-File "org-repos-stats.json" -Force

# $orgRepoStats | Export-CSV -Path "org-repos-stats.csv" -Force
