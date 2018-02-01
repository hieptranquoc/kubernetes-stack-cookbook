resource_name :helm

property :version, String, default: ''
property :path, String, default: '/usr/local/bin'

default_action :install

load_current_value do
end

action :install do
  version = new_resource.version
  version = latest_ver if new_resource.version.empty?

  raise 'version is nil' if version.nil?

  current = current_ver

  Chef::Log.info("helm current version : '#{version}'") unless current.nil?

  if current != version

    remove_helm unless current.nil?

    get_helm_url = "https://storage.googleapis.com/kubernetes-helm/helm-#{version}-#{sys}-#{arch}.tar.gz"

    execute 'get helm' do
      user 'root'
      cwd '/tmp'
      command "curl #{get_helm_url} | tar -zxv"
      action :run
    end

    file_extract_path = "/tmp/linux-#{arch}/helm"

    ruby_block "check helm exist in #{file_extract_path}" do
      block do
        Chef::Log.fatal("Could not find helm at #{file_extract_path}!")
      end
      action :run
      not_if { ::File.exist?(file_extract_path) }
    end

    directory new_resource.path do
      mode 0755
      action :create
      not_if { Dir.exist?(new_resource.path) }
    end

    remote_file "move file to #{new_resource.path}" do
      path binary_path
      source "file://#{file_extract_path}"
      mode '0755'
    end

    ruby_block "check helm exist in #{new_resource.path}" do
      block do
        if ::File.exist?(binary_path)
          file file_extract_path do
            action :delete
            only_if { ::File.exist?(file_extract_path) }
          end
        else
          Chef::Log.fatal("Could not find helm at #{new_resource.path}!")
        end
      end
      action :run
    end

    package 'bash-completion' do
      action :install
      not_if { Dir.exist?('/etc/bash_completion.d') }
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
        Chef::Log.error('kubectl autocomplete has not installed')
      end
      action :run
      not_if { ::File.exist?(helm_completion_path) }
    end
  end
end

action :remove do
  remove_helm
end

action_class do
  def arch
    return 'amd64' if node['kernel']['machine'].include?('x86_64')
    raise "Architecture #{node['kernel']['machine']} has not supported" unless node['kernel']['machine'].include?('x86_64')
  end

  def sys
    return 'linux' if node['kernel']['os'].include?('Linux')
    raise "OS platform #{node['kernel']['os']} has not supported" unless node['kernel']['os'].include?('Linux')
  end

  def binary_path
    "#{new_resource.path}/helm"
  end

  def latest_ver
    cmd = Mixlib::ShellOut.new("curl -s https://api.github.com/repos/kubernetes/helm/releases/latest | grep 'tag_name' | cut -d\\\" -f4")
    cmd.run_command

    ver = cmd.stderr.empty? && !cmd.stdout.empty? ? cmd.stdout.strip : nil

    raise 'helm latest version not found' if ver.nil?

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
      only_if 'which helm'
    end
  end
end
