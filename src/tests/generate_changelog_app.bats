setup() {
  source src/scripts/changelog/app_changelog_generator.sh

  mockEnvVariable
  mockIssuesFile
}

mockEnvVariable() {
  issues_file="src/tests/issues_file.txt"
  export ISSUES=issues_file
  changelog_file="src/tests/changelog.md"
  export DESTINATION_FILE=changelog_file
  flavor="nunav navigation"
  export FLAVOR=flavor
}

mockIssuesFile() {
  touch ${!ISSUES}

  issue1="[#193] test issue =ci=sebeifares"
  echo "$issue1" >> "${!ISSUES}"
  issue2="[#194] test issue =enhancement nunav navigation=sebeifares"
  echo "$issue2" >> "${!ISSUES}"
  issue3="[#195] test issue =bugs=sebeifares"
  echo "$issue3" >> "${!ISSUES}"
  issue4="[#196] test issue =enhancement nunav bus=sebeifares"
  echo "$issue4" >> "${!ISSUES}"
}

@test '1: Check script env requirements' {
    checkRequirements
}

@test '2: sort issues' {
  declare -a bugs
  declare -a enhancements
  declare -a others

  sortIssues

  [ ${#others[@]} == 1 ]
  [ ${#enhancements[@]} == 1 ]
  [ ${#bugs[@]} == 1 ]
}

@test '3: generate Changelog file' {

  main

  [ -f ${!DESTINATION_FILE} ]
}

teardown() {
  rm ${!ISSUES}

  if [ -f "${!DESTINATION_FILE}"  ]; then
      rm ${!DESTINATION_FILE}
  fi
}
