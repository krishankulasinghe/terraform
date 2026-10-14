#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get -o Acquire::Retries=5 update
apt-get -o Acquire::Retries=5 install -y apache2 curl

# Get the Azure VM name using Azure Instance Metadata Service
VM_NAME=$(curl --fail --silent --noproxy '*' -H Metadata:true 'http://169.254.169.254/metadata/instance/compute/name?api-version=2021-02-01&format=text')

# The private Blob container is a separate storage exercise; this page needs no credentials.

# Create a simple HTML file with the portfolio content and display the images
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>My Portfolio</title>
  <style>
    /* Add animation and styling for the text */
    @keyframes colorChange {
      0% { color: red; }
      50% { color: green; }
      100% { color: blue; }
    }
    h1 {
      animation: colorChange 2s infinite;
    }
  </style>
</head>
<body>
  <h1>Terraform Project Server 1</h1>
  <h2>Azure VM: <span style="color:green">$VM_NAME</span></h2>
  <p>Welcome to Abhishek Veeramalla's Channel</p>
  
</body>
</html>
EOF

# Start Apache and enable it on boot
systemctl start apache2
systemctl enable apache2
