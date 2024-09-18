#!/bin/bash

# Check if the required parameters are passed
if [ "$#" -lt 4 ]; then
  echo "Usage: ./perform_snapshot_tests.sh <config_file> <environment_file> <results_dir> <scheme>"
  exit 1
fi

# Function to extract test cases from a given test class file
extract_test_cases() {
  local test_class_file=$1
  grep -oE "func test[A-Za-z0-9_]+" "$test_class_file" | awk '{print $2}'
}

config_file=$1
environment_file=$2
results_dir=$3
scheme=$4

# Read the JSON file
devices=$(jq -r '.devices[] | @base64' $config_file)
tests=$(jq -r '.testPlans[] | @base64' $config_file)

# Find the default device
default_device_name=""
default_device_count=0

declare -A device_info_map

for device in $devices; do
  _jq() {
    echo ${device} | base64 --decode | jq -r ${1}
  }
  is_default=$(_jq '.isDefaultTestDevice')
  device_name=$(_jq '.name')
  orientation=$(_jq '.orientation')
  os_version=$(_jq '.os')

  # If os_version is empty or null, default to 'latest'
  if [ -z "$os_version" ] || [ "$os_version" == "null" ]; then
    os_version="latest"
  fi

  device_info_map["$device_name"]="$orientation;$os_version"

  if [ "$is_default" == "true" ]; then
    default_device_name=$device_name
    default_device_count=$((default_device_count + 1))
  fi
done

if [ "$default_device_count" -eq 0 ]; then
  echo "Error: No default device specified in the configuration (isDefaultTestDevice: true)."
  exit 1
elif [ "$default_device_count" -gt 1 ]; then
  echo "Error: More than one default device specified in the configuration (isDefaultTestDevice: true)."
  exit 1
fi

echo "Default device: $default_device_name"

# Map to hold device to tests mapping
declare -A device_to_tests_map

# Loop through the test plans and test classes
for test_plan in $tests; do
  plan_name=$(echo ${test_plan} | base64 --decode | jq -r '.name')
  test_classes=$(echo ${test_plan} | base64 --decode | jq -r '.testClasses[] | @base64')

  for test_class in $test_classes; do
    _jq() {
      echo ${test_class} | base64 --decode | jq -r ${1}
    }
    class_name=$(_jq '.name')
    runs_on_device=$(_jq '.runsOn')

    # Determine the device this test class should run on
    if [[ "$runs_on_device" != "null" && "$runs_on_device" != "" ]]; then
      test_device_name="$runs_on_device"
    else
      test_device_name="$default_device_name"
    fi

    # Add the test class to the device's list
    device_to_tests_map["$test_device_name"]+="$class_name "
  done
done

# Now, for each device, run all its tests in one go
for device_name in "${!device_to_tests_map[@]}"; do
  orientation_and_os="${device_info_map[$device_name]}"
  IFS=';' read -r orientation os_version <<< "$orientation_and_os"

  # Create the JSON file with the environment variables
  echo "{
  \"DEVICE_NAME\": \"$device_name\",
  \"ORIENTATION\": \"$orientation\"
}" > "$environment_file"

  echo "Environment file created at: $environment_file"
  cat "$environment_file"  # Print the contents of the file for verification

  # Perform the build once for the current device
  echo "Cleaning the project"
  xcodebuild clean -scheme "$scheme" -destination "platform=iOS Simulator,name=$device_name,OS=$os_version"
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

  # Collect all test cases for this device
  test_classes=${device_to_tests_map[$device_name]}
  test_cases_to_run=()

  for class_name in $test_classes; do
    # Find the test class file in EcosiaTests subdirectories
    test_class_file=$(find EcosiaTests -name "${class_name}.swift" | head -n 1)

    if [[ -n "$test_class_file" ]]; then
      # Extract the test cases from the test class file
      test_cases=$(extract_test_cases "$test_class_file")
      for test_case in $test_cases; do
        # Append to the list of test cases to run
        test_cases_to_run+=("$plan_name/$class_name/$test_case")
      done
    else
      echo "Test class file for $class_name not found."
    fi
  done

  # Prepare the list of -only-testing parameters
  only_testing_params=""
  for test_identifier in "${test_cases_to_run[@]}"; do
    only_testing_params+=" -only-testing \"$test_identifier\""
  done

  # Replace whitespaces in device_name with _
  updated_device_name=$(echo "$device_name" | tr ' ' '_')

  result_path="$results_dir/${updated_device_name}_tests.xcresult"

  # Prepare the command
  xcodebuild_cmd="xcodebuild test-without-building \
    -scheme \"$scheme\" \
    -clonedSourcePackagesDirPath \"SourcePackages/\" \
    -destination \"platform=iOS Simulator,name=$device_name,OS=$os_version\" \
    $only_testing_params \
    -resultBundlePath \"$result_path\""

  # Run the xcodebuild command
  echo "Running tests on device: $device_name with orientation: $orientation"
  eval $xcodebuild_cmd
done

# Combine all xcresult files into one
combined_result_path="$results_dir/all_tests.xcresult"
# Define the Xcode path based on the CI environment variable
if [ "$CI" = "true" ]; then
    xcresulttool_path="/Applications/Xcode_15.4.app/Contents/Developer/usr/bin/xcresulttool"
else
    xcresulttool_path="/Applications/Xcode.app/Contents/Developer/usr/bin/xcresulttool"
fi

# Run the xcresulttool merge command using the determined path
$xcresulttool_path merge $(find "$results_dir" -name "*.xcresult") --output-path "$combined_result_path"
echo "Combined xcresult created at: $combined_result_path"