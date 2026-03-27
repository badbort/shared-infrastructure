locals {
  dns_zone_name = "badbort.com"

  # Low TTL is useful during PoC — easy to bump up for production
  dns_default_ttl = 300

  dns_a_records = {
    # "@" = { records = ["1.2.3.4"] }
    # "www" = { records = ["1.2.3.4"] }
    # "staging" = { ttl = 60, records = ["1.2.3.4"] }  # override ttl when needed
  }

  dns_cname_records = {
    # "api" = { record = "some.target.example.com" }
  }

  dns_txt_records = {
    # "@" = { records = ["v=spf1 -all"] }
  }

  dns_mx_records = {
    # "@" = { records = [{ preference = 10, exchange = "mail.example.com" }] }
  }
}

import {
  to = azurerm_dns_zone.badbort
  id = "/subscriptions/bd8e250a-66a6-4038-acd8-0d6aced3e3c8/resourceGroups/rg-common/providers/Microsoft.Network/dnsZones/badbort.com"
}

resource "azurerm_dns_zone" "badbort" {
  name                = local.dns_zone_name
  resource_group_name = module.common.rg_name
  tags                = var.resource_tags

  soa_record {
    email         = "admin.badbort.com"
    expire_time   = 2419200
    minimum_ttl   = 300
    refresh_time  = 3600
    retry_time    = 300
    ttl           = 3600
  }
}

resource "azurerm_dns_a_record" "records" {
  for_each            = local.dns_a_records
  name                = each.key
  zone_name           = azurerm_dns_zone.badbort.name
  resource_group_name = module.common.rg_name
  ttl                 = try(each.value.ttl, local.dns_default_ttl)
  records             = each.value.records
  tags                = var.resource_tags
}

resource "azurerm_dns_cname_record" "records" {
  for_each            = local.dns_cname_records
  name                = each.key
  zone_name           = azurerm_dns_zone.badbort.name
  resource_group_name = module.common.rg_name
  ttl                 = try(each.value.ttl, local.dns_default_ttl)
  record              = each.value.record
  tags                = var.resource_tags
}

resource "azurerm_dns_txt_record" "records" {
  for_each            = local.dns_txt_records
  name                = each.key
  zone_name           = azurerm_dns_zone.badbort.name
  resource_group_name = module.common.rg_name
  ttl                 = try(each.value.ttl, local.dns_default_ttl)

  dynamic "record" {
    for_each = each.value.records
    content {
      value = record.value
    }
  }

  tags = var.resource_tags
}

resource "azurerm_dns_mx_record" "records" {
  for_each            = local.dns_mx_records
  name                = each.key
  zone_name           = azurerm_dns_zone.badbort.name
  resource_group_name = module.common.rg_name
  ttl                 = try(each.value.ttl, local.dns_default_ttl)

  dynamic "record" {
    for_each = each.value.records
    content {
      preference = record.value.preference
      exchange   = record.value.exchange
    }
  }

  tags = var.resource_tags
}
