#!/bin/bash

# Check if the required parameters are passed
if [ "$#" -lt 2 ]; then
  echo "Usage: ./perform_snapshot_tests.sh <config_file> <scheme>"
  exit 1
fi

# Function to extract test cases from a given test class file
extract_test_cases() {
  local test_class_file=$1
  grep -oE "func test[A-Za-z0-9_]+" "$test_class_file" | awk '{print $2}'
}

# Function to get device information
get_device_info() {
  local device_name="$1"
  local info_type="$2"
  for device in $devices; do
    _jq() {
      echo ${device} | base64 --decode | jq -r ${1}
    }
    current_device_name=$(_jq '.name')
    if [[ "$current_device_name" == "$device_name" ]]; then
      echo $(_jq ".$info_type")
      return
    fi
  done
}

# Read the JSON file
config_file=$1
devices=$(jq -r '.devices[] | @base64' $config_file)
tests=$(jq -r '.testPlans[] | @base64' $config_file)
scheme=$2

# Loop through the test plans and test classes
for test_plan in $tests; do
  plan_name=$(echo ${test_plan} | base64 --decode | jq -r '.name')
  test_classes=$(echo ${test_plan} | base64 --decode | jq -r '.testClasses[] | @base64')

  for test_class in $test_classes; do
    _jq() {
      echo ${test_class} | base64 --decode | jq -r ${1}
    }
    class_name=$(_jq '.name')
    test_devices=$(echo ${test_class} | base64 --decode | jq -r '.devices[]')

    # If "all" is specified, use all devices from the devices list
    if [[ "$test_devices" == "all" ]]; then
      test_devices=$(jq -r '.devices[] | .name' $config_file)
    fi

    IFS=$'\n' # Change IFS to handle device names with spaces correctly
    for test_device_name in $test_devices; do
      # Get the full device information from the devices list
      device_info=$(jq -r --arg name "$test_device_name" '.devices[] | select(.name == $name) | @base64' $config_file)

      # If the device is found, proceed with the testing
      if [ -n "$device_info" ]; then
        device_json=$(echo "$device_info" | base64 --decode)
        device_name=$(echo "$device_json" | jq -r '.name')
        orientation=$(echo "$device_json" | jq -r '.orientation')
        os_version=$(echo "$device_json" | jq -r '.os')

        # Check if os_version is empty or null, if so default to 'latest'
        if [ -z "$os_version" ] || [ "$os_version" == "null" ]; then
          os_version="latest"
        fi

        # Get the locales for this test class
        test_locales=$(_jq '.locales[]')

        if [[ "$test_locales" == "all" ]]; then
          locales=$(jq -r '.locales[]' $config_file)
        else
          locales=$(echo $test_class | base64 --decode | jq -r '.locales[]')
        fi

        # Combine locales into a comma-separated string
        locale_string=$(echo "${locales[@]}" | tr '\n' ',' | sed 's/,$//')

        # Create the JSON file with the environment variables
        env_file_path="EcosiaTests/SnapshotTests/environment.json"
        echo "{
  \"DEVICE_NAME\": \"$device_name\",
  \"ORIENTATION\": \"$orientation\",
  \"LOCALES\": \"$locale_string\"
}" > "$env_file_path"

        echo "Environment file created at: $env_file_path"
        cat "$env_file_path"  # Print the contents of the file for verification

        # Perform the build once for the current device
        echo "Building the project for device: $device_name, OS: $os_version"
        xcodebuild build-for-testing \
          -scheme "$scheme" \
          -clonedSourcePackagesDirPath "SourcePackages/" \
          -destination "platform=iOS Simulator,name=$device_name,OS=$os_version" \
          CODE_SIGN_IDENTITY="" \
          CODE_SIGNING_REQUIRED=NO \
          PROVISIONING_PROFILE_SPECIFIER="" \
          CODE_SIGN_ENTITLEMENTS="" \
          CODE_SIGNING_ALLOWED="NO"

        # Find the test class file in EcosiaTests subdirectories
        test_class_file=$(find EcosiaTests -name "${class_name}.swift" | head -n 1)

        if [[ -n "$test_class_file" ]]; then
          # Extract the test cases from the test class file
          test_cases=$(extract_test_cases "$test_class_file")

          # Construct and run the xcodebuild command for each test case separately
          for test_case in $test_cases; do

            result_path="EcosiaTests/Results/$device_name\_$class_name\_$test_case.xcresult"

            # Prepare the command
            xcodebuild_cmd="xcodebuild test-without-building \
              -scheme \"$scheme\" \
              -clonedSourcePackagesDirPath \"SourcePackages/\" \
              -destination \"platform=iOS Simulator,name=$device_name,OS=$os_version\" \
              -only-testing \"$plan_name/$class_name/$test_case\" \
              -resultBundlePath \"$result_path\""

            # Run the xcodebuild command
            echo "Running test case: $test_case for class: $class_name on device: $device_name with locales: $locale_string"
            eval $xcodebuild_cmd
          done
        else
          echo "Test class file for $class_name not found."
        fi
      else
        echo "Device $test_device_name not found in the devices list. Skipping..."
      fi
    done
    unset IFS # Reset IFS
  done
done