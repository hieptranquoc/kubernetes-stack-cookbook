# frozen_string_literal: true
# This recipe is used for running the `install_kubernetes_for_chefspec` tests, it should
# not be used in the other recipes.

minikube 'install minikube' do
  version 'v0.25.2'
end
