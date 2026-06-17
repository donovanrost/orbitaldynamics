defmodule OrbitalDynamics.CampaignPlanner.TimelineSourceReports.SourceEntries do
  @moduledoc false

  def source_report_entries(source, fields, opts) do
    callbacks = callbacks!(opts)

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      callbacks.source_report_entries.(Map.get(source, field), source_path)
    end)
  end

  def direct_single_report_entries(source, fields, opts) do
    callbacks = callbacks!(opts)

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      case Map.get(source, field) do
        %{} = report -> callbacks.source_report_entries.(report, source_path)
        _report -> []
      end
    end)
  end

  def mission_state_source_report_entries(source, fields, opts) do
    source = stringify_top_level_keys(source || %{})

    source_report_entries(source, fields, opts)
  end

  def mission_state_lifecycle_state_summary_entries(source, fields, opts) do
    source
    |> mission_state_source_report_entries(fields, opts)
    |> Enum.map(fn {summary, path} ->
      {put_timeline_lifecycle_state_summary_trust_boundary(summary), path}
    end)
  end

  def put_timeline_lifecycle_state_summary_trust_boundary(summary) do
    trust_boundary =
      Map.get(summary, "trust_boundary") ||
        get_in(summary, ["provenance", "trust_boundary"]) ||
        get_in(summary, ["metadata", "trust_boundary"])

    if trust_boundary in [nil, ""] do
      summary
    else
      Map.put(summary, "trust_boundary", trust_boundary)
    end
  end

  def callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      result_artifacts_with_source: Keyword.fetch!(opts, :result_artifacts_with_source),
      result_artifact_embedded_report_entries:
        Keyword.fetch!(opts, :result_artifact_embedded_report_entries),
      put_inherited_result_artifact_trust_boundary:
        Keyword.fetch!(opts, :put_inherited_result_artifact_trust_boundary),
      stringify_keys: Keyword.fetch!(opts, :stringify_keys),
      reject_empty_values: Keyword.fetch!(opts, :reject_empty_values)
    }
  end

  defp stringify_top_level_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end

  defp stringify_top_level_keys(_value), do: %{}
end
