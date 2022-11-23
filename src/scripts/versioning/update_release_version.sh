checkRequirements() {
  if [[ -z "${!ISSUES}" ]];
  then
      echo "Issues file must be provided as the first argument"
      exit 1
  fi

  if [[ ! -f "${!ISSUES}" ]];
  then
    echo "Error: Issues file ${!ISSUES} does not exist "
    exit 1
  fi

  if [[ -z "${!VERSION}" ]];
  then
      echo "Error: version file must be provided"
      exit 1
  fi

  if [[ -z "${!GITHUB_TAG}" ]];
  then
      echo "Error: Tag must be provided"
      exit 1
  fi
}

getLastVersion (){
  # Extract release version from the last created tag
  lastUsedTag=$(git tag -l "${!GITHUB_TAG}" --sort -version:refname  | head -n 1)
  releaseVersion=$(echo "${lastUsedTag}-*" | rev | cut -d'-' -f 1 | rev )
  echo "${releaseVersion-"0.0.1"}"
}

incrementVersion(){
  major=$(echo "${releaseVersion}" |  cut -d'.'  -f 1 )
  minor=$(echo "${releaseVersion}" |  cut -d'.'  -f 2 )
  patch=$(echo "${releaseVersion}" |  cut -d'.'  -f 3 )

  # check issues for major and minor labels
  processIssuesFile

  # Increase the release version based on the label minor and major found in the issues
  if [[ ${majorExists} == "true" ]];
  then
    major=$((major+1))
    minor=0
    patch=0
  elif [[ ${minorExists} == "true" ]];
  then
    minor=$((minor+1))
    patch=0
  else
    patch=$((patch+1))
  fi

  echo "$major.$minor.$patch"
}

processIssuesFile(){
  majorExists="false"
  minorExists="false"
  # shellcheck disable=SC2034
  while IFS='=' read -r key value
  do
     # shellcheck disable=SC2143
     if [[ -n $(echo "${value}" |  grep -i "major" ) ]]
     then
        majorExists="true"
        break
     elif [[ -n $(echo "${value}" |  grep -i "minor" ) ]]
     then
        minorExists="true"
     fi
  done < "${!ISSUES}"
}

persistNewVersion () {
  echo "$newVersion" > "${!VERSION}"
}

main() {
  checkRequirements
  releaseVersion=$(getLastVersion)
  echo "Last used Version = $releaseVersion"
  issuesData=$(< "${!ISSUES}")
  echo "Issues File content: $issuesData"
  newVersion=$(incrementVersion)
  echo "Incremented Version = $newVersion"
  persistNewVersion
}

ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
  main
fi