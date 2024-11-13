#!/bin/bash

# Check if the required parameters are passed
if [ "$#" -lt 4 ]; then
  echo "Usage: ./perform_snapshot_tests.sh <config_file> <environment_file> <results_dir> <scheme>"
  exit 1
fi

config_file="$1"
environment_file="$2"
results_dir="$3"
scheme="$4"

# Read the JSON file
devices_json=$(jq -c '.devices[]' "$config_file")
tests_json=$(jq -c '.testPlans[]' "$config_file")
all_locales=$(jq -r '.locales[]' "$config_file")

# Initialize variables
device_names=()
orientations=()
os_versions=()
is_defaults=()

default_device_name=""
default_device_os_version=""
default_device_count=0

# Initialize xcodebuild execution counter
xcodebuild_count=0

# Collect device info and find the default device
while IFS= read -r device; do
  name=$(echo "$device" | jq -r '.name')
  orientation=$(echo "$device" | jq -r '.orientation')
  os_version=$(echo "$device" | jq -r '.os // empty')
  is_default=$(echo "$device" | jq -r '.isDefaultTestDevice // empty')

  device_names+=("$name")
  orientations+=("$orientation")
  os_versions+=("$os_version")
  is_defaults+=("$is_default")

  if [ "$is_default" == "true" ]; then
    default_device_name="$name"
    default_device_os_version="$os_version"
    default_device_count=$((default_device_count + 1))
  fi
done <<< "$devices_json"

if [ "$default_device_count" -eq 0 ]; then
  echo "Error: No default device specified in the configuration (isDefaultTestDevice: true)."
  exit 1
elif [ "$default_device_count" -gt 1 ]; then
  echo "Error: More than one default device specified in the configuration (isDefaultTestDevice: true)."
  exit 1
fi

echo "Default device: $default_device_name"

# Second pass: Set os_version to default if missing
for i in "${!device_names[@]}"; do
  if [ -z "${os_versions[$i]}" ] || [ "${os_versions[$i]}" == "null" ]; then
    os_versions[$i]="$default_device_os_version"
  fi
done

# Map to hold test groups based on device sets
device_set_keys=()
device_set_tests=()
device_set_devices=()

# Function to create a unique key for a device set
create_device_set_key() {
  local devices=("$@")
  IFS=$'\n' sorted_devices=($(printf '%s\n' "${devices[@]}" | sort))
  echo "$(printf '%s|' "${sorted_devices[@]}")"
}

# Function to get the test target for a given test class
get_test_target() {
  local test_class="$1"
  # Adjust this function based on your project's test target names
  # For example, if all tests are in the target "EcosiaSnapshotTests"
  echo "EcosiaSnapshotTests"
}

# Loop through the test plans and test classes
while IFS= read -r test_plan; do
  plan_name=$(echo "$test_plan" | jq -r '.name')
  test_classes_json=$(echo "$test_plan" | jq -c '.testClasses[]')

  while IFS= read -r test_class; do
    class_name=$(echo "$test_class" | jq -r '.name')
    runs_on_device=$(echo "$test_class" | jq -r '.runsOn // empty')
    devices_field=$(echo "$test_class" | jq -r '.devices // empty')
    locales_field=$(echo "$test_class" | jq -r '.locales // empty')

    # Determine the devices this test class should run on
    test_devices=()

    if [ -n "$runs_on_device" ] && [ "$runs_on_device" != "null" ]; then
      # Test class with runsOn specified
      test_device_name="$runs_on_device"
      # Check if test_device_name exists in device_names
      if ! printf '%s\n' "${device_names[@]}" | grep -Fxq "$test_device_name"; then
        echo "Error: The runsOn device '$test_device_name' specified for test class '$class_name' does not exist in the devices list."
        exit 1
      fi
      test_devices+=("$test_device_name")
    else
      # Determine devices from devices_field
      if [ -n "$devices_field" ] && [ "$devices_field" != "null" ]; then
        devices_array=$(echo "$test_class" | jq -r '.devices[]')
        if echo "$devices_array" | grep -qx "all"; then
          # Add all devices
          test_devices=("${device_names[@]}")
        else
          # Add specified devices
          while IFS= read -r device; do
            if ! printf '%s\n' "${device_names[@]}" | grep -Fxq "$device"; then
              echo "Error: The device '$device' specified in 'devices' for test class '$class_name' does not exist in the devices list."
              exit 1
            fi
            test_devices+=("$device")
          done <<< "$devices_array"
        fi
      else
        # No devices specified, use default device
        test_devices+=("$default_device_name")
      fi
    fi

    # Create a key for the device set
    device_set_key=$(create_device_set_key "${test_devices[@]}")

    # Check if this device set key already exists
    found=0
    for idx in "${!device_set_keys[@]}"; do
      if [ "${device_set_keys[$idx]}" == "$device_set_key" ]; then
        # Append the test class to the existing group
        device_set_tests[$idx]+="|$class_name"
        found=1
        break
      fi
    done

    if [ "$found" -eq 0 ]; then
      # Add new device set key and test class
      device_set_keys+=("$device_set_key")
      device_set_tests+=("$class_name")
      device_set_devices+=("$(printf '%s|' "${test_devices[@]}")")
    fi

  done <<< "$test_classes_json"
