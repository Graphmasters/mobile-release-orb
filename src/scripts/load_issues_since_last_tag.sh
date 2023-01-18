checkRequirements() {
  if [[ -z "${!DESTINATION_FILE}" ]];
  then
      echo "Issues file must be provided"
      exit 1
  fi

  if [[ -z "${!TOKEN}" ]];
  then
      echo "Github token must be provided"
      exit 1
  fi

  if [[ -z "${!GITHUB_TAG}" ]];
  then
      echo "tag must be provided"
      exit 1
  fi
}

geCommitsSinceTag() {
  if [[ -n $lastUsedTag ]]
  then
    # Get all the commits generated since the creation of the given tag.
    # echo Looking for issues since Tag "${lastUsedTag}" ......
    commits=$(git rev-list --oneline "$lastUsedTag"..HEAD)
    echo "$commits"
  else
    echo "No tag was found for this project/flavor"
    exit 1
  fi
}

getIssuesNumberSinceTag() {
  tag=$1
  commits=$(geCommitsSinceTag "$tag")

  declare -a issueNumbers

  for value in $commits
  do
    issueNb=$(echo "$value" | grep "#" | cut -d "#" -f2 | sed 's/[^0-9]*//g')
    if [[ -n ${issueNb} ]]
    then
        issueNumbers[${#issueNumbers[@]}]=${issueNb}
    fi
  done

  #remove duplicate elements from array
  result=$(printf "%s\n" "${issueNumbers[@]}" | sort -u)
  echo "$result"
}

getIssuesData() {
  issuesNumbers=$1

  declare -a Values
  # Save closed issues number and title.
  for value in  $issuesNumbers;
  do
     GetIssues="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/issues/$value"
     IssuesData=$(curl -Ss -u "${!TOKEN}:" "$GetIssues" )

     Status=$(echo "${IssuesData}" | jq '.state' | sed 's/"//g')
     labels=$(echo "${IssuesData}" | jq '.labels[]?.name' | sed 's/"//g' | tr '\n' ' ')
     title=$(echo  "${IssuesData}" | jq '.title' | sed 's/"//g')
     url=$(echo "${IssuesData}" | jq '.html_url' | sed 's/"//g')
     assignees=$(echo "${IssuesData}" | jq '.assignees[]?.login' | sed 's/"//g' | tr '\n' ' ')

     # shellcheck disable=SC2001
     Issue="[#$value] $(echo "${title}" | sed 's/[^a-zA-Z0-9 öäüÖÄÜ]//g')=$labels=$assignees"
     contain="false"

     for (( i= 0; i < ${#Values[@]}; i++ ))
     do
        if [[ "${Values[$i]}" == "${value}" ]]
        then
           contain="true"
        fi
     done

     # shellcheck disable=SC2143
     if [[ ${Status} == "closed" ]] && [[ ${contain} = "false" ]] && [[ -z $(echo "${url}" |  grep -i "pull" ) ]]
     then
          Issues[${#Issues[@]}]=${Issue}
          Values[${#Values[@]}]=${value}
     fi
  done
}

saveIssues()
{
  file=$1

  for (( i=0; i<${#Issues[@]}; i++ ))
  do
    echo "${Issues[$i]}"
  done > "${file}"
}

main() {
  checkRequirements
  lastUsedTag=$(git tag -l "${!GITHUB_TAG}-*" --sort -version:refname | head -n 1 || true )
  echo "Last used Tag : $lastUsedTag"
  issuesNumbers=$(getIssuesNumberSinceTag "$lastUsedTag" )
  declare -a Issues
  getIssuesData "$issuesNumbers"

  if [[ ${#Issues[@]} == 0 ]];
  then
    echo "There are no significant changes"
    touch "${!DESTINATION_FILE}"
  else
    echo "Found Issues : ${Issues[*]}"
    saveIssues "${!DESTINATION_FILE}"
  fi
}

ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
  main
fi