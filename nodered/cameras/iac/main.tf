terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
  }
}

resource "null_resource" "camerasSetup" {
  triggers = {
    hash = timestamp()
  }

  for_each = { for camera in var.cameras : camera.name => camera }

  connection {
    host     = each.value.ip
    user     = each.value.user
    password = each.value.pass
  }

  provisioner "remote-exec" {
    inline = [
      "sudo DEBIAN_FRONTEND=noninteractive apt -y update",
      "sudo DEBIAN_FRONTEND=noninteractive apt -y upgrade",
      "sudo DEBIAN_FRONTEND=noninteractive apt -y install python3 python3-psutil motion htop vim wget curl unzip zip net-tools dnsutils",
      "sudo usermod -aG motion ${each.value.user}",
      "sudo mkdir -p /etc/camera",
      "sudo chmod g+w /etc/camera",
      "sudo chgrp motion /etc/camera",
      "mkdir -p ${each.value.install_dir}/motion",
    ]
  }
}

resource "null_resource" "camerasFiles" {
  triggers = {
    hash = timestamp()
  }

  for_each = { for camera in var.cameras : camera.name => camera }

  connection {
    host     = each.value.ip
    user     = each.value.user
    password = each.value.pass
  }

  provisioner "file" {
    source      = "../bin/cpu.py"
    destination = "${each.value.install_dir}/cpu.py"
  }

  provisioner "file" {
    source      = "../bin/cpu.sh"
    destination = "${each.value.install_dir}/cpu.sh"
  }

  provisioner "file" {
    source      = "../bin/disk.sh"
    destination = "${each.value.install_dir}/disk.sh"
  }

  provisioner "file" {
    source      = "../bin/memory.sh"
    destination = "${each.value.install_dir}/memory.sh"
  }

  provisioner "file" {
    source      = "../bin/model.sh"
    destination = "${each.value.install_dir}/model.sh"
  }

  provisioner "file" {
    source      = "../bin/stats.sh"
    destination = "${each.value.install_dir}/stats.sh"
  }

  provisioner "file" {
    source      = "../bin/temp.sh"
    destination = "${each.value.install_dir}/temp.sh"
  }

  provisioner "file" {
    source      = "../bin/motion/checkIfItsOn.sh"
    destination = "${each.value.install_dir}/motion/checkIfItsOn.sh"
  }

  provisioner "file" {
    source      = "../bin/motion/start.sh"
    destination = "${each.value.install_dir}/motion/start.sh"
  }

  provisioner "file" {
    source      = "../bin/motion/stop.sh"
    destination = "${each.value.install_dir}/motion/stop.sh"
  }

  provisioner "file" {
    source      = "../bin/motion/motion.conf.template"
    destination = "${each.value.install_dir}/motion/motion.conf.template"
  }

  provisioner "file" {
    source      = "../etc/environment"
    destination = "/etc/camera/environment"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod uog+x ${each.value.install_dir}/*.sh",
      "chmod uog+x ${each.value.install_dir}/motion/*.sh"
    ]
  }

  depends_on = [ null_resource.camerasSetup ]
}