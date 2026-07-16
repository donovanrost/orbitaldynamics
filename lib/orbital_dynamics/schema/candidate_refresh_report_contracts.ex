defmodule OrbitalDynamics.Schema.CandidateRefreshReportContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CandidateRefreshCandidateSelectionContracts
  alias OrbitalDynamics.Schema.CandidateRefreshContactIntentContracts
  alias OrbitalDynamics.Schema.CandidateRefreshContactIntentRoutingContracts
  alias OrbitalDynamics.Schema.CandidateRefreshOperationalTimelineContracts
  alias OrbitalDynamics.Schema.CandidateRefreshProviderCounterofferContracts
  alias OrbitalDynamics.Schema.CandidateRefreshQualityGateContracts
  alias OrbitalDynamics.Schema.CandidateRefreshStationCalendarContracts
  alias OrbitalDynamics.Schema.CandidateRefreshTimelineChangeContracts
  alias OrbitalDynamics.Schema.CandidateRefreshTimelineLifecycleContracts
  alias OrbitalDynamics.Schema.CandidateRefreshTimelinePublicationContracts
  alias OrbitalDynamics.Schema.CandidateRefreshTimelineValidationContracts
  alias OrbitalDynamics.Schema.CandidateRefreshValidationReportContracts

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_nested_stable_id_array_map: 3,
      validate_stable_id_list: 3
    ]

  def validate_source_report_provenance(issues, %{"provenance" => %{} = provenance}, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_type("$.provenance", provenance, "source_reports", :map)
    |> validate_source_report_summaries(callbacks, Map.get(provenance, "source_reports"))
  end

  def validate_source_report_provenance(issues, _artifact, _callbacks), do: issues

  defp validate_source_report_summaries(issues, _callbacks, nil), do: issues

  defp validate_source_report_summaries(issues, callbacks, source_reports)
       when is_map(source_reports) do
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
        |> validate_operational_readiness_resource_context(callbacks, path, summary)
        |> validate_operational_readiness_adapter_boundary_context(callbacks, path, summary)
        |> validate_operational_readiness_cadence_import_context(callbacks, path, summary)
        |> validate_link_capacity_context(path, summary, callbacks)
        |> validate_constraint_context(path, summary, callbacks)
        |> validate_resource_projection_context(path, summary, callbacks)
        |> validate_resource_filter_context(path, summary, callbacks)
        |> validate_contact_allocation_context(path, summary, callbacks)
        |> validate_contact_contention_context(path, summary, callbacks)
        |> validate_candidate_rejection_context(path, summary, callbacks)
        |> validate_provider_counteroffer_context(path, summary, callbacks)
        |> validate_maneuver_review_context(path, summary, callbacks)
        |> validate_station_pressure_context(path, summary, callbacks)
        |> validate_contact_intent_context(path, summary, callbacks)
        |> validate_contact_filter_context(path, summary, callbacks)
        |> validate_station_calendar_context(path, summary, callbacks)
        |> validate_timeline_activity_context(path, summary, callbacks)
        |> validate_timeline_activity_lifecycle_context(path, summary, callbacks)
        |> validate_timeline_lifecycle_state_context(path, summary, callbacks)
        |> validate_timeline_activity_precondition_context(path, summary, callbacks)
        |> validate_timeline_integrity_context(path, summary, callbacks)
        |> validate_timeline_publication_context(path, summary, callbacks)
        |> validate_timeline_dependency_impact_context(path, summary, callbacks)
        |> validate_timeline_feedback_context(path, summary, callbacks)
        |> validate_timeline_diff_context(path, summary, callbacks)
        |> validate_timeline_transition_application_context(path, summary, callbacks)
        |> validate_operational_timeline_context(path, summary, callbacks)
        |> validate_quality_gate_context(path, summary, callbacks)
        |> validate_schema_validation_context(path, summary, callbacks)
        |> validate_model_acceptance_context(path, summary, callbacks)
        |> validate_freshness_context(path, summary, callbacks)
        |> validate_objective_gap_context(path, summary, callbacks)
        |> validate_refresh_budget_context(path, summary, callbacks)
        |> validate_validation_safety_case_context(path, summary, callbacks)
      else
        issues
      end
    end)
  end

  defp validate_source_report_summaries(issues, _callbacks, _source_reports), do: issues

  def validate_quality_gate_context(issues, path, summary, callbacks) when is_list(callbacks) do
    CandidateRefreshQualityGateContracts.validate(issues, path, summary)
  end

  def validate_schema_validation_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshValidationReportContracts.validate_schema_validation(issues, path, summary)
  end

  def validate_model_acceptance_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshValidationReportContracts.validate_model_acceptance(issues, path, summary)
  end

  def validate_freshness_context(issues, path, summary, callbacks) when is_list(callbacks) do
    CandidateRefreshCandidateSelectionContracts.validate_freshness(issues, path, summary)
  end

  def validate_objective_gap_context(issues, path, summary, callbacks) when is_list(callbacks) do
    issues =
      Enum.reduce(
        [
          "gap_row_count",
          "downlink_gap_row_count",
          "target_gap_row_count",
          "collection_latency_gap_row_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, path, summary, field)
        end
      )

    Enum.reduce(
      [
        "status_counts",
        "objective_type_counts",
        "term_key_counts",
        "ground_station_counts",
        "target_counts",
        "collection_counts",
        "source_activity_id_counts"
      ],
      issues,
      fn field, acc ->
        validate_non_negative_integer_count_map(acc, path <> ".#{field}", Map.get(summary, field))
      end
    )
  end

  def validate_refresh_budget_context(issues, path, summary, callbacks) when is_list(callbacks) do
    CandidateRefreshCandidateSelectionContracts.validate_refresh_budget(issues, path, summary)
  end

  def validate_validation_safety_case_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshValidationReportContracts.validate_safety_case(
      issues,
      path,
      summary,
      fn -> safety_case_count_fields(callbacks) end
    )
  end

  def validate_timeline_activity_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "invalid_activity_input_count"
    )
    |> validate_non_negative_integer_count_map(
      path <> ".invalid_activity_input_reason_counts",
      Map.get(summary, "invalid_activity_input_reason_counts")
    )
    |> validate_string_list_items(path, summary, "invalid_activity_input_reasons")
  end

  def validate_timeline_activity_lifecycle_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshTimelineLifecycleContracts.validate_activity_lifecycle(
      issues,
      path,
      summary
    )
  end

  def validate_timeline_lifecycle_state_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshTimelineLifecycleContracts.validate_lifecycle_state(issues, path, summary)
  end

  def validate_timeline_activity_precondition_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshTimelineValidationContracts.validate_activity_precondition(
      issues,
      path,
      summary
    )
  end

  def validate_timeline_publication_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshTimelinePublicationContracts.validate(issues, path, summary)
  end

  def validate_timeline_integrity_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshTimelineValidationContracts.validate_integrity(issues, path, summary)
  end

  def validate_timeline_dependency_impact_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshTimelineValidationContracts.validate_dependency_impact(issues, path, summary)
  end

  def validate_provider_counteroffer_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshProviderCounterofferContracts.validate(issues, path, summary)
  end

  def validate_timeline_feedback_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_type(path, summary, "input_keys", :list)
    |> validate_string_list_items(path, summary, "input_keys")
    |> validate_optional_count_maps(path, summary, [
      "status_counts",
      "feedback_kind_counts",
      "match_strategy_counts",
      "activity_id_counts",
      "cadence_import_status_counts"
    ])
  end

  def validate_timeline_diff_context(issues, path, summary, callbacks) when is_list(callbacks) do
    CandidateRefreshTimelineChangeContracts.validate_diff(issues, path, summary)
  end

  def validate_operational_timeline_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshOperationalTimelineContracts.validate(issues, path, summary)
  end

  def validate_timeline_transition_application_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshTimelineChangeContracts.validate_transition_application(
      issues,
      path,
      summary
    )
  end

  def validate_maneuver_review_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "maneuver_success_feedback_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "execution_uncertainty_declared_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "execution_uncertainty_missing_count"
    )
    |> expect_optional_type(path, summary, "input_keys", :list)
    |> validate_string_list_items(path, summary, "input_keys")
    |> validate_optional_count_maps(path, summary, [
      "maneuver_id_counts",
      "required_operator_action_counts"
    ])
  end

  def validate_link_capacity_context(issues, path, summary, callbacks) when is_list(callbacks) do
    validate_count_maps(issues, path, summary, [
      "ground_station_counts",
      "target_counts",
      "collection_counts",
      "selected_contact_id_counts",
      "actual_throughput_contact_id_counts"
    ])
  end

  def validate_constraint_context(issues, path, summary, callbacks) when is_list(callbacks) do
    validate_count_maps(issues, path, summary, [
      "constraint_metric_counts",
      "constraint_resource_counts",
      "constraint_spacecraft_counts"
    ])
  end

  def validate_resource_projection_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    validate_count_maps(issues, path, summary, [
      "resource_projection_spacecraft_counts",
      "resource_pressure_type_counts",
      "resource_pressure_activity_id_counts"
    ])
  end

  def validate_resource_filter_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> validate_count_maps(path, summary, [
      "resource_filter_spacecraft_counts",
      "resource_filter_resource_counts",
      "resource_filter_blocking_dimension_counts"
    ])
    |> validate_stable_id_list(
      path <> ".invalid_resource_summary_input_ids",
      Map.get(summary, "invalid_resource_summary_input_ids")
    )
  end

  def validate_contact_contention_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    validate_count_maps(issues, path, summary, [
      "contact_contention_ground_station_counts",
      "contact_contention_contact_id_counts"
    ])
  end

  def validate_contact_allocation_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    Enum.reduce(
      [
        "provider_reservation_no_request_contact_ids_by_direction_and_ground_station",
        "provider_reservation_request_contact_ids_by_direction_and_ground_station",
        "provider_reservation_review_contact_ids_by_direction_and_ground_station"
      ],
      issues,
      fn field, acc ->
        validate_nested_stable_id_array_map(acc, path <> ".#{field}", Map.get(summary, field))
      end
    )
  end

  def validate_candidate_rejection_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    validate_count_maps(issues, path, summary, [
      "candidate_rejection_candidate_id_counts",
      "candidate_rejection_ground_station_counts"
    ])
  end

  def validate_station_pressure_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "station_pressure_contact_count"
    )
    |> validate_count_maps(path, summary, [
      "station_pressure_ground_station_counts",
      "station_pressure_availability_counts",
      "station_pressure_precedence_availability_counts",
      "station_pressure_precedence_rank_counts"
    ])
  end

  def validate_contact_intent_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshContactIntentContracts.validate(issues, path, summary)
  end

  def validate_contact_filter_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> validate_stable_id_list(
      path <> ".invalid_contact_input_ids",
      Map.get(summary, "invalid_contact_input_ids")
    )
    |> expect_optional_non_negative_integer(path, summary, "station_suppression_count")
    |> validate_count_maps(path, summary, [
      "station_suppression_ground_station_counts",
      "station_suppression_availability_counts",
      "station_suppression_status_counts"
    ])
  end

  def validate_station_calendar_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshStationCalendarContracts.validate(issues, path, summary)
  end

  def validate_contact_intent_direction_routing(issues, path, value, summary, callbacks)
      when is_list(callbacks) do
    CandidateRefreshContactIntentRoutingContracts.validate(issues, path, value, summary)
  end

  defp validate_optional_count_maps(issues, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(path, summary, field, :map)
      |> validate_non_negative_integer_count_map(
        path <> ".#{field}",
        Map.get(summary, field)
      )
    end)
  end

  defp validate_count_maps(issues, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_non_negative_integer_count_map(acc, path <> ".#{field}", Map.get(summary, field))
    end)
  end

  defp validate_operational_readiness_resource_context(issues, callbacks, path, summary) do
    apply(Keyword.fetch!(callbacks, :validate_operational_readiness_resource_context), [
      issues,
      path,
      summary
    ])
  end

  defp validate_operational_readiness_adapter_boundary_context(
         issues,
         callbacks,
         path,
         summary
       ) do
    apply(Keyword.fetch!(callbacks, :validate_operational_readiness_adapter_boundary_context), [
      issues,
      path,
      summary
    ])
  end

  defp validate_operational_readiness_cadence_import_context(issues, callbacks, path, summary) do
    apply(Keyword.fetch!(callbacks, :validate_operational_readiness_cadence_import_context), [
      issues,
      path,
      summary
    ])
  end

  defp safety_case_count_fields(callbacks),
    do: apply(Keyword.fetch!(callbacks, :safety_case_count_fields), [])
end
