resource "yandex_vpc_network" "terra" {
    name = "terraform-study"
}

resource "yandex_vpc_subnet" "terra_a" {
    name = "terra-sub-ru-central1-a"
    zone = "ru-central1-a"
    network_id = yandex_vpc_network.terra.id
    v4_cidr_blocks = ["10.0.1.0/24"]
    route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_subnet" "terra_b" {
    name = "terra-sub-ru-central1-b"
    zone = "ru-central1-b"
    network_id = yandex_vpc_network.terra.id
    v4_cidr_blocks = ["10.0.2.0/24"]
    route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_gateway" "nat-gateway" {
  name = "terra-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  name = "terra-route-table"
  network_id = yandex_vpc_network.terra.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id = yandex_vpc_gateway.nat-gateway.id
  }
}

resource "yandex_vpc_security_group" "bastion" {
  name        = "bastion-sg"
  network_id  = yandex_vpc_network.terra.id

  ingress {
    protocol       = "TCP"
    description    = "allow 0.0.0.0/0"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Permit any"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "lan" {
  name        = "lan-sg"
  network_id  = yandex_vpc_network.terra.id

  ingress {
    protocol       = "TCP"
    description    = "allow 10.0.0.0/8"
    v4_cidr_blocks = ["10.0.0.0/8"]
    from_port      = 0
    to_port        = 65535
  }

  egress {
    protocol       = "ANY"
    description    = "Permit any"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "web" {
  name        = "web-sg"
  network_id  = yandex_vpc_network.terra.id

  ingress {
    protocol       = "TCP"
    description    = "allow HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "allow HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }
}