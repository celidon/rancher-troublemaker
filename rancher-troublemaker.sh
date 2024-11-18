#!/bin/bash

MAX_PROBLEM=$(ls -1 ./scripts/problems | wc -l)

#Check for AWS creds
if [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ]; then
  if [ -s aws_creds.env ]; then
    export $(egrep -v "(^#.*|^$)" aws_creds.env | xargs)
  fi  
  if [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ]; then
    echo "Please export your AWS credentials or save them in aws_creds.env"
    exit 1
  fi
fi

#Check for terraform or openTOFU
TFCMD=$(command -v tofu || command -v terraform)
if [ -z $TFCMD ]; then
  echo "Please ensure that OpenTofu or Terraform is installed and in your path"
  exit 1
fi

#Check for Helm and kubectl
if ! command -v kubectl; then
  echo "Please ensure that kubectl is installed and in your path"
  exit 1
fi
if ! command -v kubectl; then
  echo "Please ensure that Helm is installed and in your path"
  exit 1
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
$TFCMD init
$TFCMD apply --auto-approve 

cd ../..

case $problem in
  A)
    echo "Using all problems"
    echo '' > ./check.sh
    for i in $(seq 1 $MAX_PROBLEM); do
      ./scripts/problems/$i.sh
      cat ./scripts/checks/$i.sh >> ./check.sh
    done
    ;;
  [1-$MAX_PROBLEM])
    ./scripts/problems/$problem.sh
    cat ./scripts/checks/$problem.sh > ./check.sh
    ;;
esac

echo "When you believe that you have solved the problem, run ./check.sh to confirm."
echo "When you are done with the lab environment, move to ./tf/aws and run $TFCMD delete to cleanup the resources." 
