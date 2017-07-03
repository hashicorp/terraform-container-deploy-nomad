#!/bin/bash
set -ev

cd terraform

# Run terraform
TF_VAR_version=$TRAVIS_BUILD_ID terraform plan
TF_VAR_version=$TRAVIS_BUILD_ID terraform apply
