# # encoding: utf-8

# Inspec test for recipe kubernetes-stack::gcloud

# The Inspec reference, with examples and extensive document

describe command('which gcloud') do
  its(:exit_status) { should eq 1 }
end
