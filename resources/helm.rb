resource_name :helm

property :version, String, default: ''
property :platform, String, default: ''
property :arch, String, default: ''
property :binary_path, String, default: '/usr/local/bin/helm'

default_action :install

load_current_value do
end

action :install do
    platform_cmd = Mixlib::ShellOut.new('uname')
    platform_cmd.run_command
    platform_cmd.error!
    platform = platform_cmd.stdout.strip
    platform.downcase
    
    arch_cmd = Mixlib::ShellOut.new('uname -m')
    arch_cmd.run_command
    arch_cmd.error!
    arch = arch_cmd.stdout.strip

    case arch
    when "x86", "i686", "i386"
        arch = "386"
    when "x86_64", "aarch64"
        arch = "amd64"
    when "armv5*"
        arch = "armv5"
    when "armv6*"
        arch = "armv6"
    when "armv7*"
        arch = "armv7"
    else
        arch = "default"
    end
    
    bash 'clean up the existing helm' do
        code <<-EOF
        helm_binary=$(which helm);
        if hash helm 2>/dev/null; then
            rm -rf helm_binary || true;
        fi
        EOF
        only_if 'which helm'
    end

    if version.empty?
        execute 'curl get_helm' do
        command 'curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh'
        end

        execute 'chmod get_helm' do
        command 'chmod 700 get_helm.sh'
        end

        execute 'install helm' do
        command './get_helm.sh'
        end
    else
        download_url = "https://storage.googleapis.com/kubernetes-helm/helm-#{version}-#{platform}-#{arch}.tar.gz"

        remote_file binary_path do
        source download_url
        mode '0755'
        not_if { ::File.exist?(binary_path) }
        end
    end
end

action :remove do
    execute 'remove helm' do
        command "rm -rf #{binary_path}"
        only_if 'which helm'
    end
end
