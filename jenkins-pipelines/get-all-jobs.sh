import jenkins.model.*

// Get the instance of the Jenkins object
def jenkins = Jenkins.instance

// Get all jobs from the Jenkins object
def jobs = jenkins.getAllItems()

// Iterate over the jobs and print their names
jobs.each { job ->
    println(job.fullName)
}