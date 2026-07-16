defmodule OrbitalDynamics.Validation.ArtifactObservations.ValidationSafetyCaseSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    model_acceptance_evidence =
      safety_case_evidence_by_contract(artifact, "model_acceptance_report.v1")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "summary_id" => Map.get(artifact, "summary_id"),
      "case_id" => Map.get(artifact, "case_id"),
      "status" => Map.get(artifact, "status"),
      "evidence_count" => Map.get(artifact, "evidence_count"),
      "accepted_evidence_count" => Map.get(artifact, "accepted_evidence_count"),
      "review_required_evidence_count" => Map.get(artifact, "review_required_evidence_count"),
      "blocked_evidence_count" => Map.get(artifact, "blocked_evidence_count"),
      "model_accepted_count" => Map.get(artifact, "model_accepted_count"),
      "model_review_required_count" => Map.get(artifact, "model_review_required_count"),
      "model_blocked_count" => Map.get(artifact, "model_blocked_count"),
      "unknown_model_count" => Map.get(artifact, "unknown_model_count"),
      "readiness_review_required_count" => Map.get(artifact, "readiness_review_required_count"),
      "readiness_blocked_count" => Map.get(artifact, "readiness_blocked_count"),
      "ready_for_import_count" => Map.get(artifact, "ready_for_import_count"),
      "quality_gate_review_count" => Map.get(artifact, "quality_gate_review_count"),
      "quality_gate_blocked_count" => Map.get(artifact, "quality_gate_blocked_count"),
      "schema_error_count" => Map.get(artifact, "schema_error_count"),
      "schema_warning_count" => Map.get(artifact, "schema_warning_count"),
      "schema_validation_report_count" => Map.get(artifact, "schema_validation_report_count"),
      "schema_validation_failed_report_count" =>
        Map.get(artifact, "schema_validation_failed_report_count"),
      "fixture_passed_count" => Map.get(artifact, "fixture_passed_count"),
      "fixture_failed_count" => Map.get(artifact, "fixture_failed_count"),
      "input_contract_count" => count(artifact, "input_contracts"),
      "evidence_status_counts" => Map.get(artifact, "evidence_status_counts") || %{},
      "model_acceptance_evidence_status_counts" =>
        Map.get(model_acceptance_evidence, "status_counts") || %{},
      "model_acceptance_evidence_model_ids_by_status" =>
        Map.get(model_acceptance_evidence, "model_ids_by_status") || %{},
      "model_acceptance_evidence_model_ids_by_validation_level" =>
        Map.get(model_acceptance_evidence, "model_ids_by_validation_level") || %{},
      "model_acceptance_evidence_model_ids_by_intended_use" =>
        Map.get(model_acceptance_evidence, "model_ids_by_intended_use") || %{},
      "evidence_refs_by_status" => Map.get(artifact, "evidence_refs_by_status") || %{},
      "evidence_refs_by_contract" => Map.get(artifact, "evidence_refs_by_contract") || %{},
      "model_limit_count" => count(artifact, "model_limits"),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "certification_authority" => get_in(artifact, ["assumptions", "certification_authority"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"])
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp safety_case_evidence_by_contract(artifact, contract) do
    artifact
    |> Map.get("evidence", [])
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.find(%{}, &(&1["schema_contract"] == contract))
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)

  defp stringify_keys(value), do: value
end
