# ─────────────────────────────────────────────────────────────────────────────
# Observability
#
# Why this file exists: CloudWatch Logs retention is finite, but metrics derived
# from log lines retain 15 months. A metric filter is therefore the only way to
# keep a long-run record of searches and failures after the log lines themselves
# are deleted.
#
# Metric filters are NOT retroactive. They only see events ingested after they
# are created — everything before that is already gone.
#
# Traffic and visitor numbers deliberately live in Cloudflare, not here.
# Cloudflare sits in front of CloudFront and serves a large share of requests
# from its own cache, so AWS-side request counts understate real traffic. This
# dashboard is for application behaviour: searches, results, and failures.
# ─────────────────────────────────────────────────────────────────────────────

locals {
  metric_namespace = "FindMyFGC/${var.deployment_env}"

  # CloudWatch ALB dimensions take the ARN *suffix*, not the full ARN.
  #   targetgroup/find-my-fgc-backend-prod/91306359e322dc04
  #   app/enpicie/d559bf10169f1937
  target_group_dimension = split(":", module.service.target_group_arn)[5]
  load_balancer_dimension = replace(
    split(":", data.terraform_remote_state.aws_infra.outputs.alb_arn)[5],
    "loadbalancer/",
    ""
  )
}

# ── Metric filters ────────────────────────────────────────────────────────────
# Patterns match on message text rather than the "(App/main.swift:57)" source
# suffix on purpose: line numbers shift whenever main.swift is edited, and a
# filter that silently stops matching reports zero instead of failing loudly.
#
# default_value = 0 makes each metric continuous, so alarms evaluate correctly
# in quiet periods instead of sitting in INSUFFICIENT_DATA.

