defmodule OrbitalDynamics.CampaignPlanner.RefreshSourceReports do
  @moduledoc false

  alias __MODULE__.PressureRows
  alias OrbitalDynamics.CampaignPlanner.{BranchRefreshSourceInputs, SourceReportArtifacts}

  def freshness_reports(mission_state), do: freshness_reports(mission_state, default_callbacks())

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

  def source_freshness_reports(mission_state),
    do: source_freshness_reports(mission_state, default_callbacks())

  def source_freshness_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_freshness_report", "mission_state.source_freshness_report"}
      ],
      opts
    )
  end

  def canonical_freshness_reports(mission_state),
    do: canonical_freshness_reports(mission_state, default_callbacks())

  def canonical_freshness_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"freshness_report", "mission_state.freshness_report"}
      ],
      opts
    )
  end

  def refresh_budget_reports(mission_state),
    do: refresh_budget_reports(mission_state, default_callbacks())

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

  def source_refresh_budget_reports(mission_state),
    do: source_refresh_budget_reports(mission_state, default_callbacks())

  def source_refresh_budget_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_refresh_budget_report", "mission_state.source_refresh_budget_report"}
      ],
      opts
    )
  end

  def canonical_refresh_budget_reports(mission_state),
    do: canonical_refresh_budget_reports(mission_state, default_callbacks())

  def canonical_refresh_budget_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"refresh_budget_report", "mission_state.refresh_budget_report"}
      ],
      opts
    )
  end

  def refresh_reports(mission_state, report_key) do
    refresh_reports(mission_state, report_key, default_callbacks())
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

  def candidate_refresh_source_inputs(mission_state) do
    Map.new(candidate_refresh_source_input_collectors(), fn {key, collector} ->
      {key, BranchRefreshSourceInputs.source_reports_or_reports(mission_state, collector)}
    end)
  end

  def pressure_rows(reports) do
    PressureRows.pressure_rows(reports)
  end

  defp candidate_refresh_source_input_collectors,
    do: [
      {"source_freshness_report", &refresh_reports(&1, "source_freshness_report")},
      {"freshness_report", &refresh_reports(&1, "freshness_report")},
      {"source_refresh_budget_report", &refresh_reports(&1, "source_refresh_budget_report")},
      {"refresh_budget_report", &refresh_reports(&1, "refresh_budget_report")}
    ]

  defp source_reports(mission_state, fields, opts) do
    SourceReportArtifacts.source_reports(mission_state, fields, opts, &stringify_keys/1)
  end

  defp result_artifact_embedded_reports(mission_state, report_key, opts) do
    SourceReportArtifacts.embedded_reports(mission_state, report_key, opts)
  end

  defp default_callbacks do
    [
      source_report_entries: &BranchRefreshSourceInputs.source_report_entries/2,
      result_artifact_embedded_reports: &mission_state_result_artifact_embedded_reports/2
    ]
  end

  defp mission_state_result_artifact_embedded_reports(mission_state, report_keys) do
    BranchRefreshSourceInputs.result_artifact_embedded_reports(
      mission_state,
      "mission_state",
      report_keys
    )
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
