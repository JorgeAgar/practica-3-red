# Máquina de aplicación: subred pública, IP pública efímera.
resource "google_compute_instance" "app" {
  name         = "${var.prefijo}-app"
  machine_type = var.tipo_maquina
  zone         = var.zona
  tags         = ["grupo-2-sv"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    # la máquina debe quedar en tu subred, no en la default
    subnetwork = google_compute_subnetwork.publica.id
    # un bloque vacío aquí otorga una IP pública efímera
    access_config {}
  }

  # templatefile le pasa al script la IP interna de la máquina de datos.
  # Esa referencia es también la que obliga a crear primero la de datos.
  metadata_startup_script = templatefile("arranque.sh", {
    ip_datos = google_compute_instance.datos.network_interface[0].network_ip
  })
}

# Máquina de datos: Redis, sin bloque access_config, así que sin IP pública.
resource "google_compute_instance" "datos" {
  name         = "${var.prefijo}-datos"
  machine_type = var.tipo_maquina
  zone         = var.zona
  tags         = ["grupo-2-datos"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.datos.id
  }

  metadata_startup_script = file("datos.sh")

  # El script de arranque instala Redis con apt y para eso necesita el NAT.
  # Esa dependencia existe en la realidad pero no aparece en ninguna
  # referencia del código, así que se declara a mano.
  depends_on = [google_compute_router_nat.nat]
}
