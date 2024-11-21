#!/bin/bash

MainDir=$(pwd)
grep -rl 'MainDir=' $MainDir/scripts | xargs sed -i "s|MainDir=.*$|MainDir=$MainDir|"

MAX_PROBLEM=$(ls -1 $MainDir/scripts/problems | wc -l)

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
if ! command -v kubectl &>/dev/null; then
  echo "Please ensure that kubectl is installed and in your path"
  exit 1
fi
if ! command -v helm &> /dev/null; then
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

echo "Building lab environment. This might take some time."
cd $MainDir/tf/aws
$TFCMD init >/dev/null
until $TFCMD apply --auto-approve &> /dev/null; do
  echo "Still building environment..."
done
$TFCMD output > $MainDir/connection_info

cd $MainDir
echo "Initial Rancher Password: mwCHPvFr3xeT" >> $MainDir/connection_info
echo "SSH Key: $MainDir/id_rsa" >> $MainDir/connection_info
cp $MainDir/tf/aws/id_rsa $MainDir/

case $problem in
  A)
    echo "Using all problems"
    echo '' > $MainDir/check.sh
    for i in $(seq 1 $MAX_PROBLEM); do
      $MainDir/scripts/problems/$i.sh
      cat $MainDir/scripts/checks/$i.sh >> $MainDir/check.sh
      echo
    done
    ;;
  [1-$MAX_PROBLEM])
    $MainDir/scripts/problems/$problem.sh
    cat $MainDir/scripts/checks/$problem.sh > ./check.sh
    echo
    ;;
esac

echo -e "$GREENALL CHECKS PASSED $NC" >> $MainDir/check.sh

echo "Connection information (URLs, IPs, Keys) is stored in $MainDir/connection_info"
echo "When you believe that you have solved the problem, run $MainDir/check.sh to confirm."
echo "When you are done with the lab environment, move to $MainDir/tf/aws and run $TFCMD delete to cleanup the resources or manually remove them from AWS" 
