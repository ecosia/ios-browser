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

  # Fallback to "latest" if OS is not specified
  if [ -z "$os_version" ] || [ "$os_version" == "null" ]; then
    os_version="latest"
  fi

  echo "Device: $device_name, Orientation: $orientation, OS: $os_version"

  # Initialize a variable to store the xcodebuild command
  xcodebuild_cmd="xcodebuild clean test -scheme EcosiaSnapshotTests -testPlan EcosiaSnapshotTests -destination \"platform=iOS Simulator,name=$device_name,OS=$os_version\" DEVICE_NAME=\"$device_name\" ORIENTATION=\"$orientation\""

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
        locales=$(jq -r '.locales[]' $config_file | paste -sd "," -)
      else
        locales=$(echo $test | base64 --decode | jq -r '.locales[]' | paste -sd "," -)
      fi

      xcodebuild_cmd+=" -only-testing:$test_class LOCALES=\"$locales\""
    fi
  done

  # Debug output of the command before running
  echo "Running command: $xcodebuild_cmd"

  # Run the constructed xcodebuild command
  eval $xcodebuild_cmd
done