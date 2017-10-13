# # encoding: utf-8

# Inspec test for recipe kubernetes-stack::gcloud

# The Inspec reference, with examples and extensive document

describe command('which python') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match('/usr/bin/python') }
end

describe command("curl -s https://cloud.google.com/sdk/docs/release-notes | grep 'h2' | head -1 | cut -d '>' -f2 | sed 's/[[:space:]].*//'") do
  its(:exit_status) { should eq 0 }
end

describe command('which gcloud') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match('/usr/local/bin/gcloud') }
end

describe command("gcloud version | head -1 | grep -o -E '[0-9].*'") do
  its(:exit_status) { should eq 0 }
  its('stdout') { should match /^\s*[0-9]+.[0-9]+.[0-9]+?$/ }
end
