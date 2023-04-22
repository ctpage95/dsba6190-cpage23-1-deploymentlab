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


resource "azurerm_storage_account" "storageml" {
  name                     = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}ml"
  resource_group_name      = azurerm_resource_group.rgcam.name
  location                 = azurerm_resource_group.rgcam.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
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


// Machine Learning Workspace

data "azurerm_client_config" "current" {}

resource "azurerm_application_insights" "appinscam" {
  name                = "workspace-rgcam-ai"
  location            = azurerm_resource_group.rgcam.location
  resource_group_name = azurerm_resource_group.rgcam.name
  application_type    = "web"
}

resource "azurerm_key_vault" "kvcam2" {
  name                = "ws-kv-dsba6190campage2"
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
  key_vault_id            = azurerm_key_vault.kvcam2.id
  storage_account_id      = azurerm_storage_account.storageml.id

  identity {
    type = "SystemAssigned"
  }
}

// Data Factory

resource "azurerm_data_factory" "datafactorycam" {
  name                = "df-dsba6190-cam6190"
  location            = azurerm_resource_group.rgcam.location
  resource_group_name = azurerm_resource_group.rgcam.name
}



