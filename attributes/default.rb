# frozen_string_literal: true
# The MIT License (MIT)
#
# Cookbook:: kubernetes-stack
# Attribute:: default
#
# Copyright:: 2008-2018, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
default['kubernetes-stack']['arch'] = 'amd64'
default['kubernetes-stack']['sys'] = 'linux'
default['kubernetes-stack']['user'] = node['kubernetes-stack']['user'] || 'vagrant'
default['kubernetes-stack']['home'] = "/home/#{node['kubernetes-stack']['user']}"

default['docker_machine']['version'] = 'v0.14.0'
default['docker_machine']['command_path'] = '/usr/local/bin/docker-machine'
