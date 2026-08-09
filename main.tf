// Website Uptime Monitoring with Route53 Health Checks and SNS

resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  domain_name = replace(replace(var.website_url, "https://", ""), "http://", "")
  clean_domain = split("/", local.domain_name)[0]

  is_https = startswith(var.website_url, "https://")
  protocol = local.is_https ? "HTTPS" : "HTTP"
  port     = local.is_https ? 443 : 80

  health_check_name = "${var.health_check_name}-${random_id.suffix.hex}"
  topic_name        = "${var.topic_name}-${random_id.suffix.hex}"

  common_tags = merge(var.tags, {
    Name        = "Website Uptime Monitoring"
    Website     = var.website_url
    ManagedBy   = "Terraform"
    CreatedDate = timestamp()
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_sns_topic" "website_monitoring" {
  name         = local.topic_name
  display_name = "Website Uptime Monitoring Alerts"
  tags = merge(local.common_tags, {
    ResourceType = "SNS Topic"
    Description  = "Notification for website uptime monitoring health alerts"
  })
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.website_monitoring.arn
  protocol  = "email"
  endpoint  = var.admin_email
}

resource "aws_sns_topic_policy" "uptime_alerts_policy" {
  arn = aws_sns_topic.website_monitoring.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "UptimeMonitoringTopicPolicy"
    Statement = [
      {
        Sid    = "AllowCloudWatchToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = ["sns:Publish"]
        Resource = aws_sns_topic.website_monitoring.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_route53_health_check" "website_health" {
  fqdn                            = local.clean_domain
  port                            = local.port
  type                            = local.protocol
  resource_path                   = "/"
  failure_threshold               = var.failure_threshold
  request_interval                = var.health_check_interval
  enable_sni                      = true
  measure_latency                 = true
  invert_healthcheck              = false
  # `insufficient_data_health_status` omitted for basic HTTP/HTTPS health checks

  tags = merge(local.common_tags, {
    ResourceType = "Route53 Health Check"
    Description  = "Health check monitoring ${var.website_url}"
    Domain       = local.clean_domain
    Protocol     = local.protocol
    Port         = tostring(local.port)
  })
}

resource "aws_cloudwatch_metric_alarm" "website_down" {
  alarm_name          = "Website-Down-${local.health_check_name}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = var.alarm_period
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Alert when website ${var.website_url} is detected as down by Route53 health check"
  alarm_actions       = [aws_sns_topic.website_monitoring.arn]
  ok_actions          = var.enable_recovery_notifications ? [aws_sns_topic.website_monitoring.arn] : []
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.website_health.id
  }

  tags = merge(local.common_tags, {
    ResourceType = "CloudWatch Alarm"
    Description  = "Alarm for website downtime detection"
    AlarmType    = "Website Down"
  })

  depends_on = [aws_sns_topic_policy.uptime_alerts_policy]
}

resource "aws_cloudwatch_metric_alarm" "website_recovery" {
  count                = var.enable_recovery_notifications ? 1 : 0
  alarm_name           = "Website-Recovered-${local.health_check_name}"
  comparison_operator  = "GreaterThanOrEqualToThreshold"
  evaluation_periods   = 2
  metric_name          = "HealthCheckStatus"
  namespace            = "AWS/Route53"
  period               = var.alarm_period
  statistic            = "Minimum"
  threshold            = 1
  alarm_description    = "Notify when website ${var.website_url} has recovered and is healthy"
  alarm_actions        = [aws_sns_topic.website_monitoring.arn]
  treat_missing_data   = "missing"

  dimensions = {
    HealthCheckId = aws_route53_health_check.website_health.id
  }

  tags = merge(local.common_tags, {
    ResourceType = "CloudWatch Alarm"
    Description  = "Alarm for website recovery"
    AlarmType    = "Website Recovery"
  })

  depends_on = [aws_sns_topic_policy.uptime_alerts_policy]
}

resource "aws_cloudwatch_log_group" "health_check_logs" {
  name              = "/aws/route53/healthcheck/${aws_route53_health_check.website_health.id}"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    ResourceType = "CloudWatch Log Group"
    Description  = "Logs for Route53 health checks"
  })
}

resource "aws_cloudwatch_dashboard" "uptime_monitoring" {
  dashboard_name = "WebsiteUptimeMonitoring-${random_id.suffix.hex}"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", aws_route53_health_check.website_health.id],
            [".", "HealthCheckPercentHealthy", "HealthCheckId", aws_route53_health_check.website_health.id],
            [".", "ConnectionTime", "HealthCheckId", aws_route53_health_check.website_health.id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Website Health Status"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", aws_route53_health_check.website_health.id]
          ]
          view   = "singleValue"
          region = data.aws_region.current.name
          title  = "Current Health Status"
          period = 300
          stat   = "Maximum"
        }
      }
    ]
  })

}


