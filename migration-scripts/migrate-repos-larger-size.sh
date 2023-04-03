# creating a Repo on GHEC with the demoRepo1 name
curl -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $GHEC_USER_PAT" -H "X-GitHub-Api-Version: 2022-11-28" -d '{"visibility":"internal","name":"'"demoRepo1"'"}' $API_URL
$API_URL="https://api.github.com/orgs/$GHEC_ORG_NAME/repos"

#use normal clone instead of mirror clone to clone Repo from GHES
git clone <ghes-repo-url>

#change the path to the new cloned repo
cd repo-name

#change the remote url to the new GHEC url
#Replace the GHEC_USER_NAME, GHEC_USER_PAT, GHEC_ORG_NAME with the actual values
#DESTINATION_REPO_URL=https://<GHEC_USER_NAME>:<GHEC_USER_PAT>@github.com/<GHEC_ORG_NAME>/demoRepo1.git
#Replace DESTINATION_REPO_URL with the actual url as shown above
git remote set-url origin "DESTINATION_REPO_URL"

#push each branch of repo to GHEC, replace the branchname with the actual branch name and repeat the below command for each branch
max=$(git log --oneline|wc -l); for i in $(seq $max -500 1); do echo $i; git push origin branchname~$i:refs/heads/branchname; done; git push origin branchname