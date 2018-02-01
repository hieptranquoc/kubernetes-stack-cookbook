resource_name :minikube

property :version, String, default: ''
property :path, String, default: '/usr/local/bin'
property :k8s_version, String, default: ''
property :network_plugin, String, default: ''
property :bootstrapper, String, default: ''
property :vm_driver, String, default: 'none'
property :user_name, String, default: ''

default_action :install

load_current_value do
end

action :install do
  version = new_resource.version
  version = latest_ver if new_resource.version.empty?

  raise 'version is nil' if version.nil?

  current = current_ver

  if current != version

    remove_minikube unless current.nil?

    get_minikube_url = "https://storage.googleapis.com/minikube/releases/#{version}/minikube-#{sys}-#{arch}"

    directory new_resource.path do
      mode 0755
      action :create
      not_if { Dir.exist?(new_resource.path) }
    end

    execute 'get minikube' do
      cwd new_resource.path
      command "curl -Lo minikube #{get_minikube_url} && chmod +x minikube"
      action :run
      not_if 'which minikube'
    end

    ruby_block "check minikube exist in #{new_resource.path}" do
      block do
        unless ::File.exist?(binary_path)
          Chef::Log.fatal("Could not find minikube at #{new_resource.path}!")
        end
      end
      action :run
    end
  end
end

action :run do
  raise 'User not be set' if user_name.empty?

  user user_name do
    comment 'create kubernetes-stack-cookbook user'
    uid '1000'
    home user_home
    shell '/bin/bash'
    system true
    notifies :run, 'ruby_block[add user to docker group]', :immediately
    notifies :reload, 'ohai[reload passwd]', :immediately
    not_if { user_exist?(user_name) }
  end

  ruby_block 'add user to docker group' do
    block do
      if docker_installed?
        group 'docker' do
          action :modify
          members user_name
          append true
        end
      else
        Chef::Log.error('Docker has not installed')
      end
    end
    action :nothing
  end

  ohai 'reload passwd' do
    action :nothing
    plugin 'etc'
  end

  ruby_block "check #{user_name} exist" do
    block do
      unless user_exist?(user_name)
        Chef::Log.error("User : #{user_name} not found")
      end
    end
    action :run
  end

  package 'sudo' do
    action :install
    not_if { sudo_installed? }
  end

  execute 'set sudo command without passwd' do
    user 'root'
    command "echo '#{user_name} ALL=(ALL) NOPASSWD:SETENV:ALL' >> /etc/sudoers.d/#{user_name}_cmd"
    not_if { ::File.exist?("/etc/sudoers.d/#{user_name}_cmd") }
  end

  unless minikube_running
    package 'ebtables'
    package 'ethtool'

    bash 'create minikube home config' do
      user user_name
      environment(
        'HOME' => user_home,
        'USER' => user_name
      )
      code <<-EOH
      sudo mkdir -p $HOME/.kube || true
      sudo touch $HOME/.kube/config
      EOH
      action :run
    end

    file '/etc/profile.d/minikube.sh' do
      content <<-EOH
      export MINIKUBE_WANTUPDATENOTIFICATION='false'
      export MINIKUBE_WANTREPORTERRORPROMPT='false'
      export CHANGE_MINIKUBE_NONE_USER='true'
      export MINIKUBE_HOME="#{user_home}"
      export KUBECONFIG="#{user_home}/.kube/config"
      EOH
      owner 'root'
      group 'root'
      mode '0755'
      action :create
      not_if { ::File.exist?('/etc/profile.d/minikube.sh') }
    end

    execute 'run minikube' do
      environment(
        'MINIKUBE_WANTUPDATENOTIFICATION' => 'false',
        'MINIKUBE_WANTREPORTERRORPROMPT' => 'false',
        'CHANGE_MINIKUBE_NONE_USER' => 'true',
        'MINIKUBE_HOME' => user_home,
        'KUBECONFIG' => "#{user_home}/.kube/config"
      )
      command "su - #{user_name} -c '#{start_command}'"
      action :run
    end

    bash 'access kubectl to api server' do
      user user_name
      environment(
        'HOME' => user_home,
        'USER' => user_name
      )
      code <<-EOH
      for i in {1..150}; do # timeout for 5 minutes
        kubectl get po &> /dev/null
        if [ $? -ne 1 ]; then
          break
        fi
        sleep 2
      done
      EOH
      action :run
      only_if 'which kubectl'
    end
  end
end

action :remove do
  remove_minikube
end

action_class do
  include KubernetesStackCookbook::Helpers

  def arch
    return 'amd64' if node['kernel']['machine'].include?('x86_64')
    raise "Architecture #{node['kernel']['machine']} has not supported" unless node['kernel']['machine'].include?('x86_64')
  end

  def sys
    return 'linux' if node['kernel']['os'].include?('Linux')
    raise "OS platform #{node['kernel']['os']} has not supported" unless node['kernel']['os'].include?('Linux')
  end

  def binary_path
    "#{new_resource.path}/minikube"
  end

  def user_name
    new_resource.user_name
  end

  def user_home
    "/home/#{user_name}"
  end

  def latest_ver
    cmd = Mixlib::ShellOut.new("curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | grep 'tag_name' | cut -d\\\" -f4")
    cmd.run_command

    ver = cmd.stderr.empty? && !cmd.stdout.empty? ? cmd.stdout.strip : nil

    raise 'minikube latest version not found' if ver.nil?

    ver
  end

  def current_ver
    cmd = Mixlib::ShellOut.new("minikube version | cut -d ' ' -f3")
    cmd.run_command

    ver = cmd.stderr.empty? && !cmd.stdout.empty? ? cmd.stdout.strip : nil
    ver
  end

  def minikube_running
    cmd = Mixlib::ShellOut.new("su - #{user_name} -c 'minikube status' | head -1 | grep 'Running'")
    cmd.run_command

    minikube_running = cmd.stderr.empty? && !cmd.stdout.empty? ? true : false
    minikube_running
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
    if minikube_running
      execute 'delete minikube cluster' do
        command "su - #{user_name} -c 'minikube delete'"
        action :run
      end
    end

    bash 'remove minikube' do
      code <<-EOH
        minikube_binary=$(which minikube);
        rm -rf $minikube_binary
        EOH
      only_if 'which minikube'
    end

    service '*kubelet*.mount' do
      action :stop
    end

    execute 'remove k8s docker images' do
      command 'docker rm -f $(docker ps -aq --filter name=k8s)'
      action :run
      only_if 'which docker'
    end
  end
end
