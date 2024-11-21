#!/bin/bash

MainDir=$(pwd)

#Check for AWS creds
if [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ]; then
  if [ -s $MainDir/aws_creds.env ]; then
    export $(egrep -v "(^#.*|^$)" aws_creds.env | xargs)
  fi
  if [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ]; then
    echo "Please export your AWS credentials or save them in aws_creds.env"
    exit 1
  fi
fi

COUNT=0
echo "Cleaning up resources"

rm -rf $MainDir/check.sh
rm -rf $MainDir/connection_info
rm -rf $MainDir/id_rsa

cd $MainDir/tf/aws
until $TFCMD destroy --auto-approve &> /dev/null; do
  echo "Still cleaning environment..."
  COUNT=$COUNT+1
  if [ $COUNT -eq 10 ]; then
    cd $MainDir
    rm -rf $MainDir/tf/aws/terraform.tfstate
    echo "Cleanup has failed. Please manually remove the resources from AWS"
    exit 1
  fi
done

echo "Cleanup should be now be complete."
