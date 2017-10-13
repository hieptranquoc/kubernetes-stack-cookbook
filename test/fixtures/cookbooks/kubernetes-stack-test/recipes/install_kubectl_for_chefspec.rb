# This recipe is used for running the `install_kubectl_for_chefspec` tests, it should
# not be used in the other recipes.

kubectl 'install latest kubectl'

kubectl 'install specific kubectl version' do
  version 'v1.7.0'
end
