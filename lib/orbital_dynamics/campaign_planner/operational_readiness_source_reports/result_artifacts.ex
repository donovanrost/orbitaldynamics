defmodule OrbitalDynamics.CampaignPlanner.OperationalReadinessSourceReports.ResultArtifacts do
  @moduledoc false

  def operational_readiness_reports(prior_plan, opts) do
    callbacks = callbacks!(opts)

    prior_plan
    |> callbacks.result_artifacts_with_source.()
    |> Enum.flat_map(fn {artifact, source_path} ->
      operational_readiness_reports(artifact, source_path, callbacks)
    end)
  end

  def operational_readiness_gate_summaries(prior_plan, opts) do
    callbacks = callbacks!(opts)

    prior_plan
    |> callbacks.result_artifacts_with_source.()
    |> Enum.flat_map(fn {artifact, source_path} ->
      operational_readiness_gate_summaries(artifact, source_path, callbacks)
    end)
  end

  defp operational_readiness_reports(artifact, source_path, callbacks) do
    artifact = stringify_keys(artifact)

    if artifact["schema_contract"] == "operational_readiness_report.v1" do
      [{callbacks.put_inherited_result_artifact_trust_boundary.(artifact, artifact), source_path}]
    else
      ["source_operational_readiness_report", "operational_readiness_report"]
      |> Enum.flat_map(fn report_key ->
        embedded_report_entries(
          Map.get(artifact, report_key),
          artifact,
          "#{source_path}.#{report_key}",
          callbacks
        )
      end)
    end
  end

  defp operational_readiness_gate_summaries(artifact, source_path, callbacks) do
    artifact = stringify_keys(artifact)

    if artifact["schema_contract"] == "operational_readiness_gate_summary.v1" do
      [{callbacks.put_inherited_result_artifact_trust_boundary.(artifact, artifact), source_path}]
    else
      ["source_operational_readiness_gate_summary", "operational_readiness_gate_summary"]
      |> Enum.flat_map(fn summary_key ->
        embedded_report_entries(
          Map.get(artifact, summary_key),
          artifact,
          "#{source_path}.#{summary_key}",
          callbacks
        )
      end)
    end
  end

  defp embedded_report_entries(reports, artifact, source_path, callbacks) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      embedded_report_entries(
        report,
        artifact,
        "#{source_path}[#{index}]",
        callbacks
      )
    end)
  end

  defp embedded_report_entries(%{} = report, artifact, source_path, callbacks) do
    report =
      report
      |> stringify_keys()
      |> callbacks.put_inherited_result_artifact_trust_boundary.(artifact)

    [{report, source_path}]
  end

  defp embedded_report_entries(_report, _artifact, _source_path, _callbacks), do: []

  defp callbacks!(opts) do
    %{
      result_artifacts_with_source: Keyword.fetch!(opts, :result_artifacts_with_source),
      put_inherited_result_artifact_trust_boundary:
        Keyword.fetch!(opts, :put_inherited_result_artifact_trust_boundary)
    }
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
