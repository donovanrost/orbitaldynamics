defmodule OrbitalDynamics.Validation.ArtifactObservations.SchemaValidationBatchReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    reports = Map.get(artifact, "reports") || []

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "validation_mode" => Map.get(artifact, "validation_mode"),
      "input_dir" => Map.get(artifact, "input_dir"),
      "status" => Map.get(artifact, "status"),
      "status_counts" => Map.get(artifact, "status_counts"),
      "file_count" => Map.get(artifact, "file_count"),
      "artifact_count" => Map.get(artifact, "artifact_count"),
      "skipped_count" => Map.get(artifact, "skipped_count"),
      "error_count" => Map.get(artifact, "error_count"),
      "warning_count" => Map.get(artifact, "warning_count"),
      "remediation_count" => Map.get(artifact, "remediation_count"),
      "report_count" => length(reports),
      "pass_report_count" => schema_validation_batch_report_status_count(reports, "pass"),
      "fail_report_count" => schema_validation_batch_report_status_count(reports, "fail"),
      "skipped_artifact_count" => count(artifact, "skipped_artifacts"),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp schema_validation_batch_report_status_count(reports, status) when is_list(reports) do
    reports
    |> Enum.map(&stringify_keys/1)
    |> Enum.count(&(get_in(&1, ["report", "status"]) == status))
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
