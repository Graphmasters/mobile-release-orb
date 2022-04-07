checkRequirements() {
  if [[ -z "${!CHANGELOG}" ]]
  then
      echo "Error: Changelog file must be provided"
      exit 1
  fi

  if [[ ! -f "${!CHANGELOG}" ]];
  then
    echo "Error: Changelog file ${!CHANGELOG} does not exist "
    exit 1
  fi

  if [[ -z ${!GITHUB_TAG} ]]
  then
      echo "Error: TAG must be provided"
      exit 1
  fi

  if [[ -z ${!VERSION} ]]
  then
      echo "Error: Version must be provided"
      exit 1
  fi

  if [[ ! -f "${!VERSION}" ]];
  then
    echo "Error: Version file ${!VERSION} does not exist "
    exit 1
  fi

  if [[ -z "${!TOKEN}" ]]
  then
      echo "Error: Github token flavor must be provided"
      exit 1
  fi
}

createReleaseContent() {
  changelogFile=$1
  # shellcheck disable=SC2002
  content=$(cat "$changelogFile" | sed 's/^/\\n /' )
  # shellcheck disable=SC2086
  echo $content
}

createRelease(){
  releaseName=$1
  content=$2

  body=$(printf '{"tag_name": "%s","target_commitish": "master","name": "%s","body": "%s","draft": false,"prerelease": false}' "$releaseName" "$releaseName" "$content")
  createReleaseUrl="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/releases"
  response=$(curl -Ss -u "${!TOKEN}:" -d "$body" "$createReleaseUrl")

  echo "$response"
}

main() {
  checkRequirements
  content=$(createReleaseContent "${!CHANGELOG}")
  echo -e "Content : $content"
  releaseVersion=$(< "${!VERSION}")
  releaseName="${!GITHUB_TAG}-$releaseVersion"
  echo "Create github release : $releaseName"
  response=$(createRelease "$releaseName" "$content")
  echo "Response: $response"
}

ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
  main
fi