# # encoding: utf-8

# Inspec test for recipe kubernetes-stack::kubectl

# The Inspec reference, with examples and extensive document

describe command('curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt') do
  its(:exit_status) { should eq 0 }
  its('stdout') { should match /^\s*v[0-9]+.[0-9]+.[0-9]+?$/ }
end

describe command('which kubectl') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match('/usr/local/bin/kubectl') }
end

describe command("kubectl version --short --client | cut -d ':' -f2") do
  its(:exit_status) { should eq 0 }
  its('stdout') { should match /^\s*v[0-9]+.[0-9]+.[0-9]+?$/ }
end
