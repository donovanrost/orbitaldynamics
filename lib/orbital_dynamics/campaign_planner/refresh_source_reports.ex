defmodule OrbitalDynamics.CampaignPlanner.RefreshSourceReports do
  @moduledoc false

  def freshness_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_freshness_report", "mission_state.source_freshness_report"},
        {"freshness_report", "mission_state.freshness_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_freshness_report", opts) ++
      result_artifact_embedded_reports(mission_state, "freshness_report", opts)
  end

  def source_freshness_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_freshness_report", "mission_state.source_freshness_report"}
      ],
      opts
    )
  end

  def canonical_freshness_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"freshness_report", "mission_state.freshness_report"}
      ],
      opts
    )
  end

  def refresh_budget_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_refresh_budget_report", "mission_state.source_refresh_budget_report"},
        {"refresh_budget_report", "mission_state.refresh_budget_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_refresh_budget_report", opts) ++
      result_artifact_embedded_reports(mission_state, "refresh_budget_report", opts)
  end

  def source_refresh_budget_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_refresh_budget_report", "mission_state.source_refresh_budget_report"}
      ],
      opts
    )
  end

  def canonical_refresh_budget_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"refresh_budget_report", "mission_state.refresh_budget_report"}
      ],
      opts
    )
  end

  def refresh_reports(mission_state, "source_freshness_report", opts) do
    source_freshness_reports(mission_state, opts)
  end

  def refresh_reports(mission_state, "freshness_report", opts) do
    canonical_freshness_reports(mission_state, opts)
  end

  def refresh_reports(mission_state, "source_refresh_budget_report", opts) do
    source_refresh_budget_reports(mission_state, opts)
  end

  def refresh_reports(mission_state, "refresh_budget_report", opts) do
    canonical_refresh_budget_reports(mission_state, opts)
  end

  def pressure_rows(reports) do
    reports
    |> Enum.with_index(1)
    |> Enum.map(fn {{report, source_path}, index} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      {Map.put(report, "_source_report_trust_boundary", trust_boundary), source_path, index}
    end)
  end

  defp source_reports(mission_state, fields, opts) do
    callbacks = callbacks!(opts)
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      callbacks.source_report_entries.(Map.get(mission_state, field), source_path)
    end)
  end

  defp result_artifact_embedded_reports(mission_state, report_key, opts) do
    callbacks = callbacks!(opts)
    callbacks.result_artifact_embedded_reports.(mission_state, report_key)
  end

  defp callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports)
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
