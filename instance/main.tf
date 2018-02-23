data "openstack_networking_network_v2" "instance_network" {
  region = "${var.region}"
  name = "${var.network_name}"
}

output "instance" {
    value = "${openstack_compute_instance_v2.cluster.*.id}"
}

output "instance-address" {
    value = "${openstack_compute_instance_v2.cluster.*.access_ip_v4}"
}

output "quantity" {
    value = "${var.quantity}"
}

resource "openstack_networking_floatingip_v2" "ips" {
  region = "${var.region}"
  count = "${var.external ? 1 : 0}"
  pool = "${var.floating_ip_pool}"
}

resource "openstack_compute_servergroup_v2" "clusterSG" {
  region = "${var.region}"
  name     = "${var.name}"
  policies = ["anti-affinity"]
}

resource "openstack_compute_floatingip_associate_v2" "external_ip" {
  region = "${var.region}"
  count = "${var.external ? 1 : 0}"
  floating_ip = "${openstack_networking_floatingip_v2.ips.*.address[count.index]}"
  instance_id = "${openstack_compute_instance_v2.cluster.*.id[count.index]}"
}

resource "openstack_networking_port_v2" "port_local" {
  count = "${var.quantity}"
  name = "port_local-${count.index}"
  network_id = "${data.openstack_networking_network_v2.instance_network.id}"
  admin_state_up = "true"
  region = "${var.region}"
  security_group_ids = ["${var.sec_group}"]

  allowed_address_pairs = {
    ip_address = "${var.allowed_address_pairs}"
  }

  lifecycle {
    ignore_changes = ["allowed_address_pairs"]
  }
}

resource "openstack_compute_instance_v2" "cluster" {
  region = "${var.region}"
  count = "${var.quantity}"
  flavor_name = "${var.flavor}"
  name = "${var.name}-${count.index}"
  image_name = "${var.image}"
  key_pair = "${var.keypair}"
  
  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.clusterSG.id}"
  }

  network {
    uuid = "${data.openstack_networking_network_v2.instance_network.id}"
    port = "${openstack_networking_port_v2.port_local.*.id[count.index]}"
  }

  lifecycle {
    ignore_changes = ["user_data"]
  }

  metadata = "${var.tags}"
  user_data = "${var.userdata}"
}
