#!/bin/bash

# Prepare
apt-get update -y
apt-get upgrade -y

# Download and install Puppet for Debian (Jessie)
wget https://apt.puppetlabs.com/puppetlabs-release-jessie.deb
dpkg -i puppetlabs-release-jessie.deb
apt-get update -y
apt-get -y install puppet
rm puppetlabs-release-jessie.deb

# Finish
{ sleep 1; reboot -f; } >/dev/null &
