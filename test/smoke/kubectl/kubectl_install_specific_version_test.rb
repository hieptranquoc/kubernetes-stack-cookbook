# # encoding: utf-8

# Inspec test for recipe kubernetes-stack::kubectl

# The Inspec reference, with examples and extensive document

describe command("kubectl version --short --client | cut -d ':' -f2") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match('v1.7.0') }
end
