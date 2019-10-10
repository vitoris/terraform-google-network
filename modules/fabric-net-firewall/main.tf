/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

###############################################################################
#                            rules based on IP ranges
###############################################################################

resource "google_compute_firewall" "allow-internal" {
  count         = var.internal_ranges_enabled == true && length(var.internal_allow) > 0 ? 1 : 0
  name          = "${var.network}-ingress-internal"
  description   = "Allow ingress traffic from internal IP ranges"
  network       = var.network
  project       = var.project_id
  source_ranges = var.internal_ranges

  dynamic "allow" {
    for_each = [var.internal_allow]
    content {
      protocol = lookup(allow.value[count.index], "protocol", null)
      ports    = lookup(allow.value[count.index], "ports", null)
    }
  }
}

resource "google_compute_firewall" "allow-admins" {
  count         = var.admin_ranges_enabled == true ? 1 : 0
  name          = "${var.network}-ingress-admins"
  description   = "Access from the admin subnet to all subnets"
  network       = var.network
  project       = var.project_id
  source_ranges = var.admin_ranges

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}

###############################################################################
#                              rules based on tags
###############################################################################

resource "google_compute_firewall" "allow-tag-ssh" {
  count         = length(var.ssh_source_ranges) > 0 ? 1 : 0
  name          = "${var.network}-ingress-tag-ssh"
  description   = "Allow SSH to machines with the 'ssh' tag"
  network       = var.network
  project       = var.project_id
  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "allow-tag-http" {
  count         = length(var.http_source_ranges) > 0 ? 1 : 0
  name          = "${var.network}-ingress-tag-http"
  description   = "Allow HTTP to machines with the 'http-server' tag"
  network       = var.network
  project       = var.project_id
  source_ranges = var.http_source_ranges
  target_tags   = ["http-server"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_firewall" "allow-tag-https" {
  count         = length(var.https_source_ranges) > 0 ? 1 : 0
  name          = "${var.network}-ingress-tag-https"
  description   = "Allow HTTPS to machines with the 'https' tag"
  network       = var.network
  project       = var.project_id
  source_ranges = var.https_source_ranges
  target_tags   = ["https-server"]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}

################################################################################
#                                dynamic rules                                 #
################################################################################

resource "google_compute_firewall" "ingress-dynamic" {
  # provider                = "google-beta"
  for_each                = var.ingress_rules
  name                    = each.key
  description             = each.value.description
  direction               = "INGRESS"
  network                 = var.network
  project                 = var.project_id
  source_ranges           = each.value.source_ranges
  source_tags             = each.value.target_type == "service_accounts" ? null : each.value.source_tags
  target_tags             = each.value.target_type == "tags" ? each.value.target_values : null
  target_service_accounts = each.value.target_type == "service_accounts" ? each.value.target_values : null
  disabled                = lookup(each.value.extra_attributes, "disabled", false)
  priority                = lookup(each.value.extra_attributes, "priority", 1000)
  # enable_logging          = lookup(each.value.extra_attributes, "enable_logging", false)

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }
}

/* resource "google_compute_firewall" "egress-dynamic" {
  for_each                = var.ingress_rules
  name                    = each.key
  description             = each.value.description
  network                 = var.network
  project                 = var.project_id
  source_ranges           = each.value.source_ranges
  target_tags             = each.value.target_type == "tags" ? each.value.target_values : null
  target_service_accounts = each.value.target_type == "service_accounts" ? each.value.target_values : null
  disabled                = lookup(each.value.extra_attributes, "disabled", false)
  priority                = lookup(each.value.extra_attributes, "priority", 1000)
  # logging needs the beta provider
  # enable_logging          = lookup(each.value.extra_attributes, "enable_logging", false)

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }
}
 */
