#!/bin/bash

### Problem Block ###

##Problem Template##
#problem1 () {
#  #Problem decription
#  echo "Issue 1" 
#
#}
#

problem1 () {
  #Problem decription
  echo "Issue 1" 

}

problem2 () {
  #Problem decription
  echo "Issue 2" 

}

problem3 () {
  #Problem decription
  echo "Issue 3" 

}

problem4 () {
  #Problem decription
  echo "Issue 4" 

}

problem5 () {
  #Problem decription
  echo "Issue 5" 

}

### End Problem Block ###

MAX_PROBLEM=5

#Check for AWS creds
#if [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ]; then
#  if [ -s aws_creds.env ]; then
#    export $(egrep -v "(^#.*|^$)" aws_creds.env | xargs)
#  fi  
#  if [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ]; then
#    echo "Please export your AWS credentials or save them in aws_creds.env"
#    exit 1
#  fi
#fi

#Check for terraform or openTOFU
TFCMD=$(command -v tofu || command -v terraform)
if [ -z $TFCMD ]; then
  echo "Please ensure that OpenTofu or Terraform is installed and in your path"
  exit
fi

USAGE=$(cat <<EOF

 Usage: $0 [arguments]

 Arguments:
   -r         Random Problem
   -A         All Problems
   -[N]       Problem Number N (N must be between 1 and $MAX_PROBLEM)


EOF
)

problem=$(echo $1 | tr -d -)

#Check for valid arguments

if [ ! -z $2 ]; then
  echo "Too many arguments"
  echo "$USAGE"
  exit 1
elif [[ $# -eq 0 ]] || [ $1 == "-r" ]; then
  echo "Selecting random problem"
  problem=$(( $RANDOM % $MAX_PROBLEM + 1 ))
elif [ $1 == "-h" ]; then
  echo "$USAGE"
  exit
elif ( [ $problem != "A" ] && [[ ! "$problem" =~ ^[0-9]+$ ]] ) || ( [[ "$problem" =~ ^[0-9]+$ ]] && ( [ $problem -lt 1 ] || [ $problem -gt $MAX_PROBLEM ] ) ); then
    echo "Please select a valid problem option"
    echo "$USAGE"
    exit 1
fi

echo "Building lab environment" 
cd ./tf/aws
$TFCMD apply 

case $problem in
  A)
    echo "Using all problems"
    for i in $(seq 1 $MAX_PROBLEM); do
      problem$i
    done
    ;;
  [1-$MAX_PROBLEM])
    problem$problem
    ;;
esac
