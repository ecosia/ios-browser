#!/bin/bash

# Read the JSON file
config_file="EcosiaTests/SnapshotTests/snapshot_configuration.json"
devices=$(jq -r '.devices[] | @base64' $config_file)
tests=$(jq -r '.testPlans[] | @base64' $config_file)

# Build the project first
xcodebuild build -scheme Ecosia

for device in $devices; do
  # Decode the device JSON
  _jq() {
    echo ${device} | base64 --decode | jq -r ${1}
  }
  device_name=$(_jq '.name')
  orientation=$(_jq '.orientation')
  os_version=$(_jq '.os')

    # Check if os_version is empty, if so default to 'latest'
  if [ -z "$os_version" ]; then
    os_version="latest"
  fi

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
        xcodebuild test-without-building \
          -scheme Ecosia \
          -destination "platform=iOS Simulator,name=$device_name,OS=$os_version" \
          -testPlan "$plan_name" \
          -only-testing:$plan_name/$class_name \
          DEVICE_NAME="$device_name" \
          ORIENTATION="$orientation" \
          LOCALES="$locale_string"
      fi
    done
  done
done