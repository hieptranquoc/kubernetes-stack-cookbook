# frozen_string_literal: true
resource_name :minikube

property :version, String, default: ''
property :path, String, default: '/usr/local/bin'
property :k8s_version, String, default: ''
property :network_plugin, String, default: ''
property :bootstrapper, String, default: ''
property :vm_driver, String, default: 'none'

default_action :install

load_current_value do
end

action :install do
  version = new_resource.version
  version = latest_ver if new_resource.version.empty?

  log "minikube install version = '#{version}'" do
    level :info
  end

  current = current_ver

  log "minikube current version : '#{current}'" do
    level :info
  end

  if current != version

    remove_minikube unless current.nil?

    get_minikube_url = "https://storage.googleapis.com/minikube/releases/#{version}/minikube-#{sys}-#{arch}"

    log "minikube will be downloaded at #{get_minikube_url}" do
      level :info
    end

    directory new_resource.path do
      mode 0755
      action :create
      notifies :write, "log[create #{new_resource.path} directory]", :immediately
      not_if { Dir.exist?(new_resource.path) }
    end

    log "create #{new_resource.path} directory" do
      level :info
      action :nothing
    end

    execute 'get minikube' do
      cwd new_resource.path
      command "curl -Lo minikube #{get_minikube_url} && chmod +x minikube"
      action :run
      not_if 'which minikube'
    end

    ruby_block 'check minikube' do
      block do
        if ::File.exist?(binary_path)
          log "minikube has installed at #{binary_path}!" do
            level :info
          end
        else
          log "Could not find minikube at #{binary_path}!" do
            level :error
          end
          raise
        end
      end
      action :run
    end
  else
    log 'no need to install new minikube version' do
      level :info
    end
  end
end

action :run do
  user = node['kubernetes-stack']['user']

  log "user : #{user}" do
    level :info
  end

  user_home = node['kubernetes-stack']['home']

  log "home dir : #{user_home}" do
    level :info
  end

  user user do
    comment 'create kubernetes-stack-cookbook user'
    uid '1000'
    home user_home
    manage_home true
    system true
    not_if { user_exist?(user) }
  end

  ruby_block "check #{user} exist" do
    block do
      if user_exist?(user)
        log "user_name: #{user} exist" do
          level :info
        end
      else
        log "user_name: #{user} has not exist" do
          level :error
        end
        raise 'user not found'
      end
    end
    action :run
  end

  unless sudo_installed?
    package 'sudo' do
      action :install
      notifies :write, 'log[package sudo has been installed]', :immediately
    end

    log 'package sudo has been installed' do
      level :info
      action :nothing
    end
  end

  execute 'set sudo command without passwd' do
    user 'root'
    command "echo '#{user} ALL=(ALL) NOPASSWD:SETENV:ALL' >> /etc/sudoers.d/#{user}_cmd"
    only_if 'which sudo'
  end

  if docker_installed?
    log 'docker has exist' do
      level :info
    end

    group 'docker' do
      action :modify
      members user
      append true
    end
  else
    log 'docker has not exist' do
      level :error
    end
  end

  package 'ebtables'
  package 'ethtool'

  log "minikube start command: #{start_command}" do
    level :info
  end

  bash 'run minikube' do
    user user
    environment(
      'USER' => user,
      'HOME' => user_home
    )
    code <<-EOF
      export MINIKUBE_WANTUPDATENOTIFICATION=false
      export MINIKUBE_WANTREPORTERRORPROMPT=fasle
      export CHANGE_MINIKUBE_NONE_USER=true
      export MINIKUBE_HOME=$HOME

      mkdir -p $HOME/.kube || true
      touch $HOME/.kube/config

      export KUBECONFIG=$HOME/.kube/config

      #{start_command}
      EOF
  end
end

action :remove do
  remove_minikube
end

action_class do
  include KubernetesStackCookbook::Helpers

  def arch
    node['kubernetes-stack']['arch']
  end

  def sys
    node['kubernetes-stack']['sys']
  end

  def binary_path
    "#{new_resource.path}/minikube"
  end

  def latest_ver
    cmd = Mixlib::ShellOut.new("curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | grep 'tag_name' | cut -d\\\" -f4")
    cmd.run_command
    cmd.error!

    ver = cmd.stdout.strip
    ver
  end

  def current_ver
    cmd = Mixlib::ShellOut.new("minikube version | cut -d ' ' -f3")
    cmd.run_command

    ver = cmd.stderr.empty? && !cmd.stdout.empty? ? cmd.stdout.strip : nil
    ver
  end

  def start_command
    cmd = "sudo -E #{binary_path} start"
    cmd += " --vm-driver=#{new_resource.vm_driver}" unless new_resource.vm_driver.empty?
    cmd += " --bootstrapper=#{new_resource.bootstrapper}" unless new_resource.bootstrapper.empty?
    cmd += " --network-plugin=#{new_resource.network_plugin}" unless new_resource.network_plugin.empty?
    cmd += " --kubernetes-version=#{new_resource.k8s_version}" unless new_resource.k8s_version.empty?
    cmd
  end

  def remove_minikube
    bash 'remove minikube' do
      code <<-EOH
        minikube delete
        minikube_binary=$(which minikube);
        rm -rf $minikube_binary
        rm -rf $HOME/.minikube
        EOH
      notifies :write, 'log[minikube has deleted successfull]', :immediately
      only_if 'which minikube'
    end

    log 'minikube has deleted successfull' do
      level :info
      action :nothing
    end

    service '*kubelet*.mount' do
      notifies :write, 'log[kubelet has stopped]', :immediately
      action :stop
    end

    log 'kubelet has stopped' do
      level :info
      action :nothing
    end

    execute 'remove k8s docker images' do
      command 'docker rm -f $(docker ps -aq --filter name=k8s)'
      notifies :write, 'log[k8s image has removed]', :immediately
      action :run
      only_if 'which docker'
    end

    log 'k8s image has removed' do
      level :info
      action :nothing
    end
  end
end
