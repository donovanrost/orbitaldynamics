defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_report_field_values: 2,
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      numeric_report_count: 2,
      sorted_string_values: 1,
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1,
      sum_report_count: 2
    ]

  def report_input_summary([], _callbacks), do: nil

  def report_input_summary(sources, callbacks) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => callback!(callbacks, :operational_readiness_input_summary_contract).(reports),
      "count" => length(sources),
      "row_count" => length(sources),
      "source_summary_model_counts" => count_report_field_values(reports, "source_summary_model"),
      "source_summary_schema_contract_counts" =>
        count_report_field_values(reports, "source_summary_schema_contract"),
      "source_artifact_type_counts" => count_report_field_values(reports, "source_artifact_type"),
      "readiness_level_counts" => count_report_field_values(reports, "readiness_level"),
      "import_classification_counts" =>
        count_report_field_values(reports, "import_classification"),
      "status_counts" => count_report_field_values(reports, "status"),
      "import_eligible_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :operational_readiness_import_eligible_count)
        ),
      "import_ineligible_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :operational_readiness_import_ineligible_count)
        ),
      "execution_boundary_counts" => count_report_field_values(reports, "execution_boundary"),
      "analysis_mode_source_counts" => count_report_field_values(reports, "analysis_mode_source"),
      "handoff_only_count" => boolean_count_sum(reports, callbacks, "handoff_only", true),
      "execution_allowed_count" =>
        boolean_count_sum(reports, callbacks, "execution_allowed", true),
      "execution_denied_count" =>
        boolean_count_sum(reports, callbacks, "execution_allowed", false),
      "cadence_write_allowed_count" =>
        boolean_count_sum(reports, callbacks, "cadence_write_allowed", true),
      "cadence_write_denied_count" =>
        boolean_count_sum(reports, callbacks, "cadence_write_allowed", false),
      "operator_authority_granted_count" =>
        boolean_count_sum(reports, callbacks, "operator_authority_granted", true),
      "operator_authority_denied_count" =>
        boolean_count_sum(reports, callbacks, "operator_authority_granted", false),
      "gate_count" =>
        sum_report_count(reports, callback!(callbacks, :operational_readiness_report_gate_count)),
      "passed_gate_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "passed_gate_count")),
      "review_gate_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "review_gate_count")),
      "analysis_gate_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "analysis_gate_count")),
      "analysis_mode_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :operational_readiness_analysis_mode_counts))
        |> merge_count_maps(),
      "blocked_gate_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "blocked_gate_count")),
      "non_passed_gate_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "non_passed_gate_count")),
      "gate_status_counts" =>
        reports
        |> Enum.map(
          &callback!(callbacks, :operational_readiness_count_map).(&1, "gate_status_counts")
        )
        |> merge_count_maps(),
      "gate_classification_counts" =>
        reports
        |> Enum.map(
          &callback!(callbacks, :operational_readiness_count_map).(
            &1,
            "gate_classification_counts"
          )
        )
        |> merge_count_maps(),
      "gate_ids_by_status" =>
        reports
        |> Enum.map(callback!(callbacks, :operational_readiness_gate_ids_by_status))
        |> merge_string_list_maps(),
      "gate_ids_by_classification" =>
        reports
        |> Enum.map(callback!(callbacks, :operational_readiness_gate_ids_by_classification))
        |> merge_string_list_maps(),
      "passed_gate_ids" =>
        reports
        |> Enum.flat_map(
          &callback!(callbacks, :operational_readiness_string_list).(&1, "passed_gate_ids")
        )
        |> sorted_string_values(),
      "review_required_gate_ids" =>
        reports
        |> Enum.flat_map(
          &callback!(callbacks, :operational_readiness_gate_ids_for_status).(
            &1,
            "review_required",
            "review_required_gate_ids"
          )
        )
        |> sorted_string_values(),
      "analysis_only_gate_ids" =>
        reports
        |> Enum.flat_map(
          &callback!(callbacks, :operational_readiness_gate_ids_for_status).(
            &1,
            "analysis_only",
            "analysis_only_gate_ids"
          )
        )
        |> sorted_string_values(),
      "blocked_gate_ids" =>
        reports
        |> Enum.flat_map(
          &callback!(callbacks, :operational_readiness_gate_ids_for_status).(
            &1,
            "blocked",
            "blocked_gate_ids"
          )
        )
        |> sorted_string_values(),
      "non_passed_gate_ids" =>
        reports
        |> Enum.flat_map(callback!(callbacks, :operational_readiness_non_passed_gate_ids))
        |> sorted_string_values(),
      "ready_for_import_count" =>
        evidence_count_sum(reports, callbacks, "ready_for_import_count"),
      "manifest_review_required_count" =>
        evidence_count_sum(reports, callbacks, "manifest_review_required_count"),
      "blocked_import_count" => evidence_count_sum(reports, callbacks, "blocked_import_count"),
      "missing_import_count" => evidence_count_sum(reports, callbacks, "missing_import_count"),
      "invalid_cadence_import_count" =>
        evidence_count_sum(reports, callbacks, "invalid_cadence_import_count"),
      "review_required_count" => evidence_count_sum(reports, callbacks, "review_required_count"),
      "current_freshness_count" =>
        evidence_count_sum(reports, callbacks, "current_freshness_count"),
      "stale_freshness_count" => evidence_count_sum(reports, callbacks, "stale_freshness_count"),
      "unknown_freshness_count" =>
        evidence_count_sum(reports, callbacks, "unknown_freshness_count"),
      "freshness_status_counts" =>
        reports
        |> Enum.map(
          &callback!(callbacks, :operational_readiness_evidence_count_map).(
            &1,
            "freshness_status_counts"
          )
        )
        |> merge_count_maps(),
      "schema_validation_pass_count" =>
        evidence_count_sum(reports, callbacks, "schema_validation_pass_count"),
      "schema_validation_fail_count" =>
        evidence_count_sum(reports, callbacks, "schema_validation_fail_count"),
      "schema_validation_error_count" =>
        evidence_count_sum(reports, callbacks, "schema_validation_error_count"),
      "schema_validation_warning_count" =>
        evidence_count_sum(reports, callbacks, "schema_validation_warning_count"),
      "schema_validation_remediation_count" =>
        evidence_count_sum(reports, callbacks, "schema_validation_remediation_count"),
      "schema_validation_status_counts" =>
        reports
        |> Enum.map(
          &callback!(callbacks, :operational_readiness_evidence_count_map).(
            &1,
            "schema_validation_status_counts"
          )
        )
        |> merge_count_maps(),
      "import_status_counts" =>
        reports
        |> Enum.map(
          &callback!(callbacks, :operational_readiness_evidence_count_map).(
            &1,
            "import_status_counts"
          )
        )
        |> merge_count_maps(),
      "cadence_import_status_counts" =>
        reports
        |> Enum.map(
          &callback!(callbacks, :operational_readiness_evidence_count_map).(
            &1,
            "cadence_import_status_counts"
          )
        )
        |> merge_count_maps(),
      "source_model_limit_count" =>
        evidence_count_sum(reports, callbacks, "source_model_limit_count"),
      "adapter_context_count" => evidence_count_sum(reports, callbacks, "adapter_context_count"),
      "adapter_trust_boundary_declared_count" =>
        evidence_count_sum(reports, callbacks, "adapter_trust_boundary_declared_count"),
      "adapter_trust_boundary_missing_count" =>
        evidence_count_sum(reports, callbacks, "adapter_trust_boundary_missing_count"),
      "adapter_trust_boundary_untrusted_count" =>
        evidence_count_sum(reports, callbacks, "adapter_trust_boundary_untrusted_count"),
      "adapter_boundary_status_counts" =>
        reports
        |> Enum.map(
          &callback!(callbacks, :operational_readiness_evidence_count_map).(
            &1,
            "adapter_boundary_status_counts"
          )
        )
        |> merge_count_maps(),
      "resource_availability_pressure_count" =>
        evidence_count_sum(reports, callbacks, "resource_availability_pressure_count"),
      "resource_availability_reason_counts" =>
        reports
        |> Enum.map(
          &callback!(callbacks, :operational_readiness_evidence_count_map).(
            &1,
            "resource_availability_reason_counts"
          )
        )
        |> merge_count_maps(),
      "resource_availability_reason_ids" =>
        reports
        |> Enum.flat_map(callback!(callbacks, :operational_readiness_resource_reason_ids))
        |> sorted_non_empty_values(),
      "station_availability_reason_ids" =>
        reports
        |> Enum.flat_map(callback!(callbacks, :operational_readiness_station_reason_ids))
        |> sorted_non_empty_values(),
      "station_availability_reason_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :operational_readiness_station_reason_counts))
        |> merge_count_maps(),
      "unavailable_resource_reason_ids" =>
        reports
        |> Enum.flat_map(
          callback!(callbacks, :operational_readiness_unavailable_resource_reason_ids)
        )
        |> sorted_non_empty_values(),
      "resource_blocking_dimension_counts" =>
        reports
        |> Enum.map(
          &callback!(callbacks, :operational_readiness_evidence_count_map).(
            &1,
            "resource_blocking_dimension_counts"
          )
        )
        |> merge_count_maps(),
      "review_type_counts" =>
        reports
        |> Enum.map(
          &callback!(callbacks, :operational_readiness_evidence_count_map).(
            &1,
            "review_type_counts"
          )
        )
        |> merge_count_maps(),
      "import_action_counts" =>
        reports
        |> Enum.map(
          &callback!(callbacks, :operational_readiness_evidence_count_map).(
            &1,
            "import_action_counts"
          )
        )
        |> merge_count_maps(),
      "source_review_type_counts" =>
        reports
        |> Enum.map(
          &callback!(callbacks, :operational_readiness_evidence_count_map).(
            &1,
            "source_review_type_counts"
          )
        )
        |> merge_count_maps(),
      "trust_boundary_status" => source_report_trust_boundary_status(reports),
      "trust_boundaries" => source_report_trust_boundaries(reports)
    }
    |> Map.merge(
      callback!(callbacks, :operational_readiness_timeline_publication_input_summary).(reports)
    )
    |> compact_map()
  end

  defp boolean_count_sum(reports, callbacks, field, expected) do
    counter = callback!(callbacks, :operational_readiness_boolean_count)
    sum_report_count(reports, &counter.(&1, field, expected))
  end

  defp evidence_count_sum(reports, callbacks, field) do
    counter = callback!(callbacks, :operational_readiness_evidence_count)
    sum_report_count(reports, &counter.(&1, field))
  end

  defp sorted_non_empty_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
