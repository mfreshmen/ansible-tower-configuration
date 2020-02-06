#!/usr/bin/env bash

echo "tower_openshift_project: '"$TOWER_OPENSHIFT_PROJECT"'" >> e2e_test_config.yml
echo "tower_openshift_password: '"$TOWER_OPENSHIFT_PASSWORD"'" >> e2e_test_config.yml
echo "tower_openshift_username: '"$TOWER_OPENSHIFT_USERNAME"'" >> e2e_test_config.yml
echo "tower_openshift_master_url: '"$OPENSHIFT_MASTER"'" >> e2e_test_config.yml

if [ -f /.dockerenv ]; then
    echo "tempuser:x:$(id -u):$(id -g):,,,:${HOME}:/bin/bash" >> /etc/passwd
    echo "tempuser:x:$(id -G | cut -d' ' -f 2)" >> /etc/group
fi

echo "Installing tower on openshift: ${TOWER_OPENSHIFT_PROJECT}"
ansible-playbook -i ./inventories/hosts \
playbooks/install_tower.yml \
--extra-vars "@e2e_test_config.yml"
install_exit_code=$?
echo "Install playbook ansible exit code: $install_exit_code"

#Pass environment variables to config file
echo "e2e_tower_license: '"$TOWER_LICENSE"'" >> e2e_test_config.yml
echo "e2e_tower_password: '"$TOWER_PASSWORD"'" >> e2e_test_config.yml
echo "e2e_tower_username: '"$TOWER_USERNAME"'" >> e2e_test_config.yml

echo "Bootstrapping tower in openshift project: ${TOWER_OPENSHIFT_PROJECT}"
ansible-playbook -i ./inventories/hosts \
playbooks/bootstrap.yml \
--extra-vars "@e2e_test_config.yml"
bootstrap_exit_code=$?
echo "Bootstrap playbook ansible exit code: $bootstrap_exit_code"


oc delete project ${TOWER_OPENSHIFT_PROJECT}
exit_code=`expr $install_exit_code + $bootstrap_exit_code`
exit $exit_code