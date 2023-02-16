def jenkinsUrl = "jenkins.fleet.ad"
def ghesUrl = "github.fleet.ad"
def ghecUrl = "github.com"
def jenkinsUser = "your_jenkins_username"
def jenkinsApiToken = "your_jenkins_api_token"
// Read list of jobs from file
def jobNames = new File('jenkins_jobs_list.txt').text.readLines()
// Loop through each job
for (jobName in jobNames) {
   jobName = jobName.replace("/job/", "").replaceAll(" ", "%20")
   def jobUrl = "http://${jenkinsUrl}/job/${jobName}/config.xml"
   echo "JOB_URL ${jobUrl}"
   // Get job configuration
   def jobConfig = sh(returnStdout: true, script: "curl --user ${jenkinsUser}:${jenkinsApiToken} -X GET ${jobUrl}")
   // Replace ghesUrl with ghecUrl
   jobConfig = jobConfig.replaceAll(ghesUrl, ghecUrl)
   jobConfig = jobConfig.replaceAll("http://${ghecUrl}", "https://${ghecUrl}")
   // Update job configuration
   sh(script: "curl --user ${jenkinsUser}:${jenkinsApiToken} -X POST ${jobUrl} -H 'Content-Type: application/xml' --data-binary '${jobConfig}'")
   // Log job URL and any lines with ghesUrl
   def linesWithGhesLink = jobConfig.readLines().findAll { line -> line.contains(ghesUrl) }
   echo "${jobUrl}|${linesWithGhesLink}" >> 'jenkins_dependencies_report.txt'
   echo "" >> 'jenkins_dependencies_report.txt'
}