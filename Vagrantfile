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

  config.vm.synced_folder ".", "/vagrant"

  if Vagrant.has_plugin?("vagrant-triggers") then
    config.trigger.before [:up, :resume] do
      info "Get SwarmKit"
      run <<-EOT
        sh -c "[ -d swarmkit ] || git clone https://github.com/docker/swarmkit.git"
      EOT
    end
  end

  config.vm.provision :shell do |sh|
    sh.privileged = false
    sh.inline = <<-EOT
      if [ ! -f /vagrant/swarmkit/bin/swarmd ]; then
        docker pull golang:1.6
        docker run --rm -v /vagrant/swarmkit:/go/src/github.com/docker/swarmkit -w /go/src/github.com/docker/swarmkit golang:1.6 make binaries
      fi
      mkdir -p /tmp/swarm
    EOT
  end

  config.vm.provision :docker do |docker|
    docker.pull_images "ailispaw/barge"
    docker.build_image "/vagrant", args: "-t ailispaw/swarmd"
  end

  config.vm.define "node-01", primary: true do |node|
    node.vm.hostname = "node-01"

    node.vm.network :private_network, ip: "#{BASE_IP_ADDR}.101"

    node.vm.provision :docker do |docker|
      docker.run "swarmd",
        image: "ailispaw/swarmd",
        args: [
          "-u bargee:docker",
          "-v /tmp/swarm:/tmp/swarm",
          "-v /var/run/docker.sock:/var/run/docker.sock",
          "-p 4242:4242"
        ].join(" "),
        cmd: "-d /tmp/swarm/cluster --listen-control-api /tmp/swarm/swarm.sock"
    end

    node.vm.provision :shell do |sh|
      sh.inline = <<-EOT
        install /vagrant/swarmkit/bin/swarmctl /opt/bin/
      EOT
    end
  end

  (2..NUM_NODES).each do |i|
    config.vm.define vm_name = "node-%02d" % i do |node|
      node.vm.hostname = vm_name

      node.vm.network :private_network, ip: "#{BASE_IP_ADDR}.#{100+i}"

      node.vm.provision :docker do |docker|
        docker.run "swarmd",
          image: "ailispaw/swarmd",
          args: [
            "-u bargee:docker",
            "-v /tmp/swarm:/tmp/swarm",
            "-v /var/run/docker.sock:/var/run/docker.sock"
          ].join(" "),
          cmd: "-d /tmp/swarm/cluster --join-addr #{BASE_IP_ADDR}.101:4242"
      end
    end
  end
end
