#!/usr/bin/env bash
#
# Templated environment script for configuring your own AWS/Ansible environment.
#
# The first argument to the script specifies the AWS_ACCESS_KEY_ID, the second the AWS_SECRET_ACCESS_KEY and the third
# is the AWS_REGION.
#

echo export ANSIBLE_HOSTS=/etc/ansible/ec2.py
echo export EC2_INI_PATH=/etc/ansible/ec2.ini

echo export AWS_ACCESS_KEY_ID=$1
echo export AWS_SECRET_ACCESS_KEY=$2
echo export AWS_REGION=$3
