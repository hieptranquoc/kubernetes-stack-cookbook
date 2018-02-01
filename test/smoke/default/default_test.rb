# frozen_string_literal: true
# encoding: utf-8

# Inspec test for recipe kubernetes-stack::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

unless os.windows?
  describe user('root') do
    it { should exist }
  end
end
