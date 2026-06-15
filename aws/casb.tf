# ============================================================
# CASB — Cloud Access Security Broker (version compte gratuit)
# Implémenté avec : CloudTrail + CloudWatch + SNS + Config
# ============================================================

# ============================================================
# SNS Topic — Canal d'alertes CASB
# ============================================================

resource "aws_sns_topic" "casb_alerts" {
  name = "casb-security-alerts"
  tags = {
    Name    = "secure-multicloud-casb-alerts"
    Project = var.project_name
  }
}

# ============================================================
# CloudWatch Log Group pour CloudTrail
# ============================================================

resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/aws/cloudtrail/secure-multicloud"
  retention_in_days = 90
  tags = {
    Name    = "secure-multicloud-cloudtrail-logs"
    Project = var.project_name
  }
}

# ============================================================
# IAM Role pour CloudTrail → CloudWatch
# ============================================================

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "cloudtrail-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  name = "cloudtrail-cloudwatch-policy"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
    }]
  })
}

# ============================================================
# CASB Alerte 1 — Connexion root account détectée
# ============================================================

resource "aws_cloudwatch_log_metric_filter" "root_login" {
  name           = "casb-root-login"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.eventType != \"AwsServiceEvent\" }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name

  metric_transformation {
    name      = "RootAccountLogin"
    namespace = "SecureMultiCloud/CASB"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_login_alarm" {
  alarm_name          = "casb-root-account-login"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootAccountLogin"
  namespace           = "SecureMultiCloud/CASB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "CASB ALERT: Root account login detected"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.casb_alerts.arn]

  tags = {
    Name    = "casb-root-login-alarm"
    Project = var.project_name
  }
}

# ============================================================
# CASB Alerte 2 — Modification IAM non autorisée
# ============================================================

resource "aws_cloudwatch_log_metric_filter" "iam_changes" {
  name           = "casb-iam-changes"
  pattern        = "{ ($.eventName = DeleteGroupPolicy) || ($.eventName = DeleteRolePolicy) || ($.eventName = DeleteUserPolicy) || ($.eventName = PutGroupPolicy) || ($.eventName = PutRolePolicy) || ($.eventName = PutUserPolicy) || ($.eventName = CreatePolicy) || ($.eventName = DeletePolicy) || ($.eventName = CreatePolicyVersion) || ($.eventName = DeletePolicyVersion) || ($.eventName = SetDefaultPolicyVersion) || ($.eventName = AttachRolePolicy) || ($.eventName = DetachRolePolicy) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name

  metric_transformation {
    name      = "IAMPolicyChanges"
    namespace = "SecureMultiCloud/CASB"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_changes_alarm" {
  alarm_name          = "casb-iam-policy-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "IAMPolicyChanges"
  namespace           = "SecureMultiCloud/CASB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "CASB ALERT: IAM policy modification detected"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.casb_alerts.arn]

  tags = {
    Name    = "casb-iam-changes-alarm"
    Project = var.project_name
  }
}

# ============================================================
# CASB Alerte 3 — Bucket S3 rendu public
# ============================================================

resource "aws_cloudwatch_log_metric_filter" "s3_public_access" {
  name           = "casb-s3-public-access"
  pattern        = "{ ($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name

  metric_transformation {
    name      = "S3BucketPolicyChanges"
    namespace = "SecureMultiCloud/CASB"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "s3_public_alarm" {
  alarm_name          = "casb-s3-policy-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "S3BucketPolicyChanges"
  namespace           = "SecureMultiCloud/CASB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "CASB ALERT: S3 bucket policy modification detected"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.casb_alerts.arn]

  tags = {
    Name    = "casb-s3-alarm"
    Project = var.project_name
  }
}

# ============================================================
# CASB Alerte 4 — Modification du VPN / réseau
# ============================================================

resource "aws_cloudwatch_log_metric_filter" "vpn_changes" {
  name           = "casb-vpn-changes"
  pattern        = "{ ($.eventName = CreateVpnConnection) || ($.eventName = DeleteVpnConnection) || ($.eventName = ModifyVpnConnection) || ($.eventName = CreateVpnGateway) || ($.eventName = DeleteVpnGateway) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name

  metric_transformation {
    name      = "VPNChanges"
    namespace = "SecureMultiCloud/CASB"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "vpn_changes_alarm" {
  alarm_name          = "casb-vpn-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "VPNChanges"
  namespace           = "SecureMultiCloud/CASB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "CASB ALERT: VPN configuration change detected"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.casb_alerts.arn]

  tags = {
    Name    = "casb-vpn-alarm"
    Project = var.project_name
  }
}

# ============================================================
# CASB Alerte 5 — Désactivation de CloudTrail (Anti-forensics)
# ============================================================

resource "aws_cloudwatch_log_metric_filter" "cloudtrail_disabled" {
  name           = "casb-cloudtrail-disabled"
  pattern        = "{ ($.eventName = StopLogging) || ($.eventName = DeleteTrail) || ($.eventName = UpdateTrail) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name

  metric_transformation {
    name      = "CloudTrailDisabled"
    namespace = "SecureMultiCloud/CASB"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_disabled_alarm" {
  alarm_name          = "casb-cloudtrail-disabled"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CloudTrailDisabled"
  namespace           = "SecureMultiCloud/CASB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "CASB CRITICAL: CloudTrail logging disabled — possible anti-forensics"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.casb_alerts.arn]

  tags = {
    Name    = "casb-cloudtrail-alarm"
    Project = var.project_name
  }
}

# ============================================================
# Outputs CASB
# ============================================================

output "casb_sns_topic_arn" {
  value       = aws_sns_topic.casb_alerts.arn
  description = "SNS Topic ARN pour les alertes CASB"
}

output "casb_log_group" {
  value       = aws_cloudwatch_log_group.cloudtrail_logs.name
  description = "CloudWatch Log Group pour CloudTrail"
}

output "casb_alerts_count" {
  value       = "5 alertes CASB configurées : Root Login, IAM Changes, S3 Policy, VPN Changes, CloudTrail Disabled"
  description = "Résumé des alertes CASB"
}
