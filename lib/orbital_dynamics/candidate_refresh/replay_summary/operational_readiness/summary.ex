defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalReadiness.Summary do
  @moduledoc false

  alias __MODULE__.Pressure
  alias __MODULE__.ReadinessFields

  def pressure_fields(readiness_summary) do
    Pressure.fields(readiness_summary, ReadinessFields.fields(readiness_summary))
  end

  def summary(readiness_summary, summary_source, replay_scope, timeline_publication_context) do
    review_gate_count = summary_integer(readiness_summary, "review_gate_count")
    blocked_gate_count = summary_integer(readiness_summary, "blocked_gate_count")
    review_required_count = summary_integer(readiness_summary, "review_required_count")
    import_review_count = summary_integer(readiness_summary, "manifest_review_required_count")
    missing_import_count = summary_integer(readiness_summary, "missing_import_count")
    blocked_import_count = summary_integer(readiness_summary, "blocked_import_count")
    invalid_import_count = summary_integer(readiness_summary, "invalid_cadence_import_count")
    import_eligible_count = summary_integer(readiness_summary, "import_eligible_count")
    import_ineligible_count = summary_integer(readiness_summary, "import_ineligible_count")
    non_passed_gate_count = summary_integer(readiness_summary, "non_passed_gate_count")
    handoff_only_count = summary_integer(readiness_summary, "handoff_only_count")
    execution_allowed_count = summary_integer(readiness_summary, "execution_allowed_count")
    execution_denied_count = summary_integer(readiness_summary, "execution_denied_count")

    cadence_write_allowed_count =
      summary_integer(readiness_summary, "cadence_write_allowed_count")

    cadence_write_denied_count = summary_integer(readiness_summary, "cadence_write_denied_count")

    operator_authority_granted_count =
      summary_integer(readiness_summary, "operator_authority_granted_count")

    operator_authority_denied_count =
      summary_integer(readiness_summary, "operator_authority_denied_count")

    resource_pressure_count =
      summary_integer(readiness_summary, "resource_availability_pressure_count")

    readiness_fields = ReadinessFields.fields(readiness_summary)
    pressure_fields = Pressure.fields(readiness_summary, readiness_fields)

    %{
      "model" => "artifact_only_candidate_refresh_operational_readiness_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(readiness_summary, "operational_readiness_report.v1"),
      "source_report_count" => summary_integer(readiness_summary, "count"),
      "source_report_row_count" => summary_integer(readiness_summary, "row_count"),
      "source_report_paths" => Map.get(readiness_summary, "paths", []),
      "import_eligible_count" => import_eligible_count,
      "import_ineligible_count" => import_ineligible_count,
      "handoff_only_count" => handoff_only_count,
      "execution_allowed_count" => execution_allowed_count,
      "execution_denied_count" => execution_denied_count,
      "cadence_write_allowed_count" => cadence_write_allowed_count,
      "cadence_write_denied_count" => cadence_write_denied_count,
      "operator_authority_granted_count" => operator_authority_granted_count,
      "operator_authority_denied_count" => operator_authority_denied_count,
      "gate_count" => summary_integer(readiness_summary, "gate_count"),
      "passed_gate_count" => summary_integer(readiness_summary, "passed_gate_count"),
      "review_gate_count" => review_gate_count,
      "analysis_gate_count" => summary_integer(readiness_summary, "analysis_gate_count"),
      "blocked_gate_count" => blocked_gate_count,
      "non_passed_gate_count" => non_passed_gate_count,
      "ready_for_import_count" => summary_integer(readiness_summary, "ready_for_import_count"),
      "manifest_review_required_count" => import_review_count,
      "blocked_import_count" => blocked_import_count,
      "missing_import_count" => missing_import_count,
      "invalid_cadence_import_count" => invalid_import_count,
      "review_required_count" => review_required_count,
      "current_freshness_count" => summary_integer(readiness_summary, "current_freshness_count"),
      "stale_freshness_count" => summary_integer(readiness_summary, "stale_freshness_count"),
      "unknown_freshness_count" => summary_integer(readiness_summary, "unknown_freshness_count"),
      "schema_validation_pass_count" =>
        summary_integer(readiness_summary, "schema_validation_pass_count"),
      "schema_validation_fail_count" =>
        summary_integer(readiness_summary, "schema_validation_fail_count"),
      "schema_validation_error_count" =>
        summary_integer(readiness_summary, "schema_validation_error_count"),
      "schema_validation_warning_count" =>
        summary_integer(readiness_summary, "schema_validation_warning_count"),
      "schema_validation_remediation_count" =>
        summary_integer(readiness_summary, "schema_validation_remediation_count"),
      "adapter_trust_boundary_missing_count" =>
        summary_integer(readiness_summary, "adapter_trust_boundary_missing_count"),
      "adapter_trust_boundary_untrusted_count" =>
        summary_integer(readiness_summary, "adapter_trust_boundary_untrusted_count"),
      "resource_availability_pressure_count" => resource_pressure_count,
      "trust_boundary_status" => Map.get(readiness_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(readiness_summary, "trust_boundaries", []),
      "branch_local_review_pressure" => Map.get(pressure_fields, "branch_local_review_pressure"),
      "branch_local_import_pressure" => Map.get(pressure_fields, "branch_local_import_pressure"),
      "branch_local_execution_boundary_pressure" =>
        Map.get(pressure_fields, "branch_local_execution_boundary_pressure"),
      "branch_local_resource_pressure" =>
        Map.get(pressure_fields, "branch_local_resource_pressure"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_operational_readiness_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(readiness_fields)
    |> Map.merge(timeline_publication_context)
    |> compact_map()
  end

  defp source_report_summary_contract(summary, default_contract) when map_size(summary) > 0 do
    case Map.get(summary, "contract", default_contract) do
      contract when is_binary(contract) and contract != "" -> contract
      _contract -> nil
    end
  end

  defp source_report_summary_contract(_summary, _default_contract), do: nil

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(value) do
          {parsed, ""} -> parsed
          _other -> 0
        end

      _other ->
        0
    end
  end

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
