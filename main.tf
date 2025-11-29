data "yandex_compute_image" "ubuntu_2204_lts" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
        image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
        type = "network-hdd"
        size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.terra_a.id
    nat = true
    security_group_ids = [yandex_vpc_security_group.lan.id, yandex_vpc_security_group.bastion.id]
  }

  metadata = {
    user-data = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }
}

resource "yandex_compute_instance" "web_a" {
  name        = "web-a"
  hostname    = "web-a"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
        image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
        type = "network-hdd"
        size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.terra_a.id
    nat = false
    security_group_ids = [yandex_vpc_security_group.lan.id, yandex_vpc_security_group.web.id]
  }

  metadata = {
    user-data = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }
}

resource "yandex_compute_instance" "web_b" {
  name        = "web-b"
  hostname    = "web-b"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores  = 2
    memory = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
        image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
        type = "network-hdd"
        size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.terra_b.id
    nat = false
    security_group_ids = [yandex_vpc_security_group.lan.id, yandex_vpc_security_group.web.id]
  }

  metadata = {
    user-data = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }
}

resource "local_file" "inventory" {
    content = <<-XYZ
    [bastion]
    ${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}

    [webservers]
    ${yandex_compute_instance.web_a.network_interface.0.ip_address}
    ${yandex_compute_instance.web_b.network_interface.0.ip_address}
    [webservers:vars]
    ansible_ssh_common_args='-o ProxyCommand="ssh -p 22 -W %h:%p -q user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'
    XYZ
    filename = "./hosts.ini"
}