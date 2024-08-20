#!/bin/bash

# Read the JSON file
config_file="EcosiaTests/SnapshotTests/snapshot_configuration.json"
devices=$(jq -r '.devices[] | @base64' $config_file)
test_plans=$(jq -r '.testPlans[] | @base64' $config_file)

for device in $devices; do
  # Decode the device JSON
  _jq() {
    echo ${device} | base64 --decode | jq -r ${1}
  }
  device_name=$(_jq '.name')
  orientation=$(_jq '.orientation')
  os_version=$(_jq '.os')

  for test_plan in $test_plans; do
    _jq() {
      echo ${test_plan} | base64 --decode | jq -r ${1}
    }
    plan_name=$(_jq '.name')
    test_classes=$(echo ${test_plan} | base64 --decode | jq -r '.testClasses[] | @base64')

    for test_class in $test_classes; do
      _jq() {
        echo ${test_class} | base64 --decode | jq -r ${1}
      }
      class_name=$(_jq '.name')
      class_devices=$(_jq '.devices[]')

      if [[ "$class_devices" == "all" || "$class_devices" == *"$device_name"* ]]; then
        # Check locales for this test class
        class_locales=$(_jq '.locales[]')

        if [[ "$class_locales" == "all" ]]; then
          locales=$(jq -r '.locales[]' $config_file)
        else
          locales=$(echo $test_class | base64 --decode | jq -r '.locales[]')
        fi

        # Combine locales into a comma-separated string
        locale_string=$(echo $locales | tr ' ' ',')

        # Concatenate plan_name and class_name with /
        only_testing_param="$plan_name/$class_name"

        # Construct xcodebuild command
        xcodebuild_cmd="xcodebuild test -scheme EcosiaSnapshotTests -destination \"platform=iOS Simulator,name=$device_name,OS=$os_version\" -testPlan $plan_name -only-testing:$only_testing_param DEVICE_NAME=\"$device_name\" LOCALES=\"$locale_string\" ORIENTATION=\"$orientation\""

        echo "Running command: $xcodebuild_cmd"
        eval $xcodebuild_cmd
      fi
    done
  done
done