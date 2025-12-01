resource "google_compute_instance" "vm-instances" {
  for_each = var.instances
  name = each.key       #jenkins-master         jenkins-slave       sonar       nexus   
  zone = var.geczone
  machine_type = each.value
  tags = [each.key]  # this can be used , if we want to implement instance level firewalls
  boot_disk {
    initialize_params {
        image  = data.google_compute_image.ubuntu_image.self_link
        #image = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2510-questing-amd64-v20251024"
        size = 10
        type  = "pd-balanced"

    }
  }
  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  connection{
    type        = "ssh"
    user        = "asielnathala"
    host        = self.network_interface[0].access_config[0].nat_ip
    private_key = file("ssh-key")
  }

  provisioner "file" {
    source      = each.key == "ansible" ? "ansible.sh" : "empty.sh"
    destination = each.key == "ansible" ? "/home/asielnathala/ansible.sh" : "/home/asielnathala/empty.sh"
  }

  provisioner "remote-exec" {
    inline = [
      each.key == "ansible" ? "chmod +x /home/asielnathala/ansible.sh && sh /home/asielnathala/ansible.sh" : "echo skip the command"
    ]
  }

  provisioner "file" {
    source      = "ssh-key"
    destination = "/home/asielnathala/ssh-key"
  }
}

# Implement data sources , 
data "google_compute_image" "ubuntu_image" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

