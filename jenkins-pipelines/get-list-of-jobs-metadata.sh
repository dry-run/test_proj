import org.jenkinsci.plugins.workflow.job.WorkflowJob;

def printScm(project, scm){
    if (scm instanceof hudson.plugins.git.GitSCM) {
        scm.getRepositories().each {
            it.getURIs().each {
                println(project + "\t"+ it.toString());
            }
        }
    }
}

Jenkins.instance.getAllItems(Job.class).each {

    project = it.getFullName()
    if (it instanceof AbstractProject){
        printScm(project, it.getScm())
    } else if (it instanceof WorkflowJob) {
        it.getSCMs().each {
            printScm(project, it)
        }
    } else {
        println("project type unknown: " + it)
    }

}