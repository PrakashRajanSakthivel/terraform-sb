variable "name" {
  type        = string
  default     = "tesbpsst"
  description = "The name of the namespace."
}

variable "resource_group_name" {
  type        = string
  default     = "tsterraform"
  description = "The name of an existing resource group."
}

variable "location" {
  type        = string
  default     = "centralus"
  description = "The name of an Location."
}


variable "sku" {
  type        = string
  default     = "Standard"
  description = "The SKU of the namespace. The options are: `Basic`, `Standard`, `Premium`."
}

variable "capacity" {
  type        = number
  default     = 0
  description = "The number of message units."
}

variable "topics" {
  type        = any
  default     = [
    {
      name = "123",
      subscriptions = [
        {
          name = "1222"
          rules = [{
            name = "ProcessingSucceededRule",
            sql_filter = "Da = 'we'"
          }]
        },
        {
          name = "oracledatareadysubscription"
          max_delivery_count = 1
          rules = [{
            name = "DataReadyRule",
            sql_filter = "dat= '12'"
          }]
        }
      ]
    },
    {
     name = "newtopic",
      subscriptions = [
        {
          name = "new sub"
        }
      ] 
    }
  ]
  description = "List of topics."
}

variable "authorization_rules" {
  type        = any
  default     = []
  description = "List of namespace authorization rules."
}

variable "queues" {
  type        = any
  default     = []
  description = "List of queues."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = " Map of tags to assign to the resources."
}

locals {
  authorization_rules = [
    for rule in var.authorization_rules : merge({
      name   = ""
      rights = []
    }, rule)
  ]

  default_authorization_rule = {
    name                        = "RootManageSharedAccessKey"
    primary_connection_string   = azurerm_servicebus_namespace.servicebus.default_primary_connection_string
    secondary_connection_string = azurerm_servicebus_namespace.servicebus.default_secondary_connection_string
    primary_key                 = azurerm_servicebus_namespace.servicebus.default_primary_key
    secondary_key               = azurerm_servicebus_namespace.servicebus.default_secondary_key
  }

  topics = [
    for topic in var.topics : merge({
      name                       = ""
      status                     = "Active"
      auto_delete_on_idle        = null
      default_message_ttl        = null
      enable_batched_operations  = null
      enable_express             = null
      enable_partitioning        = null
      max_size                   = null
      enable_duplicate_detection = null
      enable_ordering            = null
      authorization_rules        = []
      subscriptions              = []

      duplicate_detection_history_time_window = null
    }, topic)
  ]

    queues = [
    for queue in var.queues : merge({
      name                       = ""
      status                     = "Active"
      auto_delete_on_idle        = null
      default_message_ttl        = null
      enable_batched_operations  = null
      enable_express             = null
      enable_partitioning        = null
      max_size                   = null
      enable_duplicate_detection = null
      enable_ordering            = null
      authorization_rules        = []
      subscriptions              = []
      max_delivery_count         = 10

      duplicate_detection_history_time_window = null
    }, queue)
  ]

  topic_authorization_rules = flatten([
    for topic in local.topics : [
      for rule in topic.authorization_rules : merge({
        name   = ""
        rights = []
        }, rule, {
        topic_name = topic.name
      })
    ]
  ])

  topic_subscriptions = flatten([
    for topic in local.topics : [
      for subscription in topic.subscriptions :
      merge({
        name                      = ""
        auto_delete_on_idle       = null
        default_message_ttl       = null
        lock_duration             = null
        enable_batched_operations = null
        max_delivery_count        = 10
        enable_session            = null
        forward_to                = null
        rules                     = []

        enable_dead_lettering_on_message_expiration = null
        }, subscription, {
        topic_name = topic.name
      })
    ]
  ])

  topic_subscription_rules = flatten([
    for subscription in local.topic_subscriptions : [
      for rule in subscription.rules : merge({
        name       = ""
        sql_filter = ""
        action     = ""
        }, rule, {
        topic_name        = subscription.topic_name
        subscription_name = subscription.name
      })
    ]
  ])
}
