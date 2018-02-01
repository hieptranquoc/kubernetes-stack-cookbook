# frozen_string_literal: true
# This recipe is used for running the `install_kubectl_for_chefspec` tests, it should
# not be used in the other recipes.

kubectl 'install kubectl' do
  version 'v1.9.1'
end
