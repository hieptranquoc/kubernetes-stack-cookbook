# This recipe is used for running the `install_gcloud_for_chefspec` tests, it should
# not be used in the other recipes.

gcloud 'install latest gcloud'

gcloud 'install specific gcloud version' do
  version '158.0.0'
end
