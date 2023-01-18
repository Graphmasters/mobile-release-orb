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

  if [[ -z "${!CHANGELOG}" ]];
  then
      echo "Changelog file must be provided"
      exit 1
  fi

  if [[ -z "${!VERSION}" ]];
  then
      echo "Release releaseVersion file must be provided"
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
  local content=$1
  releaseVersion=$(< "${!VERSION}")
  releaseName="$CIRCLE_PROJECT_REPONAME-$releaseVersion"
  releaseLink="https://github.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/releases/tag/$releaseName"

  json="{\"channel\": \"#${!CHANNEL}\", \"text\": \"*$CIRCLE_PROJECT_REPONAME* (*$releaseVersion*) released $ICON\nRelease:\n$releaseLink\n\n>>>$content\", \"username\": \"Release Info\", \"icon_emoji\": \"$ICON\"}"

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
