resource "google_compute_firewall" "permitir_http" {
  name    = "${var.prefijo}-permitir-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["grupo-2-sv"]
}

resource "google_compute_firewall" "ssh_iap" {
  name    = "${var.prefijo}-permitir-ssh-iap"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # 35.235.240.0/20 es el rango desde el que Google reenvía SSH
  # a través de IAP. Es el único origen autorizado para el 22.
  # La de datos también lo lleva: es la única forma de administrarla.
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["grupo-2-sv", "grupo-2-datos"]
}

# Redis solo acepta tráfico que venga de máquinas con la etiqueta de la
# aplicación, no de toda la VPC ni de un rango de direcciones.
resource "google_compute_firewall" "redis_interno" {
  name    = "${var.prefijo}-permitir-redis-app"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  source_tags = ["grupo-2-sv"]
  target_tags = ["grupo-2-datos"]
}
