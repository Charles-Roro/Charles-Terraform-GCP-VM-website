resource "google_compute_network" "vpc_network" {
  project                 = "network-psemanning"
  name                    = "manningarmo1"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "manning-sub" {
  name                   = "manningarmo1-sub"
  network                = google_compute_network.vpc_network.id
  ip_cidr_range          = "10.88.88.0/24"
  region                 = "us-central1"
  private_ip_google_access = true
}


resource "google_compute_firewall" "default" {
  name    = "nrules"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_tags = ["web"]
}

resource "google_compute_instance" "manningarmovm1" {
  boot_disk {
    auto_delete  = true
    device_name  = "manningarmovm1"

    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20240415"
      size  = 10
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = "n2-standard-2"

  metadata = {
    startup-script = "apt update\napt install -y apache2\ncat <<EOF > /var/www/html/index.html\n<html><body>\n<h2>Welcome to your custom website.</h2>\n<h3>Created with a direct input startup script!</h3>\n</body></html>\nEOF"
  }

  name = "manningarmovm1"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/network-psemanning/regions/us-central1/subnetworks/manningarmo1-sub"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "42290137601-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = ["http-server"]
  zone = "us-central1-a"
}

resource "google_compute_address" "static_ip" {
  name         = "manningarmo1-static-ip"
  region       = "us-central1"
  address_type = "EXTERNAL"
}

output "internal_ip" {
  value = google_compute_instance.manningarmovm1.network_interface.0.network_ip
}

output "vpc" {
  value = google_compute_network.vpc_network.id
}

output "subnet" {
  value = google_compute_subnetwork.manning-sub.id
}

output "external_ip" {
  value = google_compute_address.static_ip.address
}
