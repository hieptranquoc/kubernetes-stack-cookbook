# frozen_string_literal: true
resource_name :kubectl

property :version, String, default: ''
property :path, String, default: '/usr/local/bin'

default_action :install

load_current_value do
end

action :install do
  version = new_resource.version
  version = latest_ver if new_resource.version.empty?

  log "kubectl install version = '#{version}'" do
    level :info
  end

  current = current_ver

  log "kubectl current version = '#{current}'" do
    level :info
  end

  if current != version

    remove_kubectl unless current.nil?

    get_kubectl_url = "https://storage.googleapis.com/kubernetes-release/release/#{version}/bin/#{sys}/#{arch}/kubectl"

    log "kubectl will be downloaded at #{get_kubectl_url}" do
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

    execute 'download kubectl' do
      user 'root'
      cwd new_resource.path
      command "curl -Lo kubectl #{get_kubectl_url} && chmod +x kubectl"
      action :run
      not_if 'which kubectl'
    end

    ruby_block 'check kubectl' do
      block do
        if ::File.exist?(binary_path)
          log "kubectl has installed at #{binary_path}!" do
            level :info
          end
        else
          log "Could not find kubectl at #{binary_path}!" do
            level :error
          end
          raise
        end
      end
      action :run
    end

    package 'bash-completion' do
      action :install
      notifies :write, 'log[install bash-completion]', :immediately
      not_if { Dir.exist?('/etc/bash_completion.d') }
    end

    log 'install bash-completion' do
      level :info
      action :nothing
    end

    # Install kubectl autocomplete
    execute 'install kubectl bash completion' do
      command "kubectl completion bash > #{kubectl_completion_path}"
      creates kubectl_completion_path
      user 'root'
      action :run
      only_if 'which kubectl'
    end

    ruby_block 'check kubectl autocompletion' do
      block do
        if ::File.exist?(kubectl_completion_path)
          log 'kubectl autocomplete has installed' do
            level :info
          end
        else
          log 'kubectl autocomplete has not installed' do
            level :error
          end
        end
      end
      action :run
    end
  else
    log 'no need to install new kubectl version' do
      level :info
    end
  end
end

action :remove do
  remove_kubectl
end

action_class do
  def arch
    node['kubernetes-stack']['arch']
  end

  def sys
    node['kubernetes-stack']['sys']
  end

  def binary_path
    "#{new_resource.path}/kubectl"
  end

  def kubectl_completion_path
    '/etc/bash_completion.d/kubectl'
  end

  def latest_ver
    cmd = Mixlib::ShellOut.new('curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt')
    cmd.run_command
    cmd.error!

    ver = cmd.stdout.strip
    ver
  end

  def current_ver
    cmd = Mixlib::ShellOut.new("kubectl version --short --client | cut -d ':' -f2")
    cmd.run_command

    ver = cmd.stderr.empty? && !cmd.stdout.empty? ? cmd.stdout.strip : nil
    ver
  end

  def remove_kubectl
    bash 'remove kubectl' do
      user 'root'
      code <<-EOH
        kubectl_binary=$(which kubectl);
        rm -rf $kubectl_binary
        rm -rf #{kubectl_completion_path}
        EOH
      notifies :write, 'log[kubectl has deleted successfull]', :immediately
      notifies :write, 'log[kubectl-autocompletion has deleted successfull]', :immediately
      only_if 'which kubectl'
    end

    log 'kubectl has deleted successfull' do
      level :info
      action :nothing
    end

    log 'kubectl-autocompletion has deleted successfull' do
      level :info
      action :nothing
    end
  end
end
