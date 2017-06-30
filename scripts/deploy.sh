#!/bin/bash
set -ev

cd terraform
ssh-keyscan 52.51.228.216 >> ~/.ssh/known_hosts
ssh -N -i ~/.ssh/nomad_rsa -L 4646:internal-nomad-consul-internal-1094868142.eu-west-1.elb.amazonaws.com:4646 ubuntu@52.51.228.216 &
sleep 10
TF_VAR_version=$TRAVIS_BUILD_ID terraform plan
TF_VAR_version=$TRAVIS_BUILD_ID terraform apply
killall ssh
