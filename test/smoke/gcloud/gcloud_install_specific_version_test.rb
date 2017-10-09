# # encoding: utf-8

# Inspec test for recipe kubernetes-stack::gcloud

# The Inspec reference, with examples and extensive document

describe command("gcloud version | head -1 | grep -o -E '[0-9].*'") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match('158.0.0') }
end
