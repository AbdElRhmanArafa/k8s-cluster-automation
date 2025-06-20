# k8s-cluster-automation

This repository contains the code to automate the creation of a Kubernetes cluster on local machine  using Ansible.

## Prerequisites

- Ansible
- Vagrant
- libvirt

## Steps to create a Kubernetes cluster

1. Clone the repository
2. Run the following command to create 2 VMs using Vagrant

```bash
cd vagrant
vagrant up
```
3. Run the following command to setup ssh keys on the VMs and Inventory file

```bash
chmod +x setup_ssh_keys.sh
./setup_ssh_keys.sh
```
4. Run the following command to install Kubernetes on the VMs

```bash
ansible-playbook  site.yml
```
5. Run the following command to check the status of the cluster

```bash
cd vagrant
vagrant ssh node1
kubectl get nodes
```

## File Descriptions

### Vagrantfile
The Vagrantfile is used to create and configure the virtual machines. It defines two VMs with different memory and CPU configurations and provisions them using a shell script.

### bootstrap.sh
The bootstrap.sh script is used to set up the VMs. It creates a user, sets up passwordless sudo, enables SSH password authentication, and installs Python.

### setup_ssh_keys.sh
The setup_ssh_keys.sh script installs the `expect` package if it is not already installed, ensures that an SSH key exists, and copies the SSH key to the VMs. It also creates an Ansible inventory file.

### site.yml
The site.yml file is the main Ansible playbook that sets up the Kubernetes cluster. It includes tasks for both master and worker nodes.

### roles/kubernetes_cluster/tasks/master.yml
This file contains the tasks for setting up the master node, including initializing the Kubernetes cluster and setting up the kubeconfig file.

### roles/kubernetes_cluster/tasks/worker.yml
This file contains the tasks for setting up the worker nodes, including joining them to the Kubernetes cluster.

### roles/kubernetes_cluster/vars/main.yml
This file defines the `ansible_user` variable, which is used throughout the playbook.

### roles/kubernetes_cluster/handlers/main.yml
This file contains handlers for reloading and restarting systemd services.

### roles/kubernetes_cluster/tasks/main.yml
This file contains the main tasks for setting up the Kubernetes cluster, including installing containerd, setting up the Kubernetes repository, and installing Kubernetes components.

## Feature Enhancements

### 1. Dynamic Node Scaling
Implement a feature to dynamically scale the number of worker nodes in the cluster. This can be achieved by modifying the Vagrantfile and Ansible playbooks to accept a variable number of nodes.

### 2. Make Ansible Roles More Flexible
Refactor the Ansible roles to make them more flexible and reusable. This can be done by parameterizing the roles and using variables to define the configuration.

### 3. Add Monitoring and Logging
Integrate monitoring and logging solutions such as Prometheus and Grafana to monitor the cluster's health and performance. This can provide valuable insights into the cluster's operation and help identify and troubleshoot issues.

### 4. Use Terraform for Infrastructure Provisioning
Use Terraform to provision the infrastructure (VMs) instead of Vagrant. This can provide more flexibility and scalability in managing the cluster's resources.

### 6. Add password in Secret file or environment variable
