defmodule OrbitalDynamics.Schema.CandidateRefreshReportContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CandidateRefreshCandidateSelectionContracts
  alias OrbitalDynamics.Schema.CandidateRefreshCommunicationPressureContracts
  alias OrbitalDynamics.Schema.CandidateRefreshContactIntentContracts
  alias OrbitalDynamics.Schema.CandidateRefreshContactIntentRoutingContracts
  alias OrbitalDynamics.Schema.CandidateRefreshObjectiveGapContracts
  alias OrbitalDynamics.Schema.CandidateRefreshOperationalTimelineContracts
  alias OrbitalDynamics.Schema.CandidateRefreshProviderCounterofferContracts
  alias OrbitalDynamics.Schema.CandidateRefreshQualityGateContracts
  alias OrbitalDynamics.Schema.CandidateRefreshReviewFeedbackContracts
  alias OrbitalDynamics.Schema.CandidateRefreshResourceSignalContracts
  alias OrbitalDynamics.Schema.CandidateRefreshStationCalendarContracts
  alias OrbitalDynamics.Schema.CandidateRefreshTimelineChangeContracts
  alias OrbitalDynamics.Schema.CandidateRefreshTimelineLifecycleContracts
  alias OrbitalDynamics.Schema.CandidateRefreshTimelinePublicationContracts
  alias OrbitalDynamics.Schema.CandidateRefreshTimelineValidationContracts
  alias OrbitalDynamics.Schema.CandidateRefreshValidationReportContracts
  alias OrbitalDynamics.Schema.OperationalReadinessContextContracts
  alias OrbitalDynamics.Schema.ValidationAcceptanceReportContracts

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_string_list_items: 4
    ]

  def validate_source_report_provenance(issues, %{"provenance" => %{} = provenance}) do
    issues
    |> expect_optional_type("$.provenance", provenance, "source_reports", :map)
    |> validate_source_report_summaries(Map.get(provenance, "source_reports"))
  end

  def validate_source_report_provenance(issues, _artifact), do: issues

  defp validate_source_report_summaries(issues, nil), do: issues

  defp validate_source_report_summaries(issues, source_reports) when is_map(source_reports) do
    Enum.reduce(source_reports, issues, fn {family, summary}, issues ->
      path = "$.provenance.source_reports.#{family}"

      issues =
        expect_type(issues, "$.provenance.source_reports", source_reports, family, :map)

      if is_map(summary) do
        issues
        |> expect_optional_type(path, summary, "contract", :binary)
        |> expect_optional_type(path, summary, "paths", :list)
        |> validate_string_list_items(path, summary, "paths")
        |> expect_optional_non_negative_integer(path, summary, "count")
        |> expect_optional_non_negative_integer(path, summary, "row_count")
        |> validate_non_negative_integer_count_map(
          path <> ".analysis_mode_counts",
          Map.get(summary, "analysis_mode_counts")
        )
        |> expect_optional_type(path, summary, "trust_boundary_status", :binary)
        |> expect_optional_type(path, summary, "trust_boundaries", :list)
        |> validate_string_list_items(path, summary, "trust_boundaries")
        |> expect_optional_non_negative_integer(
          path,
          summary,
          "station_reservation_evidence_row_count"
        )
        |> expect_optional_non_negative_integer(
          path,
          summary,
          "station_reservation_expiration_evidence_row_count"
        )
        |> OperationalReadinessContextContracts.validate_resource_context(path, summary)
        |> OperationalReadinessContextContracts.validate_adapter_boundary_context(path, summary)
        |> OperationalReadinessContextContracts.validate_cadence_import_context(path, summary)
        |> validate_link_capacity_context(path, summary)
        |> validate_constraint_context(path, summary)
        |> validate_resource_projection_context(path, summary)
        |> validate_resource_filter_context(path, summary)
        |> validate_contact_allocation_context(path, summary)
        |> validate_contact_contention_context(path, summary)
        |> validate_candidate_rejection_context(path, summary)
        |> validate_provider_counteroffer_context(path, summary)
        |> validate_maneuver_review_context(path, summary)
        |> validate_station_pressure_context(path, summary)
        |> validate_contact_intent_context(path, summary)
        |> validate_contact_filter_context(path, summary)
        |> validate_station_calendar_context(path, summary)
        |> validate_timeline_activity_context(path, summary)
        |> validate_timeline_activity_lifecycle_context(path, summary)
        |> validate_timeline_lifecycle_state_context(path, summary)
        |> validate_timeline_activity_precondition_context(path, summary)
        |> validate_timeline_integrity_context(path, summary)
        |> validate_timeline_publication_context(path, summary)
        |> validate_timeline_dependency_impact_context(path, summary)
        |> validate_timeline_feedback_context(path, summary)
        |> validate_timeline_diff_context(path, summary)
        |> validate_timeline_transition_application_context(path, summary)
        |> validate_operational_timeline_context(path, summary)
        |> validate_quality_gate_context(path, summary)
        |> validate_schema_validation_context(path, summary)
        |> validate_model_acceptance_context(path, summary)
        |> validate_freshness_context(path, summary)
        |> validate_objective_gap_context(path, summary)
        |> validate_refresh_budget_context(path, summary)
        |> validate_validation_safety_case_context(path, summary)
      else
        issues
      end
    end)
  end

  defp validate_source_report_summaries(issues, _source_reports), do: issues

  def validate_quality_gate_context(issues, path, summary) do
    CandidateRefreshQualityGateContracts.validate(issues, path, summary)
  end

  def validate_schema_validation_context(issues, path, summary) do
    CandidateRefreshValidationReportContracts.validate_schema_validation(issues, path, summary)
  end

  def validate_model_acceptance_context(issues, path, summary) do
    CandidateRefreshValidationReportContracts.validate_model_acceptance(issues, path, summary)
  end

  def validate_freshness_context(issues, path, summary) do
    CandidateRefreshCandidateSelectionContracts.validate_freshness(issues, path, summary)
  end

  def validate_objective_gap_context(issues, path, summary) do
    CandidateRefreshObjectiveGapContracts.validate(issues, path, summary)
  end

  def validate_refresh_budget_context(issues, path, summary) do
    CandidateRefreshCandidateSelectionContracts.validate_refresh_budget(issues, path, summary)
  end

  def validate_validation_safety_case_context(issues, path, summary) do
    CandidateRefreshValidationReportContracts.validate_safety_case(
      issues,
      path,
      summary,
      &ValidationAcceptanceReportContracts.safety_case_count_fields/0
    )
  end

  def validate_timeline_activity_context(issues, path, summary) do
    CandidateRefreshTimelineValidationContracts.validate_activity(issues, path, summary)
  end

  def validate_timeline_activity_lifecycle_context(issues, path, summary) do
    CandidateRefreshTimelineLifecycleContracts.validate_activity_lifecycle(
      issues,
      path,
      summary
    )
  end

  def validate_timeline_lifecycle_state_context(issues, path, summary) do
    CandidateRefreshTimelineLifecycleContracts.validate_lifecycle_state(issues, path, summary)
  end

  def validate_timeline_activity_precondition_context(issues, path, summary) do
    CandidateRefreshTimelineValidationContracts.validate_activity_precondition(
      issues,
      path,
      summary
    )
  end

  def validate_timeline_publication_context(issues, path, summary) do
    CandidateRefreshTimelinePublicationContracts.validate(issues, path, summary)
  end

  def validate_timeline_integrity_context(issues, path, summary) do
    CandidateRefreshTimelineValidationContracts.validate_integrity(issues, path, summary)
  end

  def validate_timeline_dependency_impact_context(issues, path, summary) do
    CandidateRefreshTimelineValidationContracts.validate_dependency_impact(issues, path, summary)
  end

  def validate_provider_counteroffer_context(issues, path, summary) do
    CandidateRefreshProviderCounterofferContracts.validate(issues, path, summary)
  end

  def validate_timeline_feedback_context(issues, path, summary) do
    CandidateRefreshReviewFeedbackContracts.validate_timeline_feedback(issues, path, summary)
  end

  def validate_timeline_diff_context(issues, path, summary) do
    CandidateRefreshTimelineChangeContracts.validate_diff(issues, path, summary)
  end

  def validate_operational_timeline_context(issues, path, summary) do
    CandidateRefreshOperationalTimelineContracts.validate(issues, path, summary)
  end

  def validate_timeline_transition_application_context(issues, path, summary) do
    CandidateRefreshTimelineChangeContracts.validate_transition_application(
      issues,
      path,
      summary
    )
  end

  def validate_maneuver_review_context(issues, path, summary) do
    CandidateRefreshReviewFeedbackContracts.validate_maneuver_review(issues, path, summary)
  end

  def validate_link_capacity_context(issues, path, summary) do
    CandidateRefreshResourceSignalContracts.validate_link_capacity(issues, path, summary)
  end

  def validate_constraint_context(issues, path, summary) do
    CandidateRefreshResourceSignalContracts.validate_constraint(issues, path, summary)
  end

  def validate_resource_projection_context(issues, path, summary) do
    CandidateRefreshResourceSignalContracts.validate_resource_projection(issues, path, summary)
  end

  def validate_resource_filter_context(issues, path, summary) do
    CandidateRefreshResourceSignalContracts.validate_resource_filter(issues, path, summary)
  end

  def validate_contact_contention_context(issues, path, summary) do
    CandidateRefreshCommunicationPressureContracts.validate_contact_contention(
      issues,
      path,
      summary
    )
  end

  def validate_contact_allocation_context(issues, path, summary) do
    CandidateRefreshCommunicationPressureContracts.validate_contact_allocation(
      issues,
      path,
      summary
    )
  end

  def validate_candidate_rejection_context(issues, path, summary) do
    CandidateRefreshCandidateSelectionContracts.validate_candidate_rejection(
      issues,
      path,
      summary
    )
  end

  def validate_station_pressure_context(issues, path, summary) do
    CandidateRefreshCommunicationPressureContracts.validate_station_pressure(
      issues,
      path,
      summary
    )
  end

  def validate_contact_intent_context(issues, path, summary) do
    CandidateRefreshContactIntentContracts.validate(issues, path, summary)
  end

  def validate_contact_filter_context(issues, path, summary) do
    CandidateRefreshCommunicationPressureContracts.validate_contact_filter(issues, path, summary)
  end

  def validate_station_calendar_context(issues, path, summary) do
    CandidateRefreshStationCalendarContracts.validate(issues, path, summary)
  end

  def validate_contact_intent_direction_routing(issues, path, value, summary) do
    CandidateRefreshContactIntentRoutingContracts.validate(issues, path, value, summary)
  end
end
