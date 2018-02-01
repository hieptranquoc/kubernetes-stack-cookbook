# frozen_string_literal: true
module KubernetesStackCookbook
  module Helpers
    include Chef::Mixin::ShellOut

    # Determines if sudo is installed on a system.
    #
    # @return [Boolean]
    def sudo_installed?
      !which('sudo').nil?
    end

    # Determines if docker is installed on a system.
    #
    # @return [Boolean]
    def docker_installed?
      !which('docker').nil?
    end

    # Determines if user has in system.
    #
    # @return [Boolean]
    def user_exist?(user_name)
      cmd = shell_out!("getent passwd #{user_name}", returns: [0, 2])
      cmd.stderr.empty? && (cmd.stdout =~ /^#{user_name}/)
    end

    # Determines if bash-completion is installed on a system.
    #
    # @return [Boolean]
    def bash_completion_installed?
      !which('bash-completion').nil?
    end

    # Finds a command in $PATH
    #
    # @return [String, nil]
    def which(cmd)
      paths = (ENV['PATH'].split(::File::PATH_SEPARATOR) + %w(/bin /usr/bin /sbin /usr/sbin))

      paths.each do |path|
        possible = File.join(path, cmd)
        return possible if File.executable?(possible)
      end

      nil
    end
  end
end

Chef::Recipe.send(:include, ::KubernetesStackCookbook::Helpers)
