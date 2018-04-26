# frozen_string_literal: true
#
# Cookbook:: kubernetes-stack-test
# Recipe:: docker
#
# Copyright:: 2017, The Authors, All Rights Reserved.

unless docker_installed?
  docker_service 'default' do
    action [:create, :start]
  end

  def install_url
    release = node['docker_machine']['release']
    kernel_name = node['kernel']['name']
    machine_hw_name = node['kernel']['machine']
    "https://github.com/docker/machine/releases/download/#{release}/docker-machine-#{kernel_name}-#{machine_hw_name}"
  end

  command_path = node['docker_machine']['command_path']
  url = install_url

  execute 'install docker-machine' do
    action :run
    command "curl -sSL #{url} > #{command_path} && chmod +x #{command_path}"
    creates command_path
    user 'root'
    group 'docker'
    umask '0027'
  end
end
