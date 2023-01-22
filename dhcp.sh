#!/bin/bash

# Get list of devices and their IP addresses
devices=$(ip addr show)

# Print list of devices and their IP addresses in numerical order
echo "List of devices:"
counter=1
echo "$devices" | awk '$1 == "inet" {print NR, $NF, $2}' | while read -r num interface address; do
  echo "$counter. $interface : $address"
  counter=$((counter + 1))
done

# Get the number of devices
num_devices=$(echo "$devices" | awk '$1 == "inet" {print NR}' | wc -l)

# Prompt user to select a device
while true; do
  read -p "Select a device by number: " device_num
  if ! [[ "$device_num" =~ ^[0-9]+$ ]]; then
    echo "Invalid input: Please enter a number."
  elif [ "$device_num" -lt 1 ]; then
    echo "Invalid input: Please enter a number greater than 0."
  elif [ "$device_num" -gt "$num_devices" ]; then
    echo "Invalid input: Please enter a number within the range of available devices."
  else
    break
  fi
done

# Get the selected device name
selected_device=$(echo "$devices" | awk '$1 == "inet" {print NR, $NF, $2}' | awk -v devnum="$device_num" 'NR==devnum{print $2}')

# Check if device exists
if [ -z "$selected_device" ]; then
  echo "Device does not exist"
  exit
fi

# Print selected device
echo "Selected device: $selected_device trying to renew DHCP lease..."

# Renew DHCP lease
if [ -n "$selected_device" ]; then
  dhclient -r $selected_device && sleep 5 && dhclient $selected_device
  if [ $? -eq 0 ]; then
    # Print current IP address of the selected device
    retries=3
    while [ $retries -gt 0 ]; do
      current_ip=$(ip addr show $selected_device | grep -Po 'inet \K[\d.]+')
      if [ -n "$current_ip" ]; then
        echo "Current IP address of the selected device: $current_ip"
        break
      fi
      echo "Retrying to obtain IP address for $selected_device..."
      sleep 2
      retries=$((retries - 1))
    done
    if [ -z "$current_ip" ]; then
      echo "Error: Failed to obtain IP address for $selected_device after multiple retries"
    fi
  else
    echo "Error: Failed to renew DHCP lease for $selected_device"
  fi
else
  echo "Error: Invalid input. Please enter a number within the range of available devices."
fi
