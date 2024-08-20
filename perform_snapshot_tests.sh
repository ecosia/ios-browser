#!/bin/bash

# Read the JSON file
config_file="EcosiaTests/SnapshotTests/snapshot_configuration.json"
devices=$(jq -r '.devices[] | @base64' $config_file)
tests=$(jq -r '.testPlans[] | @base64' $config_file)
scheme="EcosiaSnapshotTests"

for device in $devices; do
  # Decode the device JSON
  _jq() {
    echo ${device} | base64 --decode | jq -r ${1}
  }
  device_name=$(_jq '.name')
  orientation=$(_jq '.orientation')
  os_version=$(_jq '.os')

  # Check if os_version is empty or null, if so default to 'latest'
  if [ -z "$os_version" ] || [ "$os_version" == "null" ]; then
    os_version="latest"
  fi

  # Build the project once for the current device
  echo "Building the project for device: $device_name, OS: $os_version"
  xcodebuild build \
    -scheme "$scheme" \
    -destination "platform=iOS Simulator,name=$device_name,OS=$os_version"

  # Loop through the test plans and test classes
  for test_plan in $tests; do
    plan_name=$(echo ${test_plan} | base64 --decode | jq -r '.name')
    test_classes=$(echo ${test_plan} | base64 --decode | jq -r '.testClasses[] | @base64')

    for test_class in $test_classes; do
      _jq() {
        echo ${test_class} | base64 --decode | jq -r ${1}
      }
      class_name=$(_jq '.name')
      test_devices=$(_jq '.devices[]')
      
      # If the test class should run on the current device
      if [[ "$test_devices" == "all" || "$test_devices" == *"$device_name"* ]]; then
        # Get the locales for this test class
        test_locales=$(_jq '.locales[]')

        if [[ "$test_locales" == "all" ]]; then
          locales=$(jq -r '.locales[]' $config_file)
        else
          locales=$(echo $test_class | base64 --decode | jq -r '.locales[]')
        fi

        # Combine locales into a comma-separated string
        locale_string=""
        for locale in $locales; do
          locale_string+="$locale,"
        done
        # Remove the trailing comma
        locale_string=${locale_string%,}

        # Construct and run the xcodebuild command for each test class separately
        echo "Running tests for class: $class_name on device: $device_name with locales: $locale_string"
        xcodebuild \
          -scheme "$scheme" \
          -destination "platform=iOS Simulator,name=$device_name,OS=$os_version" \
          -only-testing:$plan_name/$class_name \
          DEVICE_NAME="$device_name" \
          ORIENTATION="$orientation" \
          LOCALES="$locale_string"
      fi
    done
  done
done