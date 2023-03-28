> <h2>Print the name of all jobs including jobs inside of a folder and the folders themselves</h2>

Here's a Groovy script file to fetch all Jenkins jobs:

Open Jenkins server and copy the code from the file "get-all-jobs.sh" and execute it in "script console"

    import jenkins.model.*

    // Get the instance of the Jenkins object
    def jenkins = Jenkins.instance

    // Get all jobs from the Jenkins object
    def jobs = jenkins.getAllItems()

    // Iterate over the jobs and print their names
    jobs.each { job ->
        println(job.fullName)
    }

This script uses the <b>Jenkins.instance</b> method to get the instance of the Jenkins object, and then the <b>getAllItems()</b> method to get all the jobs in Jenkins. It then iterates over each job and prints its full name.

You can run this script in a Jenkins Groovy script console or in a Jenkinsfile using the script step.

> <h2>To download config.xml of Jenkins jobs </h2>

Here is the script file to download the config.xml file(s) with job name and also prints all job names with scm links into "jenkins_dependencies_report.txt"

    JENKINS_URL="$1"
    JENKINS_USER="$2"
    JENKINS_API_TOKEN="$3"
    GHES_URL="$4"

Add all Jenkins job names into this file <b>jenkins_jobs_list.txt</b>

![Alt text](/jenkins-jobs-list.png "List of Jenkins jobs")

> Note: Each job name should be added in new line

Replace the _JENKINS_URL, JENKINS_USER_ and _JENKINS_API_TOKEN_ variables with the appropriate values for your Jenkins instance._GHES_URL_ with GitHub enterprise server URL, in order to print the scm links in the <i>jenkins_dependencies_report.txt</i>

    ./download-config-file.sh <JENKINS_URL> <JENKINS_USER> <JENKINS_API_TOKEN> <GHES_URL>

![Alt text](/jenkins-job-configs.png "List of downloaded config files")

> <h2>Update Jenkins config from GHES URL(s) to GHEC URL(s)</h2>

In this script, we'll do below

- Update GHES Url with GHEC Url
- Updates Organization name
- Updates "http" to "https"
- Updates CredentialId value

you'll need to replace the GHES_URL and GHEC_URL variables with your own GitHub Enterprise Server and GitHub Enterprise Cloud URLs, respectively. You'll also need to update the JENKINS_HOME variable to point to the location of your Jenkins home directory.

    JENKINS_URL="$1"
    OLD_ORG="$2"
    NEW_ORG="$3"
    SSH_CRED_ID="$4"
    HTTP_CRED_ID="$5"
    GHES_URL="$6"
    GHEC_URL="github.com"

Execute the script using below

    ./update-ghes2ghec-config-info-in-jobs.sh jenkis1.demo.ad demo-org1 demo-org2 123 456 gitabc.demo.ad
