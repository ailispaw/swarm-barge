# A dummy plugin for Barge to set hostname and network correctly at the very first `vagrant up`
module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "change_host_name") { Cap::ChangeHostName }
      guest_capability("linux", "configure_networks") { Cap::ConfigureNetworks }
    end
  end
end

NUM_NODES    = 3
BASE_IP_ADDR = "192.168.65"

Vagrant.configure(2) do |config|
  config.vm.box = "ailispaw/barge"
  config.vm.box_version = ">= 2.1.4"

  config.vm.provision :shell do |sh|
    sh.inline = <<-EOT
      /etc/init.d/docker restart v1.12.0-rc2
    EOT
  end

  config.vm.define "node-01", primary: true do |node|
    node.vm.hostname = "node-01"

    node.vm.network :private_network, ip: "#{BASE_IP_ADDR}.101"

    node.vm.provision :shell do |sh|
      sh.inline = <<-EOT
        docker swarm init --listen-addr "#{BASE_IP_ADDR}.101:2377"
      EOT
    end
  end

  (2..NUM_NODES).each do |i|
    config.vm.define vm_name = "node-%02d" % i do |node|
      node.vm.hostname = vm_name

      node.vm.network :private_network, ip: "#{BASE_IP_ADDR}.#{100+i}"

      node.vm.provision :shell do |sh|
        sh.inline = <<-EOT
          docker swarm join "#{BASE_IP_ADDR}.101:2377"
        EOT
      end
    end
  end
end
