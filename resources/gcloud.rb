resource_name :gcloud

property :version, String, default: ''
property :platform, String, default: ''
property :arch, String, default: ''
property :gcloud_path, String, default: '/usr/bin/gcloud'
property :gcloud_repo, String, default: '/etc/yum.repos.d/google-cloud-sdk.repo'

default_action :install

load_current_value do
end

action :install do
  # TODO(hoatle): support more platform, support specified version installation
  platform_cmd = Mixlib::ShellOut.new('uname')
  platform_cmd.run_command
  platform_cmd.error!
  platform = platform_cmd.stdout.strip
  platform.downcase
  
  arch_cmd = Mixlib::ShellOut.new('uname -m')
  arch_cmd.run_command
  arch_cmd.error!
  arch = arch_cmd.stdout.strip

  # existing_version=$(gcloud version | head -1 | grep -o -E '[0-9].*');
  bash 'clean up the existing gcloud' do
    code <<-EOF
      gcloud_binary=$(which gcloud);
      if hash gcloud 2>/dev/null; then
        rm -rf gcloud_binary || true;
      fi
    EOF
    only_if 'which gcloud'
  end

  # for ubuntu-16.04 platform
  if platform?('ubuntu')
    execute 'import google-cloud-sdk public key' do
      command 'curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -'
    end

    apt_repository 'google-cloud-sdk' do
      uri          'http://packages.cloud.google.com/apt'
      distribution "cloud-sdk-#{node['lsb']['codename']}"
      components   ['main']
      # key 'A7317B0F'
      # keyserver 'packages.cloud.google.com/apt/doc/apt-key.gpg'
    end

    if version.empty?
      package 'google-cloud-sdk'
    else
      # execute 'install gcloud' do
      #   command 'curl #{download_url} | sudo tar xvz'
      # end

      download_url = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-#{version}-#{platform}-#{arch}.tar.gz"

      remote_file gcloud_path do
        source download_url
        mode '0755'
        not_if { ::File.exist?(gcloud_path) }
      end
    end
  end

  # for centos-7 platform
  if platform?('centos')
    bash 'clean up the existing gcloud configuration file' do
      code <<-EOF
        if [ -f "#{gcloud_repo}" ]; then
          sudo rm -rf #{gcloud_repo} || true;
        else
          vi #{gcloud_repo}
        fi
      EOF
    end

    yum_repository 'google-cloud-sdk' do
      repositoryid "google-cloud-sdk"
      baseurl "https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-#{arch}"
      enabled true
      gpgcheck true
      repo_gpgcheck true
      gpgkey 'https://packages.cloud.google.com/yum/doc/yum-key.gpg
              https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg'
    end
            
    if version.empty?
      yum_package 'google-cloud-sdk'
    else

      download_url = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-#{version}-#{platform}-#{arch}.tar.gz"

      remote_file gcloud_path do
        source download_url
        mode '0755'
        not_if { ::File.exist?(gcloud_path) }
      end
    end
  end
end

action :remove do
  package 'google-cloud-sdk' do
    action :remove
  end
end
