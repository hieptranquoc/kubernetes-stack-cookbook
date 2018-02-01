# frozen_string_literal: true
#
# Cookbook:: kubernetes-stack-test
# Recipe:: install
#
# Copyright:: 2017, The Authors, All Rights Reserved.

kubectl_opt = node['kubernetes-stack']['kubectl']

minikube_opt = node['kubernetes-stack']['minikube']

gcloud_opt = node['kubernetes-stack']['gcloud']

helm_opt = node['kubernetes-stack']['helm']

if kubectl_opt['enabled']
  kubectl "install kubectl #{kubectl_opt['version']}" do
    version kubectl_opt['version']
    action :install
  end
end

if gcloud_opt['enabled']
  gcloud "install gcloud #{gcloud_opt['version']}" do
    version gcloud_opt['version']
    action :install
  end
end

if helm_opt['enabled']
  helm "install helm #{helm_opt['version']}" do
    version helm_opt['version']
    action :install
  end
end

if minikube_opt['enabled']
  minikube "install minikube #{minikube_opt['version']}" do
    version minikube_opt['version']
    k8s_version minikube_opt['k8s_version']
    network_plugin minikube_opt['network_plugin']
    bootstrapper minikube_opt['bootstrapper']
    vm_driver minikube_opt['vm_driver']
    action [:install, :run]
  end
end
