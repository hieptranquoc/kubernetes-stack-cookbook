# # encoding: utf-8

# Inspec test for recipe kubernetes-stack::helm

# The Inspec reference, with examples and extensive document

describe command("curl -s https://api.github.com/repos/kubernetes/helm/releases/latest | grep 'tag_name' | cut -d\\\" -f4") do
  its(:exit_status) { should eq 0 }
  its('stdout') { should match /^\s*v[0-9]+.[0-9]+.[0-9]+?$/ }
end

describe command('which helm') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match('/usr/local/bin/helm') }
end

describe command("helm version --short --client | cut -d ':' -f2 | sed 's/[[:space:]]//g' | sed 's/+.*//'") do
  its(:exit_status) { should eq 0 }
  its('stdout') { should match /^\s*v[0-9]+.[0-9]+.[0-9]+?$/ }
end
