// Tags
locals {
  tags = {
    owner       = var.tag_department
    region      = var.tag_region
    environment = var.environment
  }
}

// Existing Resources

/// Subscription ID

data "azurerm_subscription" "current" {
}

// Random Suffix Generator

resource "random_integer" "deployment_id_suffix" {
  min = 100
  max = 999
}

// Resource Group

resource "azurerm_resource_group" "rgcam" {
  name     = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-rgcam"
  location = var.location

  tags = local.tags
}

// Storage Account

resource "azurerm_storage_account" "storage" {
  name                     = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}st"
  resource_group_name      = azurerm_resource_group.rgcam.name
  location                 = azurerm_resource_group.rgcam.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
  is_hns_enabled           = true
}

// Machine Learning Workspace

data "azurerm_client_config" "current" {}

resource "azurerm_application_insights" "appinscam" {
  name                = "workspace-rgcam-ai"
  location            = azurerm_resource_group.rgcam.location
  resource_group_name = azurerm_resource_group.rgcam.name
  application_type    = "web"
}

resource "azurerm_key_vault" "kvcam" {
  name                = "workspaceexamplekeyvault"
  location            = azurerm_resource_group.rgcam.location
  resource_group_name = azurerm_resource_group.rgcam.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
}


resource "azurerm_machine_learning_workspace" "mlwscam" {
  name                    = "rgcam-workspace"
  location                = azurerm_resource_group.rgcam.location
  resource_group_name     = azurerm_resource_group.rgcam.name
  application_insights_id = azurerm_application_insights.appinscam.id
  key_vault_id            = azurerm_key_vault.kvcam.id
  storage_account_id      = azurerm_storage_account.storage.id

  identity {
    type = "SystemAssigned"
  }
}


// Cosmos

resource "azurerm_cosmosdb_account" "camdb" {
  name                = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}camdb"
  location            = azurerm_resource_group.rgcam.location
  resource_group_name = azurerm_resource_group.rgcam.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "eastus"
    failover_priority = 0
  }

}

// Firewall

resource "azurerm_virtual_network" "vnetcam" {
  name                = "testvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rgcam.location
  resource_group_name = azurerm_resource_group.rgcam.name
}

resource "azurerm_subnet" "subnetcam" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rgcam.name
  virtual_network_name = azurerm_virtual_network.vnetcam.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "rgcam" {
  name                = "testpip"
  location            = azurerm_resource_group.rgcam.location
  resource_group_name = azurerm_resource_group.rgcam.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "rgcam" {
  name                = "testfirewall"
  location            = azurerm_resource_group.rgcam.location
  resource_group_name = azurerm_resource_group.rgcam.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnetcam.id
    public_ip_address_id = azurerm_public_ip.rgcam.id
  }
}

// Data Factory

resource "azurerm_data_factory" "rgcam" {
  name                = "rgcam"
  location            = azurerm_resource_group.rgcam.location
  resource_group_name = azurerm_resource_group.rgcam.name
}