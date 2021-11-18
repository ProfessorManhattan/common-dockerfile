## Overview

This project houses a Dockerfile and build tools that are meant to create an [Ansible Molecule]({{ website.ansible_molecule_docs }})-compatible image for testing against {{ pretty_name }}. Ansible Molecule testing is an important part of creating Ansible roles. Nearly all of [our Ansible roles]({{ repository.group.ansible_roles }}) support Archlinux, Debian, Fedora, CentOS, Ubuntu, Mac OS X, and Windows. On top of that, we have hundreds of roles to maintain. In order to alleviate the headache that comes with supporting so many operating systems and so many roles, we utilize several test methods which are all powered by Ansible Molecule. We use this project's image to test our Ansible scripts against {{ pretty_name }} using Docker. Although you can use the image that this project creates on any CI platform, we choose to use GitLab CI because it is free. It allows us to spot bugs before the code is available publicly. Setting up GitLab CI with Ansible Molecule and Docker is a great first line of defense when it comes to preventing issues on Linux environments.

For an example of how to use the image that this project creates (and integrate it with GitLab CI), check out the `molecule/` folder and the `.gitlab-ci.yml` file in our [Ansible Studio role](https://gitlab.com/megabyte-labs/ansible-roles/androidstudio). If that interests you then you should check out the [Integrating with Ansible Molecule](#integrating-with-ansible-molecule) section below as well.

**Note: The username and password for this image are both ansible.**