# One line per search. Emitted after the request body is parsed.
#
# Matching on the rendered metadata keys rather than a prefix, because Vapor
# renders metadata sorted ALPHABETICALLY, not in declaration order. The line
# reads "POST /tournaments [gameIds: ..., query: ..., radius: ...]" only because
# gameIds happens to sort first today; adding any key ahead of it (country,
# cacheHit, clientId) would silently drop this metric to zero.
#
# Requiring all three terms pins it to the search line under any key ordering:
#   - the route-logging and completion lines have neither "query:" nor "radius:"
#   - the raw-body line carries JSON, where the text is "query":" — the colon
#     never directly follows the key, so it does not match
resource "aws_cloudwatch_log_metric_filter" "searches" {
  name           = "${var.app_name}-${var.deployment_env}-searches"
  log_group_name = module.service.log_group_name
  pattern        = "\"POST /tournaments\" \"query:\" \"radius:\""

  metric_transformation {
    name          = "Searches"
    namespace     = local.metric_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# Searches that completed successfully but matched no tournaments.
#
# Two separate log lines carry "tournamentCount" for every request — one from
# TournamentService ("StartGG response") and one from the route handler
# ("POST /tournaments complete"). Matching on the count alone therefore doubles
# the number and, since Searches is counted once, would report roughly twice the
# true zero-result rate. Both terms are required so only the completion line
# matches. The trailing "]" keeps ": 0]" from also matching 10, 20, and so on.
resource "aws_cloudwatch_log_metric_filter" "zero_results" {
  name           = "${var.app_name}-${var.deployment_env}-zero-results"
  log_group_name = module.service.log_group_name
  pattern        = "\"POST /tournaments complete\" \"tournamentCount: 0]\""

  metric_transformation {
    name          = "ZeroResults"
    namespace     = local.metric_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# The location string could not be geocoded — the user gets an HTTP 422 and no
# map. Distinct from a zero-result search, which at least resolved a location.
resource "aws_cloudwatch_log_metric_filter" "geocode_failures" {
  name           = "${var.app_name}-${var.deployment_env}-geocode-failures"
  log_group_name = module.service.log_group_name
  pattern        = "\"Could not resolve location\""

  metric_transformation {
    name          = "GeocodeFailures"
    namespace     = local.metric_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# start.gg returned something unusable. This is the app's only data upstream, so
# a sustained rise here means the product is broken regardless of our own health.
resource "aws_cloudwatch_log_metric_filter" "startgg_errors" {
  name           = "${var.app_name}-${var.deployment_env}-startgg-errors"
  log_group_name = module.service.log_group_name
  pattern        = "\"StartGG API error\""

  metric_transformation {
    name          = "StartGGErrors"
    namespace     = local.metric_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# ── Alerting ──────────────────────────────────────────────────────────────────
# An email subscription is only created when alarm_email is set. AWS sends a
# confirmation link that a human must click — until then the subscription is
# "PendingConfirmation" and alarms notify nobody.

resource "aws_sns_topic" "alerts" {
  name = "${var.app_name}-${var.deployment_env}-alerts"

  tags = {
    Project     = var.app_name
    Environment = var.deployment_env
  }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.alarm_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# Baseline is roughly 3 geocode failures per day spread thin. The failure mode
# this is built for looked different: on 2026-07-11 one user hit 9 failures in
# 43 minutes on a valid ZIP and nobody found out for a month.
resource "aws_cloudwatch_metric_alarm" "geocode_failure_spike" {
  alarm_name        = "${var.app_name}-${var.deployment_env}-geocode-failure-spike"
  alarm_description = "Geocode failures (HTTP 422) spiked. Users are typing locations the geocoder cannot resolve. Check the failing inputs in Logs Insights before assuming bad input — valid US ZIPs have failed here before."

  namespace   = local.metric_namespace
  metric_name = "GeocodeFailures"
  statistic   = "Sum"
  period      = 900
  threshold   = var.geocode_failure_threshold

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "startgg_errors" {
  alarm_name        = "${var.app_name}-${var.deployment_env}-startgg-errors"
  alarm_description = "start.gg returned unusable responses. The tournament data upstream is degraded; searches will return empty or fail."

  namespace   = local.metric_namespace
  metric_name = "StartGGErrors"
  statistic   = "Sum"
  period      = 900
  threshold   = 5

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name        = "${var.app_name}-${var.deployment_env}-target-5xx"
  alarm_description = "Backend is returning 5XX. Note this counts only requests that reached the ALB — Cloudflare 522s never get here."

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"
  statistic   = "Sum"
  period      = 300
  threshold   = 10

  dimensions = {
    TargetGroup  = local.target_group_dimension
    LoadBalancer = local.load_balancer_dimension
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# Dead-canary: the quietest observed hour still saw ~4 searches, so six hours of
# total silence means something is broken in a way health checks do not catch —
# a broken frontend build, DNS, or Cloudflare failing to reach the origin.
# Remove this if it proves noisy; it is the most speculative alarm here.
resource "aws_cloudwatch_metric_alarm" "no_searches" {
  count = var.enable_dead_canary_alarm ? 1 : 0

  alarm_name        = "${var.app_name}-${var.deployment_env}-no-searches"
  alarm_description = "No searches for 6 hours. Health checks can still pass while the site is unusable — check the frontend and Cloudflare before the backend."

  namespace   = local.metric_namespace
  metric_name = "Searches"
  statistic   = "Sum"
  period      = 21600
  threshold   = 1

  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  treat_missing_data  = "breaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ── Dashboard ─────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "app" {
  dashboard_name = "${var.app_name}-${var.deployment_env}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = join("\n", [
            "## FindMyFGC — application behaviour",
            "Traffic, visitors and geography live in **Cloudflare**, not here — Cloudflare serves much of the site from its own cache, so AWS request counts understate real traffic. This dashboard covers what Cloudflare cannot see: searches, results, and failures.",
          ])
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6
        properties = {
          title  = "Searches per day"
          view   = "timeSeries"
          region = var.aws_region
          period = 86400
          stat   = "Sum"
          metrics = [
            [local.metric_namespace, "Searches", { label = "Searches" }],
            [".", "ZeroResults", { label = "Zero results" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6
        properties = {
          title  = "Zero-result rate (%)"
          view   = "timeSeries"
          region = var.aws_region
          period = 86400
          yAxis  = { left = { min = 0, max = 100 } }
          metrics = [
            [{ expression = "100 * (z / s)", label = "Zero-result rate %", id = "e1" }],
            [local.metric_namespace, "Searches", { id = "s", stat = "Sum", visible = false }],
            [".", "ZeroResults", { id = "z", stat = "Sum", visible = false }],
          ]
          annotations = {
            horizontal = [{ label = "2026-08 baseline (18.9%)", value = 18.9 }]
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6
        properties = {
          title  = "Failures"
          view   = "timeSeries"
          region = var.aws_region
          period = 3600
          stat   = "Sum"
          metrics = [
            [local.metric_namespace, "GeocodeFailures", { label = "Geocode 422s" }],
            [".", "StartGGErrors", { label = "start.gg errors" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "TargetGroup", local.target_group_dimension, "LoadBalancer", local.load_balancer_dimension, { label = "Backend 5XX" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6
        properties = {
          title  = "Backend latency"
          view   = "timeSeries"
          region = var.aws_region
          period = 3600
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", local.target_group_dimension, "LoadBalancer", local.load_balancer_dimension, { stat = "p95", label = "p95" }],
            ["...", { stat = "Average", label = "avg" }],
          ]
          annotations = {
            horizontal = [{ label = "1s", value = 1 }]
          }
        }
      },
    ]
  })
}
