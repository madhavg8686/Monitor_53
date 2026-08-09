#Variables
variable "website_url"{
    description = "URL of website to monitor"
    type = string
    default = "https://example.com"
    validation {
      condition = can(regex("^https?://", var.website_url))
      error_message = "Website URL must start with http:// or https://"
    }
}

variable "admin_email"{
    description = "Email address to receive uptime monitoring alerts"
    type = string
    default = "madhav.g8686@gmail.com"
    validation{
        condition = can(regex("^[a-zA-Z0-9._+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.admin_email))
        error_message= "Please provide a valid email address"
    }
}

variable "health_check_name"{
    description="Name for sns topic to send email"
    type= string
    default="website-health-check"
}
variable "topic_name"{
    description = "Name for sns topic to send alerts"
    type = string
    default= "website-uptime-alerts"
}

variable "health_check_interval"{
    description = "Health check request interval in seconds 10 or 30"
    type=number
    default=30
    validation{
        condition =contains([10,30],var.health_check_interval)
        error_message = "Health check must be in intervals of 10 or 30"
    }
}
variable "failure_threshold"{
    description = "Number of consequitive failures before health check is considered unhealthy"
    type = number
    default=3
    validation{
        condition=var.failure_threshold >= 1 && var.failure_threshold <= 10
        error_message = "Failure threshold must be within 1 and 10"
    }
 }

variable "alarm_period"{
    description = "Period in seconds for cloudwatch alarm eval"
    type =number
    default=60
}

variable "alarm_evaluation_periods" {
    description = "Number of periods CloudWatch evaluates before triggering the alarm"
    type        = number
    default     = 1
}

variable "enable_recovery_notifications" {
    description = "Whether to send notifications when website is down"
    type=bool
    default=true
  
}

variable "tags"{
    description = "Tags to aplly"
    type=map(string)
    default={
        Environment="Production"
        Purpose="UptimeMonitoring"
        Project="WebsiteMonitoring"
    }

}




