defmodule OrbitalDynamics.Schema.CampaignRepairReadinessSourceContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate(issues, artifact) when is_map(artifact) do
    validate_report_pair(
      issues,
      Map.get(artifact, "source_operational_readiness_report"),
      Map.get(artifact, "source_quality_gate_report")
    )
  end

  defp validate_report_pair(issues, %{} = readiness, %{} = quality_gate) do
    issues
    |> validate_equal(
      "$.source_quality_gate_report.source_readiness_report_id",
      Map.get(quality_gate, "source_readiness_report_id"),
      Map.get(readiness, "report_id"),
      "must match the source operational-readiness report ID"
    )
    |> validate_equal(
      "$.source_quality_gate_report.source_artifact_type",
      Map.get(quality_gate, "source_artifact_type"),
      Map.get(readiness, "source_artifact_type"),
      "must match the source operational-readiness artifact type"
    )
    |> validate_equal(
      "$.source_quality_gate_report.source_artifact_id",
      Map.get(quality_gate, "source_artifact_id"),
      Map.get(readiness, "source_artifact_id"),
      "must match the source operational-readiness artifact ID"
    )
  end

  defp validate_report_pair(issues, _readiness, _quality_gate), do: issues

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [PrimitiveValidation.error(path, message) | issues]
end
