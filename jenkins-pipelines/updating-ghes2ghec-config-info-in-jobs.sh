# get job configurations from jenkins.fleet.ad and grep for github.fleet.ad in them

JENKINS_URL="$1"
OLD_ORG="$2"
NEW_ORG="$3"
CRED_ID="$4"
GHES_URL="github.fleet.ad"
GHEC_URL="github.com"
while IFS= read -r JOB_NAME; do
    JOB_NAME_FILE=${JOB_NAME////.}
    JOB_NAME=${JOB_NAME/////job/}
    JOB_NAME=${JOB_NAME// /%20}
    echo "JOB_NAME $JOB_NAME"
    JOB_URL="https://$JENKINS_URL/job/$JOB_NAME/config.xml"
    echo "JOB_URL $JOB_URL"
    curl -k --user "$JENKINS_USER":"$JENKINS_API_TOKEN" -X GET "$JOB_URL" -o "$JOB_NAME_FILE".xml
    lines_with_ghes_link=$(cat "$JOB_NAME_FILE".xml | grep "github.fleet.ad")

    # Comment this block if you don't want to update the config
    sed -i "s/$GHES_URL\/$OLD_ORG/$GHEC_URL\/$NEW_ORG/g" "$JOB_NAME_FILE".xml
    sed -i "s/$GHES_URL:$OLD_ORG/$GHEC_URL:$NEW_ORG/g" "$JOB_NAME_FILE".xml
    sed -i "s/http:\/\/$GHEC_URL/https:\/\/$GHEC_URL/g" "$JOB_NAME_FILE".xml
    sed -i "s/git@$GHEC_URL:/https:\/\/$GHEC_URL\//g" "$JOB_NAME_FILE".xml
    sed -i "s/<credentialsId>.*<\/credentialsId>/<credentialsId>$CRED_ID<\/credentialsId>/g" "$JOB_NAME_FILE".xml
    curl -k --user "$JENKINS_USER":"$JENKINS_API_TOKEN" -X POST "$JOB_URL" -H 'Content-Type: application/xml' --data-binary "@$JOB_NAME_FILE.xml"
    # ----

    echo "$JOB_URL|$lines_with_ghes_link" >>jenkins_dependencies_report.txt
    echo -e "" >>jenkins_dependencies_report.txt
done <./jenkins_jobs_list.txt
