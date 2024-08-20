#!/bin/bash

# Read the JSON file
config_file="EcosiaTests/SnapshotTests/snapshot_configuration.json"
devices=$(jq -r '.devices[] | @base64' $config_file)
tests=$(jq -r '.tests[] | @base64' $config_file)

for device in $devices; do
  # Decode the device JSON
  _jq() {
    echo ${device} | base64 --decode | jq -r ${1}
  }
  device_name=$(_jq '.name')
  orientation=$(_jq '.orientation')
  os_version=$(_jq '.os')

  # Initialize a variable to store the xcodebuild command
  xcodebuild_cmd="xcodebuild test -scheme Ecosia -destination \"platform=iOS Simulator,name=$device_name,OS=$os_version\" -testPlan EcosiaSnapshotTests DEVICE_NAME=\"$device_name\""

  for test in $tests; do
    _jq() {
      echo ${test} | base64 --decode | jq -r ${1}
    }
    test_class=$(_jq '.testClass')
    test_devices=$(_jq '.devices[]')

    if [[ "$test_devices" == "all" || "$test_devices" == *"$device_name"* ]]; then
      # Check locales for this test class
      test_locales=$(_jq '.locales[]')

      if [[ "$test_locales" == "all" ]]; then
        locales=$(jq -r '.locales[]' $config_file)
      else
        locales=$(echo $test | base64 --decode | jq -r '.locales[]')
      fi

      # Combine locales into a single string
      locale_string=""
      for locale in $locales; do
        locale_string+="$locale "
      done

      xcodebuild_cmd+=" -only-testing:$test_class LOCALES=\"$locale_string\""
    fi
  done

  # Run the constructed xcodebuild command
  eval $xcodebuild_cmd
done