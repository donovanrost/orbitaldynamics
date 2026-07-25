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
      error: 2,
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_string_list_items: 4
    ]

  def validate_source_report_provenance(issues, %{"provenance" => %{} = provenance}) do
    validate_optional_provenance(issues, "$.provenance", provenance)
  end

  def validate_source_report_provenance(issues, _artifact), do: issues

  def validate_optional_provenance(issues, _path, nil), do: issues

  def validate_optional_provenance(issues, path, %{} = provenance) do
    issues
    |> expect_optional_type(path, provenance, "source_reports", :map)
    |> validate_source_report_summaries(
      path <> ".source_reports",
      Map.get(provenance, "source_reports")
    )
    |> expect_optional_type(path, provenance, "run_input_sources", :map)
    |> validate_run_input_sources(
      path <> ".run_input_sources",
      Map.get(provenance, "run_input_sources")
    )
  end

  def validate_optional_provenance(issues, path, _provenance),
    do: [error(path, "must be a map") | issues]

  defp validate_source_report_summaries(issues, _path, nil), do: issues

  defp validate_source_report_summaries(issues, path, source_reports)
       when is_map(source_reports) do
    Enum.reduce(source_reports, issues, fn {family, summary}, issues ->
      summary_path = "#{path}.#{family}"

      issues =
        expect_type(issues, path, source_reports, family, :map)

      if is_map(summary) do
        issues
        |> expect_optional_type(summary_path, summary, "contract", :binary)
        |> expect_optional_type(summary_path, summary, "paths", :list)
        |> validate_string_list_items(summary_path, summary, "paths")
        |> expect_optional_non_negative_integer(summary_path, summary, "count")
        |> expect_optional_non_negative_integer(summary_path, summary, "row_count")
        |> validate_non_negative_integer_count_map(
          summary_path <> ".analysis_mode_counts",
          Map.get(summary, "analysis_mode_counts")
        )
        |> expect_optional_type(summary_path, summary, "trust_boundary_status", :binary)
        |> expect_optional_type(summary_path, summary, "trust_boundaries", :list)
        |> validate_string_list_items(summary_path, summary, "trust_boundaries")
        |> expect_optional_non_negative_integer(
          summary_path,
          summary,
          "station_reservation_evidence_row_count"
        )
        |> expect_optional_non_negative_integer(
          summary_path,
          summary,
          "station_reservation_expiration_evidence_row_count"
        )
        |> OperationalReadinessContextContracts.validate_resource_context(summary_path, summary)
        |> OperationalReadinessContextContracts.validate_adapter_boundary_context(
          summary_path,
          summary
        )
        |> OperationalReadinessContextContracts.validate_cadence_import_context(
          summary_path,
          summary
        )
        |> validate_link_capacity_context(summary_path, summary)
        |> validate_constraint_context(summary_path, summary)
        |> validate_resource_projection_context(summary_path, summary)
        |> validate_resource_filter_context(summary_path, summary)
        |> validate_contact_allocation_context(summary_path, summary)
        |> validate_contact_contention_context(summary_path, summary)
        |> validate_candidate_rejection_context(summary_path, summary)
        |> validate_provider_counteroffer_context(summary_path, summary)
        |> validate_maneuver_review_context(summary_path, summary)
        |> validate_station_pressure_context(summary_path, summary)
        |> validate_contact_intent_context(summary_path, summary)
        |> validate_contact_filter_context(summary_path, summary)
        |> validate_station_calendar_context(summary_path, summary)
        |> validate_timeline_activity_context(summary_path, summary)
        |> validate_timeline_activity_lifecycle_context(summary_path, summary)
        |> validate_timeline_lifecycle_state_context(summary_path, summary)
        |> validate_timeline_activity_precondition_context(summary_path, summary)
        |> validate_timeline_integrity_context(summary_path, summary)
        |> validate_timeline_publication_context(summary_path, summary)
        |> validate_timeline_dependency_impact_context(summary_path, summary)
        |> validate_timeline_feedback_context(summary_path, summary)
        |> validate_timeline_diff_context(summary_path, summary)
        |> validate_timeline_transition_application_context(summary_path, summary)
        |> validate_operational_timeline_context(summary_path, summary)
        |> validate_quality_gate_context(summary_path, summary)
        |> validate_schema_validation_context(summary_path, summary)
        |> validate_model_acceptance_context(summary_path, summary)
        |> validate_freshness_context(summary_path, summary)
        |> validate_objective_gap_context(summary_path, summary)
        |> validate_refresh_budget_context(summary_path, summary)
        |> validate_validation_safety_case_context(summary_path, summary)
      else
        issues
      end
    end)
  end

  defp validate_source_report_summaries(issues, _path, _source_reports), do: issues

  defp validate_run_input_sources(issues, _path, nil), do: issues

  defp validate_run_input_sources(issues, path, run_input_sources)
       when is_map(run_input_sources) do
    Enum.reduce(run_input_sources, issues, fn {family, _sources}, issues ->
      issues
      |> expect_type(path, run_input_sources, family, :list)
      |> validate_string_list_items(path, run_input_sources, family)
    end)
  end

  defp validate_run_input_sources(issues, _path, _run_input_sources), do: issues

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
