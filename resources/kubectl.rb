resource_name :kubectl

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

  Chef::Log.info("kubectl current version : '#{version}'") unless current.nil?

  if current != version

    remove_kubectl unless current.nil?

    get_kubectl_url = "https://storage.googleapis.com/kubernetes-release/release/#{version}/bin/#{sys}/#{arch}/kubectl"

    directory new_resource.path do
      mode 0755
      action :create
      not_if { Dir.exist?(new_resource.path) }
    end

    execute 'download kubectl' do
      user 'root'
      cwd new_resource.path
      command "curl -Lo kubectl #{get_kubectl_url} && chmod +x kubectl"
      action :run
      not_if 'which kubectl'
    end

    ruby_block "check kubectl exist in #{new_resource.path}" do
      block do
        unless ::File.exist?(binary_path)
          Chef::Log.fatal("Could not find kubectl at #{new_resource.path}!")
        end
      end
      action :run
    end

    package 'bash-completion' do
      action :install
      not_if { Dir.exist?('/etc/bash_completion.d') }
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
        Chef::Log.error('kubectl autocomplete has not installed')
      end
      action :run
      not_if { ::File.exist?(kubectl_completion_path) }
    end
  end
end

action :remove do
  remove_kubectl
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
    "#{new_resource.path}/kubectl"
  end

  def kubectl_completion_path
    '/etc/bash_completion.d/kubectl'
  end

  def latest_ver
    cmd = Mixlib::ShellOut.new('curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt')
    cmd.run_command

    ver = cmd.stderr.empty? && !cmd.stdout.empty? ? cmd.stdout.strip : nil

    raise 'kubectl latest version not found' if ver.nil?

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
      only_if 'which kubectl'
    end
  end
end
