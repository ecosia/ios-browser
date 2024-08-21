#!/bin/bash

# Function to extract test cases from a given test class file
extract_test_cases() {
  local test_class_file=$1
  grep -oE "func test[A-Za-z0-9_]+" "$test_class_file" | awk '{print $2}'
}

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
  xcodebuild build-for-testing \
    -scheme "$scheme" \
    -clonedSourcePackagesDirPath SourcePackages \
    -destination "platform=iOS Simulator,name=$device_name,OS=$os_version" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    PROVISIONING_PROFILE_SPECIFIER="" \
    CODE_SIGN_ENTITLEMENTS="" \
    CODE_SIGNING_ALLOWED="NO"

  # Initialize the xcodebuild command
  xcodebuild_cmd="xcodebuild test-without-building -scheme \"$scheme\" -destination \"platform=iOS Simulator,name=$device_name,OS=$os_version\""

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
        locale_string=$(echo "${locales[@]}" | tr '\n' ',' | sed 's/,$//')

        # Find the test class file in EcosiaTests subdirectories
        test_class_file=$(find EcosiaTests -name "${class_name}.swift" | head -n 1)

        if [[ -n "$test_class_file" ]]; then
          # Extract the test cases from the test class file
          test_cases=$(extract_test_cases "$test_class_file")

          # Append each test case to the xcodebuild command
          for test_case in $test_cases; do
            xcodebuild_cmd+=" -only-testing:$plan_name/$class_name/$test_case"
          done

          # Add the remaining parameters
          xcodebuild_cmd+=" DEVICE_NAME=\"$device_name\" ORIENTATION=\"$orientation\" LOCALES=\"$locale_string\""
        else
          echo "Test class file for $class_name not found."
        fi
      fi
    done
  done

  # Run the accumulated xcodebuild command
  echo "Running tests for device: $device_name with the following command:"
  echo $xcodebuild_cmd
  eval $xcodebuild_cmd
done