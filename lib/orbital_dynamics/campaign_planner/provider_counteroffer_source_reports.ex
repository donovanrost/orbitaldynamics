defmodule OrbitalDynamics.CampaignPlanner.ProviderCounterofferSourceReports do
  @moduledoc false

  alias __MODULE__.PressureRows
  alias OrbitalDynamics.CampaignPlanner.{BranchRefreshSourceInputs, SourceReportArtifacts}

  @report_fields [
    {"source_provider_counteroffer_report", "mission_state.source_provider_counteroffer_report"},
    {"provider_counteroffer_report", "mission_state.provider_counteroffer_report"}
  ]

  @plan_impact_summary_fields [
    {"source_provider_counteroffer_plan_impact_summary",
     "mission_state.source_provider_counteroffer_plan_impact_summary"},
    {"provider_counteroffer_plan_impact_summary",
     "mission_state.provider_counteroffer_plan_impact_summary"}
  ]

  @import_readiness_summary_fields [
    {"source_provider_counteroffer_import_readiness_summary",
     "mission_state.source_provider_counteroffer_import_readiness_summary"},
    {"provider_counteroffer_import_readiness_summary",
     "mission_state.provider_counteroffer_import_readiness_summary"}
  ]

  @review_summary_paths %{
    "source_provider_counteroffer_review_summary" =>
      "mission_state.source_provider_counteroffer_review_summary",
    "provider_counteroffer_review_summary" => "mission_state.provider_counteroffer_review_summary"
  }

  def reports(mission_state), do: reports(mission_state, default_callbacks())

  def reports(mission_state, opts) when is_list(opts) do
    source_reports(mission_state, @report_fields, opts) ++
      result_artifact_embedded_reports(mission_state, @report_fields, opts)
  end

  def source_reports(mission_state), do: source_reports(mission_state, default_callbacks())

  def source_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_provider_counteroffer_report",
         "mission_state.source_provider_counteroffer_report"}
      ],
      opts
    )
  end

  def source_reports_with_result_artifact_fallback(mission_state),
    do: source_reports_with_result_artifact_fallback(mission_state, default_callbacks())

  def source_reports_with_result_artifact_fallback(mission_state, opts) do
    SourceReportArtifacts.source_reports_with_embedded_fallback(
      mission_state,
      &source_reports(&1, opts),
      Enum.map(@report_fields, &elem(&1, 0)),
      opts,
      fn value -> value end
    )
  end

  def canonical_reports(mission_state), do: canonical_reports(mission_state, default_callbacks())

  def canonical_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"provider_counteroffer_report", "mission_state.provider_counteroffer_report"}
      ],
      opts
    )
  end

  def plan_impact_summaries(mission_state),
    do: plan_impact_summaries(mission_state, default_callbacks())

  def plan_impact_summaries(mission_state, opts) do
    source_reports(mission_state, @plan_impact_summary_fields, opts) ++
      result_artifact_embedded_reports(mission_state, @plan_impact_summary_fields, opts)
  end

  def source_plan_impact_summaries(mission_state),
    do: source_plan_impact_summaries(mission_state, default_callbacks())

  def source_plan_impact_summaries(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_provider_counteroffer_plan_impact_summary",
         "mission_state.source_provider_counteroffer_plan_impact_summary"}
      ],
      opts
    )
  end

  def canonical_plan_impact_summaries(mission_state),
    do: canonical_plan_impact_summaries(mission_state, default_callbacks())

  def canonical_plan_impact_summaries(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"provider_counteroffer_plan_impact_summary",
         "mission_state.provider_counteroffer_plan_impact_summary"}
      ],
      opts
    )
  end

  def import_readiness_summaries(mission_state),
    do: import_readiness_summaries(mission_state, default_callbacks())

  def import_readiness_summaries(mission_state, opts) do
    source_reports(mission_state, @import_readiness_summary_fields, opts) ++
      result_artifact_embedded_reports(mission_state, @import_readiness_summary_fields, opts)
  end

  def pressure_sources(mission_state) do
    reports(mission_state) ++
      plan_impact_summaries(mission_state) ++
      import_readiness_summaries(mission_state)
  end

  def source_import_readiness_summaries(mission_state),
    do: source_import_readiness_summaries(mission_state, default_callbacks())

  def source_import_readiness_summaries(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_provider_counteroffer_import_readiness_summary",
         "mission_state.source_provider_counteroffer_import_readiness_summary"}
      ],
      opts
    )
  end

  def canonical_import_readiness_summaries(mission_state),
    do: canonical_import_readiness_summaries(mission_state, default_callbacks())

  def canonical_import_readiness_summaries(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"provider_counteroffer_import_readiness_summary",
         "mission_state.provider_counteroffer_import_readiness_summary"}
      ],
      opts
    )
  end

  def review_summary(mission_state, summary_key) do
    review_summary(mission_state, summary_key, default_callbacks())
  end

  def review_summary(mission_state, summary_key, opts) do
    case Map.fetch(@review_summary_paths, summary_key) do
      {:ok, source_path} -> source_reports(mission_state, [{summary_key, source_path}], opts)
      :error -> []
    end
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
      {"source_provider_counteroffer_report", &source_reports_with_result_artifact_fallback/1},
      {"provider_counteroffer_report", &canonical_reports/1},
      {"source_provider_counteroffer_review_summary",
       &review_summary(&1, "source_provider_counteroffer_review_summary")},
      {"provider_counteroffer_review_summary",
       &review_summary(&1, "provider_counteroffer_review_summary")},
      {"source_provider_counteroffer_import_readiness_summary",
       &source_import_readiness_summaries/1},
      {"provider_counteroffer_import_readiness_summary", &canonical_import_readiness_summaries/1},
      {"source_provider_counteroffer_plan_impact_summary", &source_plan_impact_summaries/1},
      {"provider_counteroffer_plan_impact_summary", &canonical_plan_impact_summaries/1}
    ]

  defp source_reports(mission_state, fields, opts) do
    SourceReportArtifacts.source_reports(mission_state, fields, opts, &stringify_keys/1)
  end

  defp result_artifact_embedded_reports(mission_state, fields, opts) do
    fields
    |> Enum.map(&elem(&1, 0))
    |> then(&SourceReportArtifacts.embedded_reports(mission_state, &1, opts))
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
