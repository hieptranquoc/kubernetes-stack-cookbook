# frozen_string_literal: true
#
# Cookbook:: kubernetes-stack
# Spec:: minikube
#
# The MIT License (MIT)
#
# Copyright:: 2017, Teracy Corporation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'spec_helper'

describe 'kubernetes-stack-test::install_minikube_for_chefspec' do
  context 'Install on ubuntu 16.04' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(
        step_into: 'minikube',
        platform: 'ubuntu',
        version: '16.04'
      ).converge(described_recipe)
    end

    before do
      stub_command('which kubectl').and_return('/usr/local/bin/kubectl')
      stub_command('which minikube').and_return('/usr/local/bin/minikube')
      stub_command('which docker').and_return('/usr/bin/docker')
      stub_command('which sudo').and_return('/usr/bin/sudo')
      stub_command('grep vagrant /etc/passwd').and_return(true)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'install minikube' do
      expect(chef_run).to install_minikube('install minikube')
    end
  end

  context 'Install on centos 7' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(
        step_into: 'minikube',
        platform: 'centos',
        version: '7.3.1611'
      ).converge(described_recipe)
    end

    before do
      stub_command('which kubectl').and_return('/usr/local/bin/kubectl')
      stub_command('which minikube').and_return('/usr/local/bin/minikube')
      stub_command('which docker').and_return('/usr/bin/docker')
      stub_command('which sudo').and_return('/usr/bin/sudo')
      stub_command('grep vagrant /etc/passwd').and_return(true)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'install minikube' do
      expect(chef_run).to install_minikube('install minikube')
    end
  end
end
