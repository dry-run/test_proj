# Download job configurations from jenkins server and grep for GHES_URL in them

JENKINS_URL="$1"
JENKINS_USER="$2"
JENKINS_API_TOKEN="$3"
GHES_URL="$4"

while IFS= read -r JOB_NAME; do
    JOB_NAME_FILE=${JOB_NAME////.}
    JOB_NAME=${JOB_NAME/////job/}
    JOB_NAME=${JOB_NAME// /%20}

    echo "JOB_NAME $JOB_NAME"

    JOB_URL="http://$JENKINS_URL/job/$JOB_NAME/config.xml"

    echo "JOB_URL $JOB_URL"

    curl --user "$JENKINS_USER":"$JENKINS_API_TOKEN" -X GET "$JOB_URL" -o "$JOB_NAME_FILE".xml

    lines_with_ghes_link=$(cat "$JOB_NAME_FILE".xml | grep "$GHES_URL")

    echo "$JOB_URL|$lines_with_ghes_link" >>jenkins_dependencies_report.txt
    echo -e "" >>jenkins_dependencies_report.txt
done <./jenkins_jobs_list.txt
