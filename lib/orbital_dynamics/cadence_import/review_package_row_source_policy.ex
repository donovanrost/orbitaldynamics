defmodule OrbitalDynamics.CadenceImport.ReviewPackageRowSourcePolicy do
  @moduledoc false

  def resolve("timeline_feedback_report.v1"),
    do: "operator_review_package.realized_feedback"

  def resolve("operational_timeline_report.v1"),
    do: "operator_review_package.operational_timeline_review"

  def resolve("contact_contention_report.v1"),
    do: "operator_review_package.contact_contention_review"

  def resolve("contact_contention_resolution_report.v1"),
    do: "operator_review_package.contact_contention_recommendation"

  def resolve("campaign_plan.v1"), do: "operator_review_package.rows"
  def resolve("campaign_repair.v2"), do: "operator_review_package.rows"

  def resolve("command_window_report.v1"),
    do: "operator_review_package.command_window_review"

  def resolve("station_calendar_report.v1"),
    do: "operator_review_package.station_calendar_review"

  def resolve("station_reservation_report.v1"),
    do: "operator_review_package.station_reservation_review"

  def resolve("contact_allocation_report.v1"),
    do: "operator_review_package.contact_allocation_review"

  def resolve("resource_projection_report.v1"),
    do: "operator_review_package.resource_projection_review"

  def resolve("resource_projection_flow_summary.v1"),
    do: "operator_review_package.resource_projection_review"

  def resolve("candidate_rejection_report.v1"),
    do: "operator_review_package.candidate_rejection_review"

  def resolve("provider_counteroffer_report.v1"),
    do: "operator_review_package.provider_counteroffer_review"

  def resolve("operational_readiness_report.v1"),
    do: "operator_review_package.operational_readiness_review"

  def resolve("quality_gate_report.v1"),
    do: "operator_review_package.quality_gate_review"

  def resolve(source_artifact_type) when is_binary(source_artifact_type),
    do: "operator_review_package.rows"

  def resolve(_source_artifact_type), do: "operator_review_package.rows"
end
