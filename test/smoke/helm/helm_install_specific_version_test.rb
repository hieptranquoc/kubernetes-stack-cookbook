# # encoding: utf-8

# Inspec test for recipe kubernetes-stack::helm

# The Inspec reference, with examples and extensive document

describe command("helm version --short --client | cut -d ':' -f2 | sed 's/[[:space:]]//g' | sed 's/+.*//'") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match('v2.4.2') }
end
