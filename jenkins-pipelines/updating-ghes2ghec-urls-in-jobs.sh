# get job configurations from jenkins.fleet.ad and grep for github.fleet.ad in them

JENKINS_URL="jenkins.fleet.ad"
GHES_URL="github.fleet.ad"
GHEC_URL="github.com"
while IFS= read -r JOB_NAME; do
  JOB_NAME=${JOB_NAME/////job/}
  JOB_NAME=${JOB_NAME// /%20}
  echo "JOB_NAME $JOB_NAME"
  JOB_URL="http://$JENKINS_URL/job/$JOB_NAME/config.xml"
  echo "JOB_URL $JOB_URL"
  curl --user $JENKINS_USER:$JENKINS_API_TOKEN -X GET $JOB_URL -o jobconfig.xml
  lines_with_ghes_link=$(cat jobconfig.xml | grep "github.fleet.ad")
  sed -i "s/$GHES_URL/$GHEC_URL/g" jobconfig.xml
  sed -i "s/http:\/\/$GHEC_URL/https:\/\/$GHEC_URL/g" jobconfig.xml
  curl --user $JENKINS_USER:$JENKINS_API_TOKEN -X POST $JOB_URL -H 'Content-Type: application/xml' --data-binary "@jobconfig.xml"
  echo "$JOB_URL|$lines_with_ghes_link" >>jenkins_dependencies_report.txt
  echo -e "" >>jenkins_dependencies_report.txt
done <./jenkins_jobs_list.txt
