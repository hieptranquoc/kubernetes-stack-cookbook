# frozen_string_literal: true
# encoding: utf-8

# Inspec test for recipe kubernetes-stack::minikube

# The Inspec reference, with examples and extensive document

describe command('curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt') do
  its(:exit_status) { should eq 0 }
  its('stdout') { should match /^\s*v[0-9]+.[0-9]+.[0-9]+?$/ }
end

describe command('which minikube') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match('/usr/local/bin/minikube') }
end

describe command("minikube version | cut -d ' ' -f3") do
  its(:exit_status) { should eq 0 }
end

describe command('minikube').exist? do
  it { should eq true }
end

describe command("kubectl version --short --client | cut -d ':' -f2") do
  its(:exit_status) { should eq 0 }
  its('stdout') { should match /^\s*v[0-9]+.[0-9]+.[0-9]+?$/ }
end

describe command('kubectl').exist? do
  it { should eq true }
end

describe command('which docker') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match('/usr/bin/docker') }
end

describe command('grep vagrant /etc/passwd') do
  its(:exit_status) { should eq 0 }
end

describe file('/home/vagrant/.kube/config') do
  it { should exist }
end

describe command('which kubeadm') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match('/usr/bin/kubeadm') }
end

describe command('which kubelet') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match('/usr/bin/kubelet') }
end
