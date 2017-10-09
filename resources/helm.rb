resource_name :helm

property :version, String, default: ''
property :binary_path, String, default: '/usr/local/bin/helm'

default_action :install

load_current_value do
end

action :install do
  version = new_resource.version

  arch_cmd = Mixlib::ShellOut.new('uname -m')
  arch_cmd.run_command
  arch_cmd.error!
  arch = arch_cmd.stdout.strip

  case arch
  when 'x86', 'i686', 'i386'
    arch = '386'
  when 'x86_64', 'aarch64'
    arch = 'amd64'
  when 'armv5*'
    arch = 'armv5'
  when 'armv6*'
    arch = 'armv6'
  when 'armv7*'
    arch = 'armv7'
  else
    arch = 'default'
  end

  if version.empty?
    latest_version_url = "curl -s https://api.github.com/repos/kubernetes/helm/releases/latest | grep 'tag_name' | cut -d\\\" -f4"
    latest_version_cmd = Mixlib::ShellOut.new(latest_version_url)
    latest_version_cmd.run_command
    latest_version_cmd.error!
    version = latest_version_cmd.stdout.strip
  end

  # Command to check if we should be installing helm or not.
  existing_version_cmd = Mixlib::ShellOut.new("helm version --short --client | cut -d ':' -f2 | sed 's/[[:space:]]//g' | sed 's/+.*//'")
  existing_version_cmd.run_command

  if existing_version_cmd.stderr.empty? && !existing_version_cmd.stdout.empty?
    existing_version = existing_version_cmd.stdout.strip
  end

  if existing_version.to_s != version.to_s
    bash 'clean up the mismatched helm version' do
      code <<-EOF
        helm_binary=$(which helm);
        rm -rf $helm_binary
        EOF
      only_if 'which helm'
    end

    download_url = "https://storage.googleapis.com/kubernetes-helm/helm-#{version}-linux-#{arch}.tar.gz"

    bash 'install helm' do
      code <<-EOH
        curl #{download_url} | tar -xvz
        mv linux-#{arch}/helm #{binary_path}
        EOH
    end

    package 'bash-completion'

    # Delete helm autocomplete if existing
    execute 'delete helm autocomplete' do
      action :run
      command 'rm -rf /etc/bash_completion.d/helm'
      user 'root'
      only_if 'test -f /etc/bash_completion.d/helm'
    end

    # Install helm autocomplete
    execute 'install helm autocomplete' do
      action :run
      command 'helm completion bash > /etc/bash_completion.d/helm'
      creates '/etc/bash_completion.d/helm'
      user 'root'
    end
  end
end

action :remove do
  execute 'remove helm' do
    command "rm -rf #{binary_path}"
    only_if 'which helm'
  end
end
