
## This script will print the name of all jobs including jobs inside of a folder and the folders themselves:

Jenkins.instance.getAllItems(AbstractItem.class).each {
   println it.fullName
};

# import jenkins.model.Jenkins
# import hudson.model.*
# import hudson.scm.* 
# def jenkins = Jenkins.getInstance() 
# jenkins.getItems().each { job -> 
#  println "Job Name: ${job.fullName}"
#    println "Job URL: ${jenkins.getRootUrl()}${job.getUrl()}"
#    println "Job Description: ${job.description}" 
#        def scm = job.getScm()
#    if (scm != null && scm.descriptor.displayName != "None") { 
#        println "SCM: ${scm.descriptor.displayName}"
#        println "Repository URL: ${scm.getRepositories().get(0).getURIs().get(0)}"
#        println "Branch: ${scm.getBranches().get(0).name}"  } 
#        println "--------------------------------------------------------"
#     }
# }




