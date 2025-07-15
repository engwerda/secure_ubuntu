# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Test multiple Ubuntu versions
  ubuntu_versions = {
    "ubuntu2004" => "ubuntu/focal64",
    "ubuntu2204" => "ubuntu/jammy64",
    "ubuntu2404" => "ubuntu/noble64"
  }

  ubuntu_versions.each do |name, box|
    config.vm.define name do |node|
      node.vm.box = box
      node.vm.hostname = name

      # VM settings
      node.vm.provider "virtualbox" do |vb|
        vb.memory = "2048"
        vb.cpus = 2
        vb.name = "secure-ubuntu-#{name}"
      end

      # Network configuration
      node.vm.network "private_network", type: "dhcp"

      # Sync the playbook directory
      node.vm.synced_folder ".", "/vagrant", type: "virtualbox"

      # Install Python for Ansible
      node.vm.provision "shell", inline: <<-SHELL
        apt-get update
        apt-get install -y python3 python3-apt
      SHELL

      # Run Ansible playbook
      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "playbook.yml"
        ansible.verbose = "v"
        ansible.extra_vars = {
          user: "vagrant",
          local_key: File.read("#{Dir.home}/.ssh/id_rsa.pub").strip
        }
      end
    end
  end
end
