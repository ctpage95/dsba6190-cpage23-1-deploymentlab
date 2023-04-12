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

resource "azurerm_resource_group" "rg2" {
  name     = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-rg2"
  location = var.location

  tags = local.tags
}


// Storage Account

resource "azurerm_storage_account" "storage" {
  name                     = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}st"
  resource_group_name      = azurerm_resource_group.rg2.name
  location                 = azurerm_resource_group.rg2.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.tags
}

// Machine Learning Workspace

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_application_insights" "rg2" {
  name                = "workspace-rg2-ai"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  application_type    = "web"
}

resource "azurerm_key_vault" "rg2" {
  name                = "workspaceexamplekeyvault"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
}



resource "azurerm_machine_learning_workspace" "rg2" {
  name                    = "rg2-workspace"
  location                = azurerm_resource_group.rg2.location
  resource_group_name     = azurerm_resource_group.rg2.name
  application_insights_id = azurerm_application_insights.rg2.id
  key_vault_id            = azurerm_key_vault.rg2.id
  storage_account_id      = azurerm_storage_account.rg2.id