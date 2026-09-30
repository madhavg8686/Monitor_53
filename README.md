# Monitor_53
A monitoring tool using terraform 
<img width="754" height="587" alt="Website Uptime Monitoring drawio" src="https://github.com/user-attachments/assets/31d6d56a-109a-4429-8af9-3d2b5770e12e" />

# AWS Website Monitoring & Alerting Tool

A lightweight AWS monitoring and alerting solution that continuously monitors an application endpoint using **Amazon Route 53 Health Checks** and sends notifications through **Amazon SNS** when the endpoint becomes unhealthy.

The project demonstrates how to build a simple monitoring workflow using AWS-managed services without deploying or maintaining a dedicated monitoring server.

---

## ARCHITECTURE

```text
                    +----------------------+
                    |   Application / API  |
                    |   HTTP / HTTPS URL   |
                    +----------+-----------+
                               |
                               | Health Check
                               v
                    +----------------------+
                    |     Amazon Route 53  |
                    |     Health Check     |
                    +----------+-----------+
                               |
                     Endpoint Unhealthy
                               |
                               v
                    +----------------------+
                    |   Monitoring / Alarm |
                    |       Workflow       |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    |      Amazon SNS      |
                    |  Notification Topic  |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    |   Email / Subscriber |
                    +----------------------+
```

---

## Project Objective

The goal of this project is to automatically detect application availability issues and notify administrators without requiring manual monitoring.

The system:

- Continuously checks an application endpoint.
- Detects when the endpoint becomes unhealthy.
- Triggers an alerting workflow.
- Publishes an alert through Amazon SNS.
- Notifies subscribed users.
- Provides a foundation for extending the system into a production monitoring solution.

---

## AWS Services Used

| AWS Service | Purpose |
|---|---|
| Amazon Route 53 Health Check | Monitors endpoint availability |
| Amazon SNS | Sends notifications |
| Amazon CloudWatch | Monitoring and alarm integration |
| AWS IAM | Controls service permissions |

---

## How It Works

### 1. Endpoint Monitoring

A Route 53 Health Check periodically sends requests to the configured application endpoint.

```text
Application
     |
     v
Route 53 Health Check
     |
     +---- Healthy
     |
     +---- Unhealthy
```

The health check can monitor HTTP or HTTPS endpoints and determine whether the application is responding correctly.

---

### 2. Failure Detection

When the configured health-check conditions are not satisfied, Route 53 marks the endpoint as unhealthy.

Example:

```text
Health Check
     |
     +---- Check 1 -> Failed
     |
     +---- Check 2 -> Failed
     |
     +---- Check 3 -> Failed
                  |
                  v
           Endpoint Unhealthy
```

Multiple consecutive failures can be configured before an endpoint is considered unhealthy.

---

### 3. Notification

Once the monitoring condition reaches the configured failure threshold, the alerting workflow publishes a message to an SNS topic.

```text
Endpoint Failure
       |
       v
Monitoring Alarm
       |
       v
Amazon SNS
       |
       v
Email Notification
```

Example notification:

```text
ALERT: Application Health Check Failed

Endpoint: https://example.com
Status: UNHEALTHY
Detected: 12:30 PM

Action: Investigate application availability.
```

---

# Project Setup

## Prerequisites

- AWS Account
- HTTP/HTTPS endpoint to monitor
- AWS Console or AWS CLI
- Email address for SNS notifications
- Terraform, if deploying through Infrastructure as Code

---

## 1. Create an SNS Topic

Navigate to:

```text
AWS Console
    -> Amazon SNS
    -> Topics
    -> Create Topic
```

Create a topic such as:

```text
application-monitoring-alerts
```

---

## 2. Subscribe to the Topic

Create an email subscription:

```text
Protocol: Email
Endpoint: your-email@example.com
```

Confirm the subscription using the email received from Amazon SNS.

---

## 3. Create a Route 53 Health Check

Navigate to:

```text
Route 53
    -> Health Checks
    -> Create Health Check
```

Example configuration:

```text
Type: Endpoint
Protocol: HTTPS
Domain: example.com
Port: 443
Path: /
```

Example monitoring configuration:

