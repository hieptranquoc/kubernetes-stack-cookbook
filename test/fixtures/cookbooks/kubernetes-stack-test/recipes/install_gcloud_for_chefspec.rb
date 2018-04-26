# frozen_string_literal: true
# This recipe is used for running the `install_gcloud_for_chefspec` tests, it should
# not be used in the other recipes.

gcloud 'install gcloud' do
  version '197.0.0'
end
