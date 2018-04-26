# Release

This is the release note with steps for releasing this project.

Follow: http://dev.teracy.org/docs/release_process.html


## metadata.rb

- Update the version information


## CHANGELOG.md

- Update the changelog file


## Publish to the Chef Supermarket

- Download the ``teracy.pem`` file to the `.chef` directory from
  https://manage.chef.io/organizations/teracyhq/users/teracy

- Then publish the new version of released cookbook with:

  ```bash
  $ cd ~/teracy-dev
  $ vagrant ssh
  $ ws
  $ cd kubernetes-stack-cookbook
  $ knife cookbook site share "kubernetes-stack" "Utilities"
  ```
