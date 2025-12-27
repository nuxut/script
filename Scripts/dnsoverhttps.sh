#!/bin/bash

set -e 

echo "Initializing dns over https"
sleep 3

sudo pacman -S --noconfirm --needed dns-over-https
PORT_CHECK=$(sudo ss -lp 'sport = :domain' | awk 'NR>1 {print $7}')

if [ -n "$PORT_CHECK" ]; then
  echo "Services using port 53 found:"
  echo "$PORT_CHECK" | while read -r LINE; do
    PID=$(echo "$LINE" | sed -E 's/.*pid=([0-9]+),.*/\1/')
    SERVICE=$(echo "$LINE" | sed -E 's/.*\(\(\"([^\"]+)\".*/\1/')
    if [ -n "$PID" ]; then
      echo "Stopping service running with PID $PID."
      if [ -n "$SERVICE" ]; then
        echo "$SERVICE found as systemd service, stopping and disabling with systemctl."
        sudo systemctl stop "$SERVICE" 2>/dev/null
        sudo systemctl disable "$SERVICE" 2>/dev/null
        if [ $? -eq 0 ]; then
          echo "$SERVICE service successfully stopped and disabled."
        else
          echo "$SERVICE service could not be stopped with systemctl. Manual check may be required."
        fi
      fi
      sudo kill -9 "$PID"
      if [ $? -eq 0 ]; then
        echo "PID $PID successfully stopped."
      else
        echo "PID $PID could not be stopped. You may need to check manually."
      fi
    else
      echo "Could not retrieve PID. You may need to check manually."
    fi
  done
else
  echo "No service using port 53 found. You can continue."
fi

echo "Resetting DNS..."
sudo truncate -s 0 /etc/resolv.conf

echo "Connecting DNS address to localhost..."
sudo echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf > /dev/null

sudo chattr +i /etc/resolv.conf
echo "Configuring cloudflare settings for dns-over-https..."
sleep 1

sudo mkdir -p /etc/dns-over-https/
sudo cp ./Assets/doh-client.conf /etc/dns-over-https/doh-client.conf
sudo chmod 644 /etc/dns-over-https/doh-client.conf
sudo chown root:root /etc/dns-over-https/doh-client.conf
sudo systemctl enable --now doh-client.service


echo "DNS-over-HTTPS is initialized..."
sleep 2
