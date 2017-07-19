#
# Cookbook:: kubernetes-stack
# Spec:: helm
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

describe 'kubernetes-stack-test::helm_install_default' do
  context 'When all attributes are default, on ubuntu 16.04' do

    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: 'helm', platform: 'ubuntu', version: '16.04').converge(described_recipe) }
    
    before do
      stub_command("which helm").and_return(true)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'install helm' do
      expect(chef_run).to install_helm('install helm')
    end
  end

  context 'When all attributes are default, on centos 7.3' do

    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: 'helm', platform: 'centos', version: '7.3.1611').converge(described_recipe) }
    
    before do
      stub_command("which helm").and_return(true)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'install helm' do
      expect(chef_run).to install_helm('install helm')
    end
  end
end