```text
Request Interval: 30 seconds
Failure Threshold: 3
```

The failure threshold helps prevent a single temporary network failure from immediately generating an alert.

---

## 4. Configure Monitoring

Connect the health status to the monitoring and alerting workflow.

```text
Healthy
   |
   v
Continue Monitoring


Unhealthy
   |
   v
Alarm Triggered
   |
   v
SNS Notification
```

---

# Testing

The monitoring system can be tested by temporarily making the monitored endpoint unavailable.

Normal operation:

```text
Application
     |
     v
Health Check
     |
     v
HEALTHY
     |
     v
No Alert
```

Failure scenario:

```text
Application Unavailable
          |
          v
Health Check Failures
          |
          v
Endpoint Unhealthy
          |
          v
Alarm
          |
          v
Amazon SNS
          |
          v
Email Notification
```

After restoring the application, verify that the health check returns to a healthy state.

---

# Monitoring Flow

```text
                +-------------+
                | Application |
                +------+------+
                       |
                       v
              +-----------------+
              | Route 53 Health |
              |      Check      |
              +--------+--------+
                       |
                       v
              +-----------------+
              |  Health Status  |
              +--------+--------+
                       |
              +--------+--------+
              |                 |
           HEALTHY          UNHEALTHY
              |                 |
              v                 v
        Continue          Trigger Alarm
        Monitoring              |
                                v
                          Amazon SNS
                                |
                                v
                          Notification
```

---

# Security Considerations

The project follows the principle of least privilege.

Recommended practices:

- Use IAM roles instead of hard-coded AWS credentials.
- Give services only the permissions they require.
- Never commit AWS credentials to GitHub.
- Store sensitive configuration outside the source code.
- Enable MFA for privileged AWS accounts.
- Use AWS CloudTrail for auditing and activity monitoring.

---

# Cost Considerations

The project uses managed AWS services and is designed to remain lightweight.

Costs can vary depending on:

- Number of health checks
- Health-check frequency
- SNS notifications
- CloudWatch usage
- Data transfer
- Other AWS resources used by the monitored application

Always verify current AWS pricing before deploying at scale.

---

# Possible Improvements

## Multi-Endpoint Monitoring

```text
                 Monitoring System
                  /      |      \
                 /       |       \
             API-1     API-2     API-3
```

Monitor multiple applications or APIs using separate health checks.

## Multiple Notification Channels

```text
                    Amazon SNS
                  /     |      \
                 /      |       \
             Email    Lambda    Other
```

SNS can be extended with different subscribers and automated workflows.

## CloudWatch Dashboard

Create a centralized dashboard displaying:

- Endpoint health
- Failure events
- Availability
- Alarm state
- Recovery events

## Automated Remediation

A future version can trigger AWS Lambda when an application becomes unhealthy.

```text
Health Check
     |
     v
Alarm
     |
     v
Lambda
     |
     v
Automated Recovery
```

Possible remediation actions include restarting workloads, triggering deployments, or initiating incident workflows.

---

# Project Structure

```text
route53-monitoring/
|
+-- terraform/
|   +-- main.tf
|   +-- variables.tf
|   +-- outputs.tf
|   +-- providers.tf
|
+-- diagrams/
|   +-- architecture.png
|
+-- README.md
|
+-- .gitignore
```

---

# Technologies

```text
Amazon Route 53
Amazon SNS
Amazon CloudWatch
AWS IAM
Terraform
```

---

# What I Learned

Through this project, I explored:

- Route 53 Health Checks
- Application availability monitoring
- SNS notification workflows
- CloudWatch alarms
- IAM permissions
- Failure detection and alerting
- Infrastructure as Code with Terraform
- Serverless monitoring architectures

---

# Future Scope

The monitoring system can be extended into a more complete cloud observability and automated remediation platform by adding:

- CloudWatch dashboards
- Lambda-based remediation
- Multi-region health checks
- Incident automation
- Slack or Microsoft Teams integration
- Reusable Terraform modules
- Centralized logging
- Availability reporting

---

# Author

**Madhav G**

Computer Science & Engineering  
Cloud / DevOps Enthusiast

GitHub: `github.com/madhavg8686`
