checkRequirements() {
  if [[ -z "${!ISSUES}" ]];
  then
      echo "Issues file must be provided"
      exit 1
  fi

  if [[ -z "${!VERSION}" ]];
  then
      echo "Release version file must be provided"
      exit 1
  fi

  if [[ ! -f "${!ISSUES}" ]]
  then
    echo "File ${!ISSUES} does not Exist"
    exit 1
  fi

  if [[ -z "${!TOKEN}" ]];
  then
      echo "GITHUB api token be provided"
      exit 1
  fi

  if [[ -z "${!APP_FLAVOR}" ]];
  then
      echo "App flavor must be provided"
      exit 1
  fi
}

updateIssuesStatus(){
  releaseVersion=$(< "${!VERSION}")
  flavor="${!APP_FLAVOR}"

  # shellcheck disable=SC2034
  while IFS='=' read -r issue labels assignees
  do
      issueNumber=$(echo "${issue}" |  cut -d' '  -f 1 | sed 's/[][]//g' | sed 's/#//'  )
      if [[ -n ${issueNumber} ]]
      then
          # get Issue comments.
          releaseUrl="https://github.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/releases/tag/release-${flavor,,}-$releaseVersion"
          requestCommentsUrl="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/issues/$issueNumber/comments"
          response=$(curl -s -u "${!TOKEN}:" "${requestCommentsUrl}" )
          commentsData=$(echo "$response" |  jq -c  '.[]? | { id : .id , comment: .body }' )
          deploymentCommentExists="false"

          while IFS= read -r line;
          do
              # Update comment if the issue already contains a deployment comment.
              # shellcheck disable=SC2143
              if [[ -n $(echo "${line}" |  grep -i "Deployed" ) ]]
              then
                deploymentCommentExists="true"
                id=$(echo "$line" | jq '.id' )
                comment=$(echo "$line" | jq '.comment' | sed 's/"//g')

                if [[ -z $(echo "${comment}" |  grep -i "${!APP_FLAVOR}" ) ]]
                then
                    comment+="\n * **${!APP_FLAVOR}** [$releaseVersion]($releaseUrl)"
                    body=$(printf '{ "body": "%s" }' "$comment" )
                    link="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/issues/comments/$id"
                    response=$(curl -s -u "${!TOKEN}:" -d "$body" "${link}")
                fi
                break
              fi
          done <<< "$commentsData"

          # if the issue does not contains a deployment comment create a new one.
          if [[ $deploymentCommentExists == "false" ]]
          then
            comment="### Deployed to **_Alpha_** for flavor:\n * **${!APP_FLAVOR}** [$releaseVersion]($releaseUrl)"
            body=$(printf '{ "body": "%s" }' "$comment" )
            link="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/issues/$issueNumber/comments"
            response=$(curl -s -u "${!TOKEN}:" -d "$body" "${link}")
          fi
       fi
  done < "${!ISSUES}"
}

main() {
  checkRequirements
  echo Updating Deployment status....
  updateIssuesStatus
}

ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
  main
fi
