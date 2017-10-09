resource_name :gcloud

property :version, String, default: ''
property :binary_path, String, default: '/usr/local/bin/gcloud'

default_action :install

load_current_value do
end

action :install do
  version = latest_version()
  version = new_resource.version unless new_resource.version.empty?
  existing_version = existing_version()

  if existing_version != version
    # Deleting previous version if mismatched
    delete_gcloud(binary_path) unless existing_version.empty?

    install_requirement

    install_path = '/usr/lib'

    install_root_dir = "#{install_path}/google-cloud-sdk"

    if platform?('ubuntu')
      version_avaiable = version_avaiable_in_apt_package(version)
    end

    # Gcloud version will be installed via apt-get
    if version_avaiable
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

        package 'google-cloud-sdk' do
          version "#{version}-0"
        end
      end

      # Link to binary_path
      link_to_path(binary_path, install_root_dir)
      # Disable update notification when run command 'gcloud version'
      disable_update_check(install_root_dir)

    # Gcloud version will be installed via file downloaded
    else
      download_url = "https://storage.googleapis.com/cloud-sdk-release/google-cloud-sdk-#{version}-linux-`uname -m`.tar.gz"

      execute "curl #{download_url} | tar xvz" do
        cwd install_path
        action :run
        not_if 'which gcloud'
      end

      execute './google-cloud-sdk/install.sh --quiet' do
        cwd install_path
        action :run
        only_if "test -d #{install_root_dir}"
      end

      # Link to binary_path
      link_to_path(binary_path, install_root_dir)
      # Disable update notification when run command 'gcloud version'
      disable_update_check(install_root_dir)
      # Install autocomplete
      install_autocomplete(install_root_dir)
    end
  end
end

action :remove do
  delete_gcloud(binary_path)
end

action_class do
  def latest_version
    latest_version_url = "curl -s https://cloud.google.com/sdk/docs/release-notes | grep 'h2' | head -1 | cut -d '>' -f2 | sed 's/[[:space:]].*//'"
    latest_version_cmd = Mixlib::ShellOut.new(latest_version_url)
    latest_version_cmd.run_command

    latest_version = ''
    latest_version = latest_version_cmd.stdout.strip if latest_version_cmd.stderr.empty? && !latest_version_cmd.stdout.empty?
    latest_version
  end

  def existing_version
    existing_version_cmd = Mixlib::ShellOut.new("gcloud version | head -1 | grep -o -E '[0-9].*'")
    existing_version_cmd.run_command

    existing_version = ''
    existing_version = existing_version_cmd.stdout.strip if existing_version_cmd.stderr.empty? && !existing_version_cmd.stdout.empty?
    existing_version
  end

  def version_avaiable_in_apt_package(version)
    version_avaiable_cmd = Mixlib::ShellOut.new("curl -s https://packages.cloud.google.com/apt/dists/cloud-sdk-$(lsb_release -c -s)/main/binary-amd64/Packages | grep 'google-cloud-sdk_#{version}'")
    version_avaiable_cmd.run_command

    version_avaiable = false
    version_avaiable = true if version_avaiable_cmd.stderr.empty? && !version_avaiable_cmd.stdout.empty?
    version_avaiable
  end

  def link_to_path(binary_path, install_root_dir)
    link binary_path do
      to "#{install_root_dir}/bin/gcloud"
      only_if "test -f #{install_root_dir}/bin/gcloud"
    end

    # Add gsutil to ENV_PATH
    link '/usr/local/bin/gsutil' do
      to "#{install_root_dir}/bin/gsutil"
      only_if "test -f #{install_root_dir}/bin/gsutil"
    end

    # Add bq command to ENV_PATH
    link '/usr/local/bin/bq' do
      to "#{install_root_dir}/bin/bq"
      only_if "test -f #{install_root_dir}/bin/bq"
    end
  end

  def disable_update_check(install_root_dir)
    # Disable update notification when run command 'gcloud version'
    execute 'disable update check' do
      command 'gcloud config set --installation component_manager/disable_update_check true'
    end

    # Update file config.json
    execute 'update gcloud file config' do
      command "sed -i -- 's/\"disable_updater\": false/\"disable_updater\": true/g' #{install_root_dir}/lib/googlecloudsdk/core/config.json"
    end
  end

  def install_requirement
    case node[:platform]
    when 'ubuntu'
      package %w(bash-completion python python-pip apt-transport-https)
    when 'centos'
      package %w(bash-completion python)
      execute 'download pip' do
        command "curl 'https://bootstrap.pypa.io/get-pip.py' -o 'get-pip.py'"
      end

      execute 'install pip' do
        command 'python get-pip.py'
      end
    end

    execute 'install crc-mod' do
      command 'pip install -U crcmod'
    end
  end

  def install_autocomplete(install_root_dir)
    remote_file 'install autocomplete' do
      path '/etc/bash_completion.d/gcloud'
      source "file://#{install_root_dir}/completion.bash.inc"
      mode '0755'
    end

    link '/etc/bash_completion.d/gcloud' do
      to "#{install_root_dir}/completion.bash.inc"
      mode '0755'
    end
  end

  def delete_gcloud(binary_path)
    if platform?('ubuntu')
      execute 'to complete remove gcloud' do
        command 'apt-get purge --auto-remove -y google-cloud-sdk'
        action :run
      end
    end

    file 'cleanup_binany_path' do
      path binary_path
      action :delete
      only_if 'which gcloud'
    end

    directory 'cleanup_config_path' do
      path '~/.config/gcloud'
      recursive true
      action :delete
      only_if 'test -d ~/.config/gcloud'
    end

    directory 'cleanup_install_root_dir' do
      path '/usr/lib/google-cloud-sdk'
      recursive true
      action :delete
      only_if 'test -d /usr/lib/google-cloud-sdk'
    end

    file 'cleanup_completion_path' do
      path '/etc/bash_completion.d/gcloud'
      action :delete
      only_if 'test -f /etc/bash_completion.d/gcloud'
    end
  end
end
