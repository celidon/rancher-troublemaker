# Troublemaker for Rancher

Create an intentionally broken Rancher environment in AWS to practive troubleshootingcommon issues.

This tool creates a single node Rancher cluster on k3s and a downstream custom RKE2 cluster.

Once the clusters and Rancher are online, a script will run to break the cluster and provide a short summary of the issue and required login information.

Once you have completed troubleshooting and correcting the issue, please run the check.sh script generated to confirm your results.
