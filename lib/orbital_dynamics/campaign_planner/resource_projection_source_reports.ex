defmodule OrbitalDynamics.CampaignPlanner.ResourceProjectionSourceReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchRefreshSourceInputs,
    SourceReportArtifacts
  }

  @report_fields [
    {"source_resource_projection_report", "mission_state.source_resource_projection_report"},
    {"resource_projection_report", "mission_state.resource_projection_report"}
  ]

  @prior_report_fields [
    {"source_resource_projection_report", "prior_plan.source_resource_projection_report"},
    {"resource_projection_report", "prior_plan.resource_projection_report"}
  ]

  def reports(mission_state), do: reports(mission_state, default_callbacks())

  def reports(mission_state, opts) do
    mission_state = stringify_keys(mission_state || %{})

    direct_reports(mission_state, opts, @report_fields) ++
      result_artifact_reports(mission_state, "source_resource_projection_report", opts) ++
      result_artifact_reports(mission_state, "resource_projection_report", opts)
  end

  def source_reports(mission_state),
    do: reports(mission_state, "source_resource_projection_report", default_callbacks())

  def reports(mission_state, "source_resource_projection_report", opts) do
    direct_reports(mission_state, opts, [
      {"source_resource_projection_report", "mission_state.source_resource_projection_report"}
    ])
  end

  def reports(mission_state, "resource_projection_report", opts) do
    direct_reports(mission_state, opts, [
      {"resource_projection_report", "mission_state.resource_projection_report"}
    ])
  end

  def canonical_reports(mission_state),
    do: reports(mission_state, "resource_projection_report", default_callbacks())

  def flow_summaries(mission_state, "source_resource_projection_flow_summary") do
    BranchRefreshSourceInputs.resource_projection_flow_summaries(mission_state, [
      {"source_resource_projection_flow_summary",
       "mission_state.source_resource_projection_flow_summary"}
    ])
  end

  def flow_summaries(mission_state, "resource_projection_flow_summary") do
    BranchRefreshSourceInputs.resource_projection_flow_summaries(mission_state, [
      {"resource_projection_flow_summary", "mission_state.resource_projection_flow_summary"}
    ])
  end

  def flow_summary_result_artifacts(mission_state, artifact_key)
      when artifact_key in ["source_result_artifact", "result_artifact"] do
    BranchRefreshSourceInputs.resource_projection_flow_summary_result_artifacts(
      mission_state,
      artifact_key
    )
  end

  def candidate_refresh_source_inputs(mission_state) do
    mission_state
    |> source_report_candidate_refresh_inputs()
    |> Map.merge(flow_summary_result_artifact_candidate_refresh_inputs(mission_state))
  end

  def prior_plan_reports(prior_plan), do: prior_plan_reports(prior_plan, prior_plan_callbacks())

  def prior_plan_reports(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    SourceReportArtifacts.direct_reports(prior_plan, @prior_report_fields, &stringify_keys/1) ++
      prior_plan_result_artifact_reports(prior_plan, opts)
  end

  defp source_report_candidate_refresh_inputs(mission_state) do
    Map.new(candidate_refresh_source_input_collectors(), fn {key, collector} ->
      {key, BranchRefreshSourceInputs.source_reports_or_reports(mission_state, collector)}
    end)
  end

  defp candidate_refresh_source_input_collectors do
    [
      {"source_resource_projection_report", &source_reports/1},
      {"resource_projection_report", &canonical_reports/1},
      {"source_resource_projection_flow_summary",
       &flow_summaries(&1, "source_resource_projection_flow_summary")},
      {"resource_projection_flow_summary",
       &flow_summaries(&1, "resource_projection_flow_summary")}
    ]
  end

  defp flow_summary_result_artifact_candidate_refresh_inputs(mission_state) do
    Map.new(["source_result_artifact", "result_artifact"], fn artifact_key ->
      {artifact_key, flow_summary_result_artifacts(mission_state, artifact_key)}
    end)
  end

  defp direct_reports(mission_state, opts, fields) do
    SourceReportArtifacts.source_reports(mission_state, fields, opts, &stringify_keys/1)
  end

  defp result_artifact_reports(mission_state, report_key, opts) do
    SourceReportArtifacts.inherited_result_artifact_reports(
      mission_state,
      [report_key],
      opts,
      &stringify_keys/1
    )
  end

  defp prior_plan_result_artifact_reports(prior_plan, opts) do
    report_keys = Enum.map(@report_fields, &elem(&1, 0))
    SourceReportArtifacts.embedded_reports(prior_plan, report_keys, opts)
  end

  defp prior_plan_callbacks do
    [
      result_artifact_embedded_reports: &prior_plan_result_artifact_embedded_reports/2
    ]
  end

  defp prior_plan_result_artifact_embedded_reports(prior_plan, report_keys) do
    BranchRefreshSourceInputs.result_artifact_embedded_reports(
      prior_plan,
      "prior_plan",
      report_keys
    )
  end

  defp default_callbacks do
    [
      source_report_entries: &BranchRefreshSourceInputs.source_report_entries/2,
      result_artifacts_with_source: &mission_state_result_artifacts_with_source/1,
      put_inherited_result_artifact_trust_boundary:
        &BranchRefreshSourceInputs.put_inherited_result_artifact_trust_boundary/2
    ]
  end

  defp mission_state_result_artifacts_with_source(mission_state) do
    BranchRefreshSourceInputs.result_artifacts_with_source(mission_state, "mission_state")
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
