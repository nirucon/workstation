#!/bin/bash

# Reminder: This script must be run with root privileges.

# Define the lines to be added
lines=$(cat << 'EOF'
# fstab extra for workstation

#  sda1 500gb
UUID=dde9c8f2-f54d-4267-ae28-9e6153b8ef71 /media/BACKUP btrfs defaults,noatime 0 2
#  sdc1 USB 500GB BACKUP
UUID=08c2ecbb-28a6-4cb3-b2b8-8e7ad554bb4f /media/USB-BACKUP btrfs defaults,noatime 0 2
#  nvme0n1p1 STORAGE
UUID=97629dc1-5c1c-4857-a734-0c79548c30c5 /media/STORAGE btrfs defaults,noatime 0 2
#  nvme1n1p1 MEDIA
UUID=31614e00-2e20-46b1-ace8-2e3deb81b1ba /media/MEDIA btrfs defaults,noatime 0 2
#  sdb1 128GB EXTRA OS
#UUID=3775db72-cc32-485a-a7c7-6bdcc069490a /media/OS2 btrfs defaults,noatime 0 2
EOF
)

# Backup the current fstab
cp /etc/fstab /etc/fstab.bak

# Check if the backup was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to create a backup of /etc/fstab."
  exit 1
fi

echo "Backup of /etc/fstab created successfully at /etc/fstab.bak"

# Append the lines to the fstab
echo "$lines" >> /etc/fstab

# Check if the append operation was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to append lines to /etc/fstab."
  exit 1
fi

echo "Lines appended to /etc/fstab successfully."

# Verify the changes
if tail -n $(echo "$lines" | wc -l) /etc/fstab | grep -F "$lines" > /dev/null; then
  echo "Verification successful: The lines were added correctly to /etc/fstab."
else
  echo "Verification failed: The lines were not added correctly to /etc/fstab."
  exit 1
fi

echo "Done."
