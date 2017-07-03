#!/bin/bash
set -ev

cd terraform

# Create SSH Tunnel
ssh-keyscan 52.51.228.216 >> ~/.ssh/known_hosts
ssh -f -N -i ~/.ssh/nomad_rsa -L 4646:internal-nomad-consul-internal-1094868142.eu-west-1.elb.amazonaws.com:4646 ubuntu@52.51.228.216 & echo $! > nomad.pid

# Run terraform
TF_VAR_version=$TRAVIS_BUILD_ID terraform plan
TF_VAR_version=$TRAVIS_BUILD_ID terraform apply

# Cleanup
kill $(cat nomad.pid)
rm nomad.pid

