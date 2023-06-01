#!/bin/bash

bool_values=("$@")
strings=("SharedTests" "StorageTests" "ClientTests")

result=""

for i in "${!bool_values[@]}"; do
    if [[ "${bool_values[$i]}" == "true" ]]; then
        if [[ -z "$result" ]]; then
            result="${strings[$i]}"
        else
            result+=",""${strings[$i]}"
        fi
    fi
done

echo "$result"