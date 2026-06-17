defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ValidationSafetyCase.Summary.Pressure do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ValidationSafetyCase.Summary.EvidenceCount

  def fields(safety_case_summary) do
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

    contract_pressure = fn token ->
      input_contract_counts
      |> Enum.any?(fn
        {contract, count} when is_binary(contract) ->
          String.contains?(contract, token) and summary_integer(%{"count" => count}, "count") > 0

        _entry ->
          false
      end) or
        Enum.any?(evidence_refs_by_contract, fn
          {contract, refs} when is_binary(contract) and is_list(refs) ->
            String.contains?(contract, token) and refs != []

          _entry ->
            false
        end)
    end

    review_pressure_count =
      review_required_evidence_count + blocked_evidence_count + model_review_required_count +
        model_blocked_count + readiness_review_required_count + readiness_blocked_count +
        quality_gate_review_count + quality_gate_blocked_count + schema_error_count +
        schema_warning_count + schema_validation_failed_report_count + fixture_failed_count

    blocking_pressure =
      blocked_evidence_count + model_blocked_count + readiness_blocked_count +
        quality_gate_blocked_count > 0 or summary_integer(status_counts, "blocked") > 0 or
        summary_integer(evidence_status_counts, "blocked") > 0 or
        Map.get(evidence_refs_by_status, "blocked", []) != []

    schema_pressure =
      schema_error_count + schema_warning_count + schema_validation_failed_report_count > 0 or
        contract_pressure.("schema")

    fixture_pressure = fixture_failed_count > 0 or contract_pressure.("fixture")

    review_pressure =
      review_pressure_count > 0 or blocking_pressure or schema_pressure or fixture_pressure or
        summary_integer(status_counts, "review_required") > 0 or
        summary_integer(evidence_status_counts, "review_required") > 0 or
        Map.get(evidence_refs_by_status, "review_required", []) != []

    %{
      "branch_local_review_pressure" => review_pressure,
      "branch_local_blocking_pressure" => blocking_pressure,
      "branch_local_schema_pressure" => schema_pressure,
      "branch_local_fixture_pressure" => fixture_pressure
    }
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
end
