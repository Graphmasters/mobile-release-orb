checkRequirements() {
  if [[ -z "${!ISSUES}" ]];
  then
      echo "Issues file must be provided"
      exit 1
  fi

  if [[ -z "${!DESTINATION_FILE}" ]];
  then
      echo "Error: ChangeLog destination file must be provided"
      exit 1
  fi

  if [[ -z "${!FLAVOR}" ]]
  then
      echo "App flavor label must be provided as the third argument"
      exit 1
  fi
}

sortIssues() {
  while IFS='=' read -r issue labels assignees
  do
    # Add [internal] after the issues number to all issues containing the internal label
    # shellcheck disable=SC2143
    if [[ -n $(echo "${labels}" |  grep -i "internal" ) ]]
    then
      # shellcheck disable=SC2001
      issue=$(echo "$issue" | sed 's/]/][internal]/g')
    fi

    contributors=""
    for value in ${assignees[*]};
    do
      contributors+=" @$value"
    done

    # Classify issues according to the labels they contain
    # shellcheck disable=SC2143
    if [[ -n  $(echo "${labels}" |  grep -i "${!FLAVOR}" ) ]] || \
     [[ -z $(echo "${labels}" |  grep -i "nunav navigation" )  && \
        -z $(echo "${labels}" |  grep -i "nunav bus" )   && \
        -z $(echo "${labels}" |  grep -i "nunav courier" )  && \
        -z $(echo "${labels}" |  grep -i "nunav truck" )  && \
        -z $(echo "${labels}" |  grep -i "mpf" )  && \
        -z $(echo "${labels}" |  grep -i "nunav cargobike" ) \
     ]]
    then
      if [[ -n $(echo "${labels}" |  grep -i "enhancement" ) || -n $(echo "${labels}" |  grep -i "feature" ) ]]
      then
          enhancements[${#enhancements[@]}]="${issue}${contributors}"
      elif [[ -n $(echo "${labels}" |  grep -i "bug" ) || -n $(echo "${labels}" |  grep -i "crash" ) ]]
      then
          bugs[${#bugs[@]}]="${issue}${contributors}"
      else
          others[${#others[@]}]="${issue}${contributors}"
      fi
    fi

  done < "${!ISSUES}"
}

assembleChangeLogs() {
    GroupHeader=$1
    IssuesArr=("${!2}")

    if [[ ${#IssuesArr[@]} -gt 0 ]]
    then
        Content="$GroupHeader \n"

        for (( i=0; i<${#IssuesArr[@]}; i++ ))
        do
            Content+=" - ${IssuesArr[$i]}\n"
        done

        echo -e "${Content}"
    fi
}


generateChangelogFile() {
  # Generate ChangeLog file
  if [[ ${#enhancements[@]} == 0 ]] && [[ ${#bugs[@]} == 0 ]] && [[ ${#others[@]} == 0 ]]
  then
      echo "**There are no significant changes**" > "${!DESTINATION_FILE}"
  else
      {
      assembleChangeLogs "**Bugs**" bugs[@]
      assembleChangeLogs "**Enhancements**" enhancements[@]
      assembleChangeLogs "**Others**" others[@]
      } > "${!DESTINATION_FILE}"
  fi
}

main() {
  checkRequirements
  declare -a bugs
  declare -a enhancements
  declare -a others
  sortIssues
  generateChangelogFile
  changelogFileContent=$(< "${!DESTINATION_FILE}")
  echo "changelog: $changelogFileContent"
}

ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
  main
fi