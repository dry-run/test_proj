org=$1
while IFS= read -r repo; do
    response=$(curl -s -H "Authorization: token $GHES_TOKEN" -H "Accept: application/vnd.github.v3+json" "http://github.fleet.ad/api/v3/repos/$org/$repo/pulls?state=open")
    pr_exist=$(echo "$response" | grep "$org\/$repo\/pulls")
    if [ -n "$pr_exist" ]; then
        echo "$org/$repo"
    fi
done <./repo-list
