setup() {
  source src/scripts/changelog/multiplatform_changelog_generator.sh

  mockEnvVariable
  mockIssuesFile
}

mockEnvVariable() {
  issues_file="src/tests/issues_file.txt"
  export ISSUES=issues_file
  changelog_file="src/tests/changelog.md"
  export CHANGELOG=changelog_file
}

mockIssuesFile() {
  touch ${!ISSUES}

  issue1="[#193] test issue =minor=sebeifares"
  echo "$issue1" >> "${!ISSUES}"
  issue2="[#194] test issue =enhancement=sebeifares"
  echo "$issue2" >> "${!ISSUES}"
  issue3="[#195] test issue =bugs=sebeifares"
  echo "$issue3" >> "${!ISSUES}"
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

  [ -f ${!CHANGELOG} ]
}

teardown() {
  rm ${!ISSUES}

  if [ -f "${!CHANGELOG}"  ]; then
      rm ${!CHANGELOG}
  fi
}