done <<< "$tests_json"

# Iterate over each device set group and run xcodebuild
for idx in "${!device_set_keys[@]}"; do
  device_set_key="${device_set_keys[$idx]}"
  device_set_tests_str="${device_set_tests[$idx]}"
  device_set_devices_str="${device_set_devices[$idx]}"

  # Split the device set key back into an array
  IFS='|' read -r -a device_set <<< "$device_set_devices_str"

  # Prepare the devices for environment.json with orientation
  devices_json_array=$(for device_name in "${device_set[@]}"; do
    if [ -n "$device_name" ]; then
      # Find index of the device to get orientation
      for i in "${!device_names[@]}"; do
        if [ "${device_names[$i]}" == "$device_name" ]; then
          device_orientation="${orientations[$i]}"
          break
        fi
      done
      # Escape double quotes and backslashes in device_name
      escaped_device_name=$(echo "$device_name" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
      echo "{\"name\": \"$escaped_device_name\", \"orientation\": \"$device_orientation\"}"
    fi
  done | jq -s .)

  # Prepare the list of test classes
  IFS='|' read -r -a test_classes <<< "$device_set_tests_str"

  # Prepare the -only-testing parameters
  only_testing_params=""
  for test_class in "${test_classes[@]}"; do
    test_target=$(get_test_target "$test_class")
    test_identifier="$test_target/$test_class"
    only_testing_params+=" -only-testing \"$test_identifier\""
  done

  # Use the default device for the simulator if it exists in the device set
  device_name=""
  for dev in "${device_set[@]}"; do
    if [ "$dev" == "$default_device_name" ]; then
      device_name="$default_device_name"
      break
    fi
  done

  if [ -z "$device_name" ]; then
    # If default device not in the device set, use the first device
    device_name="${device_set[0]}"
  fi

  # Get the device name to pass into the env file
  simulator_device_name="$device_name"

  # Create the JSON file with the environment variables
  locales_json_array=$(printf '%s\n' ${all_locales[@]} | jq -R . | jq -s .)

  echo "{
    \"DEVICES\": $devices_json_array,
    \"LOCALES\": $locales_json_array,
    \"SIMULATOR_DEVICE_NAME\": \"$simulator_device_name\"
  }" > "$environment_file"

  echo "Environment file created at: $environment_file"
  cat "$environment_file"  # Print the contents of the file for verification

  # Find index of the device to get OS version
  for i in "${!device_names[@]}"; do
    if [ "${device_names[$i]}" == "$device_name" ]; then
      os_version="${os_versions[$i]}"
      break
    fi
  done

  # Prepare result path
  # Concatenate test class names
  test_classes_concat=$(printf '%s_' "${test_classes[@]}")
  test_classes_concat=${test_classes_concat%_}  # Remove trailing underscore
  # Sanitize test_classes_concat to remove spaces and special characters
  test_classes_concat=$(echo "$test_classes_concat" | tr ' /' '__')
  result_path="$results_dir/${test_classes_concat}_tests.xcresult"
  mkdir -p "$results_dir"

  # Prepare the xcodebuild command
  xcodebuild_cmd="xcodebuild test \
    -scheme \"$scheme\" \
    -destination \"platform=iOS Simulator,name=$device_name,OS=$os_version\" \
    $only_testing_params \
    -resultBundlePath \"$result_path\""

  # Run the xcodebuild command
  echo "Running tests on device set: ${device_set[*]}"
  echo "Using device for xcodebuild: $device_name"
  eval $xcodebuild_cmd

  # Increment xcodebuild execution counter
  xcodebuild_count=$((xcodebuild_count + 1))
done

# Print the total number of times xcodebuild was executed
echo "Total xcodebuild commands executed: $xcodebuild_count"