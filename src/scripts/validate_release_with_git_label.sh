checkRequirements() {
  if [[ -z "${!ISSUES}" ]];
  then
      echo "Issues file must be provided"
      exit 1
  fi

  if [[ ! -f "${!ISSUES}" ]]
  then
    echo "File ${!ISSUES} does not Exist"
    exit 1
  fi

  if [[ -z "${!TOKEN}" ]];
  then
      echo "Circleci api token be provided"
      exit 1
  fi

  if [[ -z "${!LABEL}" ]];
  then
      echo "Github flavor label must be provided"
      exit 1
  fi
}

function CancelWorkflow(){
  # shellcheck disable=SC2124
  outputMessage=$@

  cancelBuildUrl="https://circleci.com/api/v1.1/project/github/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/$CIRCLE_BUILD_NUM/cancel?circle-token=${!TOKEN}"
  cancelStatus=$(curl -X POST "${cancelBuildUrl}" | jq -r '.status' )

  echo "${outputMessage}"
  echo "Workflow ${cancelStatus}"
}


# if a issues from the issues file contains the flavo label passed in the parameter
# continue workflow else Cancel Workflow
processIssues(){
  local issuesFile="$1"

  valid="false"

  # shellcheck disable=SC2034
  while IFS='=' read -r issue labels assignees
  do
      # shellcheck disable=SC2143
      if [[ -n $(echo "${labels}" |  grep -i "${!LABEL}" ) ]] || \
      [[ -z $(echo "${labels}" |  grep -i "nunav navigation" )  && \
        -z $(echo "${labels}" |  grep -i "nunav bus" )   && \
        -z $(echo "${labels}" |  grep -i "nunav courier" )  && \
        -z $(echo "${labels}" |  grep -i "nunav truck" )  && \
        -z $(echo "${labels}" |  grep -i "nunav cargobike" ) \
      ]]
      then
        valid="true"
        break
      fi
  done < "$issuesFile"

  if [[ ${valid} = "false" ]]
  then
      CancelWorkflow "No issues with Label: ${!LABEL} found"
  elif [[ ${valid} = "true" ]]
  then
      echo "Continue Workflow"
  fi
}

main() {
  checkRequirements

  # get the hash value of the commit that triggered the circleci workflow
  commitThatTriggeredTheBuild=$(git log -n 1 --oneline "${CIRCLE_SHA1}")
  cancelFlag="skip ${!LABEL}"

  # if the commit mentioned above contains a Cancel flag Cancel Circleci Workflow
  # shellcheck disable=SC2143
  if [[ -n  $(echo "${commitThatTriggeredTheBuild}" | grep -i "$cancelFlag" ) ]]
  then
    CancelWorkflow "[ ${cancelFlag} ] flag found."
    exit 1
  fi

  processIssues "${!ISSUES}"
}

ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
  main
fi