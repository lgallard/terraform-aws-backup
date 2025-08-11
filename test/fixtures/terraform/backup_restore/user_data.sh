#!/bin/bash

# User data script to initialize test data on EC2 instance
# This script creates test data that can be validated after restoration

# Update system
yum update -y

# Install AWS CLI
yum install -y aws-cli

# Create test data directory
mkdir -p /opt/test-data

# Create test files with known content
echo "Test data created at $(date)" > /opt/test-data/test-file-1.txt
echo "Backup restore test scenario" > /opt/test-data/test-file-2.txt
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)" > /opt/test-data/instance-metadata.txt

# Create a test database file
cat > /opt/test-data/test-data.json << EOF
{
  "test_scenario": "backup-restore",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "instance_id": "$(curl -s http://169.254.169.254/latest/meta-data/instance-id)",
  "availability_zone": "$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)",
  "test_files": [
    "/opt/test-data/test-file-1.txt",
    "/opt/test-data/test-file-2.txt",
    "/opt/test-data/instance-metadata.txt"
  ]
}
EOF

# Set permissions
chmod -R 644 /opt/test-data/*

# Create a log file for verification
echo "Test data initialization completed at $(date)" > /var/log/test-data-init.log

# Format and mount the attached EBS volume if present
if [ -b /dev/xvdf ]; then
    # Wait for volume to be available
    sleep 30

    # Format the volume
    mkfs.ext4 /dev/xvdf

    # Create mount point
    mkdir -p /mnt/test-data

    # Mount the volume
    mount /dev/xvdf /mnt/test-data

    # Create test data on the volume
    mkdir -p /mnt/test-data/backup-test
    echo "EBS volume test data created at $(date)" > /mnt/test-data/backup-test/ebs-test-file.txt
    echo "Volume mount test successful" > /mnt/test-data/backup-test/mount-test.txt

    # Add to fstab for persistent mounting
    echo "/dev/xvdf /mnt/test-data ext4 defaults 0 2" >> /etc/fstab

    # Log success
    echo "EBS volume setup completed at $(date)" >> /var/log/test-data-init.log
fi

# Create a systemd service to validate data integrity on boot
cat > /etc/systemd/system/test-data-validator.service << EOF
[Unit]
Description=Test Data Validator Service
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/test-data/validate-data.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Create the validation script
cat > /opt/test-data/validate-data.sh << 'EOF'
#!/bin/bash

# Validation script to check data integrity after restoration
VALIDATION_LOG="/var/log/test-data-validation.log"

echo "Starting data validation at $(date)" > $VALIDATION_LOG

# Check if test files exist
if [ -f "/opt/test-data/test-file-1.txt" ] && [ -f "/opt/test-data/test-file-2.txt" ]; then
    echo "✓ Test files found" >> $VALIDATION_LOG
else
    echo "✗ Test files missing" >> $VALIDATION_LOG
fi

# Check if EBS volume data exists
if [ -f "/mnt/test-data/backup-test/ebs-test-file.txt" ]; then
    echo "✓ EBS volume data found" >> $VALIDATION_LOG
else
    echo "✗ EBS volume data missing" >> $VALIDATION_LOG
fi

# Check if JSON data is valid
if [ -f "/opt/test-data/test-data.json" ] && python3 -m json.tool /opt/test-data/test-data.json > /dev/null 2>&1; then
    echo "✓ JSON data is valid" >> $VALIDATION_LOG
else
    echo "✗ JSON data is invalid or missing" >> $VALIDATION_LOG
fi

echo "Data validation completed at $(date)" >> $VALIDATION_LOG
EOF

# Make validation script executable
chmod +x /opt/test-data/validate-data.sh

# Enable the validation service
systemctl enable test-data-validator.service

# Signal completion
echo "User data script completed successfully at $(date)" >> /var/log/test-data-init.log
