Vagrant.configure("2") do |config|
  config.vm.define "haproxy" do |haproxy|
    haproxy.vm.box = "centos/7"
	haproxy.vm.provider "virtualbox" do |vb|
		vb.memory = 1024
		vb.cpus = 1
	end
	haproxy.vm.network "private_network", ip: "10.0.0.17", netmask:"255.255.255.0"
	haproxy.vm.provision "shell", path: "https://github.com/davetayl/Vagrant-General/raw/master/setup-centos7.sh"
	haproxy.vm.provision "shell", path: "./provision-haproxy.sh"
  end
  config.vm.define "target" do |target|
    target.vm.box = "centos/7"
	target.vm.provider "virtualbox" do |vb|
		vb.memory = 1024
		vb.cpus = 1
	end
	target.vm.network "private_network", ip: "10.0.0.18", netmask:"255.255.255.0"
	target.vm.provision "shell", path: "https://github.com/davetayl/Vagrant-General/raw/master/setup-centos7.sh"
	target.vm.provision "shell", path: "./provision-target.sh"
  end

end