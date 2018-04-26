# frozen_string_literal: true
resource_name :gcloud

property :version, String, default: ''
property :path, String, default: '/usr/local/bin'

default_action :install

load_current_value do
end

action :install do
  version = new_resource.version
  version = latest_ver if new_resource.version.empty?

  Chef::Log.info("gcloud install version = '#{version}'")

  current = current_ver

  Chef::Log.info("gcloud current version = '#{current}'")

  if current != version
    # Deleting previous version if mismatched
    delete_gcloud unless current.nil?

    directory new_resource.path do
      action :create
      not_if { Dir.exist?(new_resource.path) }
      mode 0755
      notifies :write, "log[create #{new_resource.path} directory]", :immediately
    end

    log "create #{new_resource.path} directory" do
      level :info
      action :nothing
    end

    install_requirement

    if platform?('ubuntu')
      version_avaiable = version_avaiable_in_apt_package(version)

      version = latest_ver unless version_avaiable

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

      apt_package 'google-cloud-sdk' do
        version "#{version}-0"
        action :install
      end
    elsif platform?('centos')
      version_avaiable = version_avaiable_in_yum_package(version)

      version = latest_ver unless version_avaiable

      yum_repository 'google-cloud-sdk' do
        description 'google-cloud-sdk'
        baseurl 'https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64'
        enabled true
        gpgcheck true
        repo_gpgcheck true
        gpgkey [
          'https://packages.cloud.google.com/yum/doc/yum-key.gpg',
          'https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg',
        ]
      end

      yum_package 'google-cloud-sdk' do
        version version
        action :install
      end
    else
      raise 'platform not support'
    end

    gcloud_dir = gcloud_installation_dir

    log "installation root dir : #{gcloud_dir}" do
      level :info
      not_if { gcloud_dir.empty? }
    end

    %w(gcloud gsutil bq).each do |gc|
      link "#{new_resource.path}/#{gc}" do
        to "#{gcloud_dir}/bin/#{gc}"
      end
    end

    # Disable update notification when run command 'gcloud version'
    execute 'disable update check' do
      command 'gcloud config set --installation component_manager/disable_update_check true'
    end

    # Update file config.json
    execute 'update gcloud file config' do
      command "sed -i -- 's/\"disable_updater\": false/\"disable_updater\": true/g' #{gcloud_dir}/lib/googlecloudsdk/core/config.json"
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

    remote_file 'install autocomplete' do
      path '/etc/bash_completion.d/gcloud'
      source "file://#{gcloud_dir}/completion.bash.inc"
      mode '0755'
    end

    link gcloud_completion_path do
      to "#{gcloud_dir}/completion.bash.inc"
      mode '0755'
    end

    ruby_block 'check gcloud autocompletion' do
      block do
        if ::File.exist?(gcloud_completion_path)
          log 'gcloud autocomplete has installed' do
            level :info
          end
        else
          log 'gcloud autocomplete has not installed' do
            level :error
          end
        end
      end
      action :run
    end
  else
    log 'no need to install new gcloud version' do
      level :info
    end
  end
end

action :remove do
  delete_gcloud
end

action_class do
  def sys
    node['kubernetes-stack']['sys']
  end

  def binary_path
    "#{new_resource.path}/gcloud"
  end

  def gcloud_installation_dir
    return '/usr/lib64/google-cloud-sdk' if node['platform'] == 'centos'
    '/usr/lib/google-cloud-sdk'
  end

  def gcloud_completion_path
    '/etc/bash_completion.d/gcloud'
  end

  def latest_ver
    cmd = Mixlib::ShellOut.new("curl -s https://cloud.google.com/sdk/docs/release-notes | grep 'h2' | head -1 | cut -d '>' -f2 | sed 's/[[:space:]].*//'")
    cmd.run_command

    ver = cmd.stderr.empty? && !cmd.stdout.empty? ? cmd.stdout.strip : nil
    ver
  end

  def current_ver
    cmd = Mixlib::ShellOut.new("gcloud version | head -1 | grep -o -E '[0-9].*'")
    cmd.run_command

    ver = cmd.stderr.empty? && !cmd.stdout.empty? ? cmd.stdout.strip : nil
    ver
  end

  def version_avaiable_in_apt_package(version)
    cmd = Mixlib::ShellOut.new("curl -s https://packages.cloud.google.com/apt/dists/cloud-sdk-$(lsb_release -c -s)/main/binary-amd64/Packages | grep 'google-cloud-sdk_#{version}'")
    cmd.run_command

    version_avaiable = cmd.stderr.empty? && !cmd.stdout.empty? ? true : false
    version_avaiable
  end

  def version_avaiable_in_yum_package(version)
    cmd = Mixlib::ShellOut.new("curl -s https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64/repodata/other.xml | grep 'google-cloud-sdk_#{version}'")
    cmd.run_command

    version_avaiable = cmd.stderr.empty? && !cmd.stdout.empty? ? true : false
    version_avaiable
  end

  def install_requirement
    if platform?('ubuntu')
      package %w(gcc python-dev python-setuptools python-pip lsb-release apt-transport-https openssh-client)
    end

    if platform?('centos')
      package %w(gcc python python-setuptools)

      remote_file 'get python pip' do
        path "#{Chef::Config[:file_cache_path]}/get-pip.py"
        source 'https://bootstrap.pypa.io/get-pip.py'
        mode '0755'
        action :create
      end

      execute 'install pip' do
        cwd Chef::Config[:file_cache_path]
        command 'python get-pip.py'
        action :run
      end
    end

    execute 'install crc-mod' do
      cwd '/tmp'
      command 'pip install -U crcmod'
      action :run
    end
  end

  def delete_gcloud
    bash 'remove config directory' do
      user 'root'
      code <<-EOH
        config_dir=$(gcloud info --format='value(config.paths.global_config_dir)');
        rm -rf $config_dir
        EOH
      notifies :write, 'log[config directory has deleted successfull]', :immediately
      only_if 'which gcloud'
    end

    log 'config directory has deleted successfull' do
      level :info
      action :nothing
    end

    bash 'remove installation directory' do
      user 'root'
      code <<-EOH
        installation_dir=$(gcloud info --format='value(installation.sdk_root)');
        rm -rf $installation_dir
        EOH
      notifies :write, 'log[installation directory has deleted successfull]', :immediately
      only_if 'which gcloud'
    end

    log 'installation directory has deleted successfull' do
      level :info
      action :nothing
    end

    %w(gcloud gsutil bq).each do |gc|
      bash "remove #{gc} binary path" do
        user 'root'
        code <<-EOH
          #{gc}_binary=$(which #{gc});
          rm -rf $#{gc}_binary
          EOH
        notifies :write, "log[#{gc} has deleted successfull]", :immediately
        only_if { ::File.exist?("#{new_resource.path}/#{gc}") }
      end

      log "#{gc} has deleted successfull" do
        level :info
        action :nothing
      end
    end

    file gcloud_completion_path do
      path '/etc/bash_completion.d/gcloud'
      action :delete
      only_if 'test -f /etc/bash_completion.d/gcloud'
    end
  end
end
