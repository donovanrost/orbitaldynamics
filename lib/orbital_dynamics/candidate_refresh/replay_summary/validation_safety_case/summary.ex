defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ValidationSafetyCase.Summary do
  @moduledoc false

  alias __MODULE__.{EvidenceCount, Pressure}

  def pressure_fields(safety_case_summary) do
    Pressure.fields(safety_case_summary)
  end

  def summary(safety_case_summary, summary_source, replay_scope) do
    source_report_row_count =
      EvidenceCount.count(safety_case_summary, "row_count")

    accepted_evidence_count =
      EvidenceCount.status_count(
        safety_case_summary,
        "accepted_for_use",
        "accepted_evidence_count"
      )

    review_required_evidence_count =
      EvidenceCount.status_count(
        safety_case_summary,
        "review_required",
        "review_required_evidence_count"
      )

    blocked_evidence_count =
      EvidenceCount.status_count(
        safety_case_summary,
        "blocked",
        "blocked_evidence_count"
      )

    model_review_required_count =
      summary_integer(safety_case_summary, "model_review_required_count")

    model_blocked_count = summary_integer(safety_case_summary, "model_blocked_count")

    readiness_review_required_count =
      summary_integer(safety_case_summary, "readiness_review_required_count")

    readiness_blocked_count = summary_integer(safety_case_summary, "readiness_blocked_count")
    quality_gate_review_count = summary_integer(safety_case_summary, "quality_gate_review_count")

    quality_gate_blocked_count =
      summary_integer(safety_case_summary, "quality_gate_blocked_count")

    schema_error_count = summary_integer(safety_case_summary, "schema_error_count")
    schema_warning_count = summary_integer(safety_case_summary, "schema_warning_count")

    schema_validation_failed_report_count =
      summary_integer(safety_case_summary, "schema_validation_failed_report_count")

    fixture_failed_count = summary_integer(safety_case_summary, "fixture_failed_count")
    status_counts = Map.get(safety_case_summary, "status_counts", %{})
    evidence_status_counts = Map.get(safety_case_summary, "evidence_status_counts", %{})
    input_contract_counts = Map.get(safety_case_summary, "input_contract_counts", %{})
    evidence_refs_by_status = Map.get(safety_case_summary, "evidence_refs_by_status", %{})

    evidence_refs_by_contract =
      Map.get(safety_case_summary, "evidence_refs_by_contract", %{})

    pressure_fields = pressure_fields(safety_case_summary)

    %{
      "model" => "artifact_only_candidate_refresh_validation_safety_case_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(
          safety_case_summary,
          "validation_safety_case_summary.v1"
        ),
      "source_report_count" => summary_integer(safety_case_summary, "count"),
      "source_report_row_count" => source_report_row_count,
      "source_report_paths" => Map.get(safety_case_summary, "paths", []),
      "status_counts" => status_counts,
      "evidence_status_counts" => evidence_status_counts,
      "input_contract_counts" => input_contract_counts,
      "evidence_refs_by_status" => evidence_refs_by_status,
      "evidence_refs_by_contract" => evidence_refs_by_contract,
      "accepted_evidence_count" => accepted_evidence_count,
      "review_required_evidence_count" => review_required_evidence_count,
      "blocked_evidence_count" => blocked_evidence_count,
      "model_accepted_count" => summary_integer(safety_case_summary, "model_accepted_count"),
      "model_review_required_count" => model_review_required_count,
      "model_blocked_count" => model_blocked_count,
      "unknown_model_count" => summary_integer(safety_case_summary, "unknown_model_count"),
      "readiness_review_required_count" => readiness_review_required_count,
      "readiness_blocked_count" => readiness_blocked_count,
      "ready_for_import_count" => summary_integer(safety_case_summary, "ready_for_import_count"),
      "quality_gate_review_count" => quality_gate_review_count,
      "quality_gate_blocked_count" => quality_gate_blocked_count,
      "schema_error_count" => schema_error_count,
      "schema_warning_count" => schema_warning_count,
      "schema_validation_report_count" =>
        summary_integer(safety_case_summary, "schema_validation_report_count"),
      "schema_validation_failed_report_count" => schema_validation_failed_report_count,
      "fixture_passed_count" => summary_integer(safety_case_summary, "fixture_passed_count"),
      "fixture_failed_count" => fixture_failed_count,
      "trust_boundary_status" => Map.get(safety_case_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(safety_case_summary, "trust_boundaries", []),
      "branch_local_review_pressure" => Map.get(pressure_fields, "branch_local_review_pressure"),
      "branch_local_blocking_pressure" =>
        Map.get(pressure_fields, "branch_local_blocking_pressure"),
      "branch_local_schema_pressure" => Map.get(pressure_fields, "branch_local_schema_pressure"),
      "branch_local_fixture_pressure" =>
        Map.get(pressure_fields, "branch_local_fixture_pressure"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_validation_safety_case_replay_summary",
        "safety_case_certification" => "not_performed_by_summary",
        "model_certification" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_validation_safety_case_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> compact_map()
  end

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0

  defp source_report_summary_contract(summary, default_contract) when map_size(summary) > 0 do
    case Map.get(summary, "contract", default_contract) do
      contract when is_binary(contract) and contract != "" -> contract
      _contract -> nil
    end
  end

  defp source_report_summary_contract(_summary, _default_contract), do: nil

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
