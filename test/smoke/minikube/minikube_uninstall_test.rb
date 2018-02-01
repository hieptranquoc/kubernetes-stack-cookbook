# frozen_string_literal: true
# encoding: utf-8

# Inspec test for recipe kubernetes-stack::minikube

# The Inspec reference, with examples and extensive document

describe command('which minikube') do
  its(:exit_status) { should eq 1 }
end
