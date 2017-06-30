#!/bin/bash

cd terraform
ssh-keyscan 52.215.48.30 >> ~/.ssh/known_hosts
ssh -N -i ~/.ssh/nomad_rsa -L 4646:internal-nomad-consul-internal-902604809.eu-west-1.elb.amazonaws.com:4646 ubuntu@52.215.48.30 &
sleep 10
TF_VAR_version=$TRAVIS_BUILD_ID terraform plan
TF_VAR_version=$TRAVIS_BUILD_ID terraform apply
