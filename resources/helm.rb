# frozen_string_literal: true
resource_name :helm

property :version, String, default: ''
property :path, String, default: '/usr/local/bin'

default_action :install

load_current_value do
end

action :install do
  version = new_resource.version
  version = latest_ver if new_resource.version.empty?

  log "helm install version = '#{version}'" do
    level :info
  end

  current = current_ver

  log "helm current version = '#{current}'" do
    level :info
  end

  if current != version

    remove_helm unless current.nil?

    get_helm_url = "https://storage.googleapis.com/kubernetes-helm/helm-#{version}-#{sys}-#{arch}.tar.gz"

    log "helm chart will be downloaded at #{get_helm_url}" do
      level :info
    end

    execute 'get helm' do
      user 'root'
      cwd '/tmp'
      command "curl #{get_helm_url} | tar -zxv"
      action :run
    end

    file_extract_path = "/tmp/linux-#{arch}/helm"

    ruby_block "check helm exist in #{file_extract_path}" do
      block do
        if ::File.exist?(file_extract_path)
          log 'helm has downloaded' do
            level :info
          end
        else
          log "Could not find helm at #{file_extract_path}!" do
            level :error
          end
          raise
        end
      end
      action :run
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

    remote_file "move file to #{new_resource.path}" do
      path binary_path
      source "file://#{file_extract_path}"
      mode '0755'
    end

    ruby_block "check helm exist in #{new_resource.path}" do
      block do
        if ::File.exist?(binary_path)
          log "helm has installed at #{new_resource.path}!" do
            level :info
          end

          file file_extract_path do
            action :delete
            only_if { ::File.exist?(file_extract_path) }
          end
        else
          log "Could not find helm at #{new_resource.path}!" do
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

    # Install helm autocomplete
    execute 'install helm bash completion' do
      user 'root'
      command "helm completion bash > #{helm_completion_path}"
      creates helm_completion_path
      action :run
      only_if { ::File.exist?(binary_path) }
    end

    ruby_block 'check helm autocompletion' do
      block do
        if ::File.exist?(helm_completion_path)
          log 'helm autocomplete has installed' do
            level :info
          end
        else
          log 'helm autocomplete has not installed' do
            level :error
          end
        end
      end
      action :run
    end
  else
    log 'no need to install new helm version' do
      level :info
    end
  end
end

action :remove do
  remove_helm
end

action_class do
  def arch
    node['kubernetes-stack']['arch']
  end

  def sys
    node['kubernetes-stack']['sys']
  end

  def binary_path
    "#{new_resource.path}/helm"
  end

  def latest_ver
    cmd = Mixlib::ShellOut.new("curl -s https://api.github.com/repos/kubernetes/helm/releases/latest | grep 'tag_name' | cut -d\\\" -f4")
    cmd.run_command
    cmd.error!

    ver = cmd.stdout.strip
    ver
  end

  def current_ver
    cmd = Mixlib::ShellOut.new("helm version --short --client | cut -d ':' -f2 | sed 's/[[:space:]]//g' | sed 's/+.*//'")
    cmd.run_command

    ver = cmd.stderr.empty? && !cmd.stdout.empty? ? cmd.stdout.strip : nil
    ver
  end

  def helm_completion_path
    '/etc/bash_completion.d/helm'
  end

  def remove_helm
    bash 'remove helm' do
      user 'root'
      code <<-EOH
        helm_binary=$(which helm);
        rm -rf $helm_binary
        rm -rf #{helm_completion_path}
        EOH
      notifies :write, 'log[helm has deleted successfull]', :immediately
      notifies :write, 'log[helm-autocompletion has deleted successfull]', :immediately
      only_if 'which helm'
    end

    log 'helm has deleted successfull' do
      level :info
      action :nothing
    end

    log 'helm-autocompletion has deleted successfull' do
      level :info
      action :nothing
    end
  end
end
