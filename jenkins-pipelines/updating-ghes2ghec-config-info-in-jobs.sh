#!/bin/bash

# This script will get all the jobs from a Jenkins instance and update the config.xml for each job
# Usage: ./update_jenkins_jobs.sh <JENKINS_URL> <OLD_ORG> <NEW_ORG> <CRED_ID>
# Example: ./update_jenkins_jobs.sh jenkins.fleet.ad fleet-ad fleet-ad 1

JENKINS_URL="$1"
OLD_ORG="$2"
NEW_ORG="$3"
SSH_CRED_ID="$4"
HTTP_CRED_ID="$5"

CRED_ID=$HTTP_CRED_ID
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

    noCredId=$(grep -c "credentialsId" "$JOB_NAME_FILE".xml)
    hasSSHAgent=$(grep -c "<com.cloudbees.jenkins.plugins.sshagent.SSHAgentBuildWrapper" "$JOB_NAME_FILE".xml)
    userRemoteConfigsEndTag=$(grep -c "<\/hudson.plugins.git.UserRemoteConfig>" "$JOB_NAME_FILE".xml)
    SCMNull=$(grep -c "hudson.scm.NullSCM" "$JOB_NAME_FILE".xml)
    buildWrappersEmptyTag=$(grep -c "<buildWrappers*\/>" "$JOB_NAME_FILE".xml)
    isSSHUrl=$(grep -c "git@$GHES_URL" "$JOB_NAME_FILE".xml)

    echo "$noCredId"
    echo "$hasSSHAgent"
    echo "$buildWrappersEmptyTag"
    echo "$isSSHUrl"

    # Based on the SSH or HTTP, update CRED_ID in config.xml
    if [ "$isSSHUrl" -ge 1 ]; then
        echo "SSH $isSSHUrl"
        CRED_ID=$SSH_CRED_ID
    elif [ "$isSSHUrl" -eq 0 ]; then
        echo "HTTP $isSSHUrl"
        CRED_ID=$HTTP_CRED_ID
    fi

    # Comment this block if you don't want to update the config on Jenkins server
    sed -i "s/$GHES_URL\/$OLD_ORG/$GHEC_URL\/$NEW_ORG/ig" "$JOB_NAME_FILE".xml
    sed -i "s/$GHES_URL:$OLD_ORG/$GHEC_URL:$NEW_ORG/ig" "$JOB_NAME_FILE".xml
    sed -i "s/http:\/\/$GHEC_URL/https:\/\/$GHEC_URL/g" "$JOB_NAME_FILE".xml
    ### sed -i "s/git@$GHEC_URL:/https:\/\/$GHEC_URL\//g" "$JOB_NAME_FILE".xml
    sed -i "s/<credentialsId>.*<\/credentialsId>/<credentialsId>$CRED_ID<\/credentialsId>/g" "$JOB_NAME_FILE".xml

    if [ "$SCMNull" -eq 1 ]; then
        echo "SCM is Null"
        if [ "$hasSSHAgent" -eq 0 ] && [ "$buildWrappersEmptyTag" -eq 1 ] && [ "$isSSHUrl" -ge 1 ]; then
            echo "No SSHAgent,buildWrappers found"
            sed -i "s/\(<buildWrappers*\/>\)/<buildWrappers><com.cloudbees.jenkins.plugins.sshagent.SSHAgentBuildWrapper plugin=\"ssh-agent@1.23\"><credentialIds><string>$CRED_ID<\/string><\/credentialIds><ignoreMissing>false<\/ignoreMissing><\/com.cloudbees.jenkins.plugins.sshagent.SSHAgentBuildWrapper><\/buildWrappers>/g" "$JOB_NAME_FILE".xml
        fi
        if [ "$hasSSHAgent" -eq 0 ] && [ "$buildWrappersEmptyTag" -eq 0 ] && [ "$isSSHUrl" -ge 1 ]; then
            sed -i "s/\(<\/buildWrappers>\)/<com.cloudbees.jenkins.plugins.sshagent.SSHAgentBuildWrapper plugin=\"ssh-agent@1.23\"><credentialIds><string>$CRED_ID<\/string><\/credentialIds><ignoreMissing>false<\/ignoreMissing><\/com.cloudbees.jenkins.plugins.sshagent.SSHAgentBuildWrapper><\/buildWrappers>/g" "$JOB_NAME_FILE".xml
        fi
        echo "$JOB_URL|$lines_with_ghes_link" >>jenkins_withNoSCM_report.txt
        echo -e "" >>jenkins_withNoSCM_report.txt
    elif [ "$noCredId" -eq 0 ] && [ "$userRemoteConfigsEndTag" -eq 1 ]; then
        echo "No buildWrappers found, but found userRemoteConfigs"
        sed -i "s/\(<\/hudson.plugins.git.UserRemoteConfig>\)/<credentialsId>$CRED_ID<\/credentialsId><\/hudson.plugins.git.UserRemoteConfig>/g" "$JOB_NAME_FILE".xml
        echo "$JOB_URL|$lines_with_ghes_link" >>jenkins_withSCM_report.txt
        echo -e "" >>jenkins_withSCM_report.txt
    fi

    # Post the updated config.xml to Jenkins
    curl -k --user "$JENKINS_USER":"$JENKINS_API_TOKEN" -X POST "$JOB_URL" -H 'Content-Type: application/xml' --data-binary "@$JOB_NAME_FILE.xml"

    echo "$JOB_URL|$lines_with_ghes_link" >>jenkins_dependencies_report.txt
    echo -e "" >>jenkins_dependencies_report.txt
done <./jenkins_jobs_list.txt
