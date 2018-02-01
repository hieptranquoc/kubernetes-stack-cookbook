#
# Cookbook:: kubernetes-stack-test
# Recipe:: docker
#
# Copyright:: 2017, The Authors, All Rights Reserved.

unless docker_installed?
  if platform?('ubuntu')
    docker_service 'default' do
      action [:create, :start]
    end

    def install_url
      release = node['docker_machine']['release']
      kernel_name = node['kernel']['name']
      machine_hw_name = node['kernel']['machine']
      "https://github.com/docker/machine/releases/download/#{release}/docker-machine-#{kernel_name}-#{machine_hw_name}"
    end

    command_path = "#{node['docker_machine']['command_path']}/docker-machine"
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

  if platform?('centos')
    docker_service 'default' do
      install_method 'package'
      storage_driver 'overlay2'
      storage_opts ['overlay2.override_kernel_check=true']
      action [:create, :start]
    end

    def install_url
      release = node['docker_machine']['release']
      kernel_name = node['kernel']['name']
      machine_hw_name = node['kernel']['machine']
      "https://github.com/docker/machine/releases/download/#{release}/docker-machine-#{kernel_name}-#{machine_hw_name}"
    end

    command_path = "#{node['docker_machine']['command_path']}/docker-machine"
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
end
