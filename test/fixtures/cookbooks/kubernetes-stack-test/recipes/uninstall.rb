#
# Cookbook:: kubernetes-stack-test
# Recipe:: uninstall
#
# Copyright:: 2017, The Authors, All Rights Reserved.

include_recipe 'kubernetes-stack-test::install'

gcloud 'uninstall gcloud' do
  action :remove
end

kubectl 'uninstall kubectl' do
  action :remove
end

helm 'uninstall helm' do
  action :remove
end
