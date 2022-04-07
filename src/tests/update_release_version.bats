setup() {
  source src/scripts/versioning/update_release_version.sh
  mockEnvVariable
}

mockEnvVariable() {
  issues_file="src/tests/issues_file.txt"
  export ISSUES=issues_file
  version_file="src/tests/version_file.md"
  export VERSION=version_file
  tag="default"
  export GITHUB_TAG=tag
}

mockIssuesFile() {
  label=$1
  touch ${!ISSUES}
  issue="[#193] test issue =$label=sebeifares"
  echo "$issue" > "${!ISSUES}"
}

@test '1: Check script env requirements' {
  touch ${!ISSUES}
  checkRequirements
}

@test '2: increase version patch ' {
  mockIssuesFile " "
  local releaseVersion="1.5.0"
  local issues=$(< "${!ISSUES}")
  newVersion=$(incrementVersion)
  [ "$newVersion" == "1.5.1" ]
}

@test '3: increase version minor ' {
  mockIssuesFile "minor"
  local releaseVersion="1.5.0"
  local issues=$(< "${!ISSUES}")
  newVersion=$(incrementVersion)
  [ "$newVersion" == "1.6.0" ]
}

@test '4: increase version patch ' {
  mockIssuesFile "major"
  local releaseVersion="1.5.0"
  local issues=$(< "${!ISSUES}")
  newVersion=$(incrementVersion)
  [ "$newVersion" == "2.0.0" ]
}

@test '5: create version file ' {
  mockIssuesFile "major"
  local releaseVersion="1.5.0"
  local issues=$(< "${!ISSUES}")
  newVersion=$(incrementVersion)
  persistNewVersion
  [ -f "${!VERSION}" ]
}

teardown() {
  if [ -f "${!ISSUES}"  ]; then
      rm "${!ISSUES}"
  fi

  if [ -f "${!VERSION}"  ]; then
      rm "${!VERSION}"
  fi
}
