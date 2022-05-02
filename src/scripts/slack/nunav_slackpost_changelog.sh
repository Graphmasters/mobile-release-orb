checkRequirements() {
  if [[ -z "${!CHANNEL}" ]];
  then
      echo "Slack channel must be provided"
      exit 1
  fi

  if [[ -z "${!SLACK_WEBHOOK}" ]];
  then
      echo "Slack webhook url must be provided"
      exit 1
  fi

  if [[ -z "${!RELEASE_VERSION}" ]];
  then
      echo "Release version file must be provided"
      exit 1
  fi

  if [[ -z "${!GITHUB_TAG}" ]];
  then
      echo "Github tag name must be provided"
      exit 1
  fi

  if [[ -z "${!PACKAGE_NAME}" ]];
  then
      echo "Package name ID must be provided"
      exit 1
  fi

  if [[ -z "${!RELEASE_STAGE}" ]];
  then
      echo "Release stage must be provided"
      exit 1
  fi
}


formatChangelogContent() {
  local content=$1

  # add issues Links
  # shellcheck disable=SC2162
  issues=$(while read Line
  do
      # shellcheck disable=SC2143
      if [[ -n $(echo "${Line}" |  grep -i "#" ) ]];
      then
        for value in ${Line};
        do
           if [[  -n $(echo "${value}" |  grep -i "#" ) ]];
           then
           issueNumber=$(echo "${value}" |  cut -d'#'  -f 2 | cut -d']'  -f 1  )
           fi
        done
          hyperLink="<https://github.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/issues/$issueNumber|#$issueNumber>"
          # shellcheck disable=SC2001
          newLine=$(echo "$Line" | sed 's/#//g' )
          echo  "${newLine/$issueNumber/$hyperLink}"

      else
          echo "$Line"
      fi
  done < "$content")

  result=$(echo "$issues" | sed 's/*//g'  | sed 's/-/• /' | sed 's/"//g' )
  echo "$result"
}

slackPost() {
  local content="\n\n>>>$1"

  version=$(< "${!RELEASE_VERSION}")
  versionCode=$(< "${!VERSION_CODE}")
  ReleaseName="${!GITHUB_TAG}-$version"

  ReleaseLink="https://github.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/releases/tag/$ReleaseName"
  WorkflowLink="https://circleci.com/workflow-run/$CIRCLE_WORKFLOW_ID"
  PlayStoreLink=""
  users=""

  if [[ ${POST_PLAYSTORE_DIRECT_LINK} ]]; then
    PlayStoreLink="\n\n*PlayStore directLink:*\nhttps://play.google.com/apps/test/${!PACKAGE_NAME}/$versionCode"
  fi

  if [[ "$USER_FRACTION" != 0  ]]; then
    content=""
    users="(*$USER_FRACTION%*)"
  fi

  json="{\"channel\": \"#${!CHANNEL}\", \"text\": \"New App Version (*$version*) pushed to ${!RELEASE_STAGE} $users ${ICON}\n*Github release:*\n$ReleaseLink\n\n*Workflow:*\n$WorkflowLink $PlayStoreLink $content\", \"username\": \"Release Info\", \"icon_emoji\": \"$ICON\"}"
  curl -s --data-urlencode "payload=$json" "${!SLACK_WEBHOOK}"
}

main() {
  checkRequirements
  content=$(formatChangelogContent "${!CHANGELOG}")
  echo "content: $content"
  slackPost "$content"
}

ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
  main
fi

