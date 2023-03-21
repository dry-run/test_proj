# get job configurations from jenkins.fleet.ad and grep for github.fleet.ad in them

JENKINS_URL="abc.xyz.ad:8080"
while IFS= read -r JOB_NAME; do
    JOB_NAME_FILE=${JOB_NAME////.}
    JOB_NAME=${JOB_NAME/////job/}
    JOB_NAME=${JOB_NAME// /%20}

    echo "JOB_NAME $JOB_NAME"
    JOB_URL="https://$JENKINS_URL/job/$JOB_NAME/config.xml"
    echo "JOB_URL $JOB_URL"

    curl -k --user "$JENKINS_USER":"$JENKINS_API_TOKEN" -X GET "$JOB_URL" -o "$JOB_NAME_FILE".xml
    lines_with_ghes_link=$(cat "$JOB_NAME_FILE".xml | grep "github.fleet.ad")

    echo "$JOB_URL|$lines_with_ghes_link" >>jenkins_dependencies_report.txt
    echo -e "" >>jenkins_dependencies_report.txt
done <./jenkins_jobs_list.txt
