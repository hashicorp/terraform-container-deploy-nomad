#!/bin/bash

cd $TRAVIS_BUILD_DIR/terraform
ssh -N -L 4646:internal-nomad-consul-internal-1247221898.eu-west-1.elb.amazonaws.com:4646 ubuntu@34.253.160.6 &
TF_VAR_version=$TRAVIS_BUILD_ID terraform apply
