defmodule OrbitalDynamics.CampaignPlanner.LinkCapacitySourceReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{BranchRefreshSourceInputs, SourceReportArtifacts}

  @report_paths %{
    "source_link_capacity_report" => "mission_state.source_link_capacity_report",
    "link_capacity_report" => "mission_state.link_capacity_report"
  }

  @report_fields [
    {"source_link_capacity_report", "mission_state.source_link_capacity_report"},
    {"link_capacity_report", "mission_state.link_capacity_report"},
    {"source_relay_data_path_summary", "mission_state.source_relay_data_path_summary"},
    {"relay_data_path_summary", "mission_state.relay_data_path_summary"}
  ]

  @prior_report_fields [
    {"source_link_capacity_report", "prior_plan.source_link_capacity_report"},
    {"link_capacity_report", "prior_plan.link_capacity_report"},
    {"source_relay_data_path_summary", "prior_plan.source_relay_data_path_summary"},
    {"relay_data_path_summary", "prior_plan.relay_data_path_summary"}
  ]

  @summary_paths %{
    "source_link_capacity_summary" => "mission_state.source_link_capacity_summary",
    "link_capacity_summary" => "mission_state.link_capacity_summary",
    "source_relay_data_path_summary" => "mission_state.source_relay_data_path_summary",
    "relay_data_path_summary" => "mission_state.relay_data_path_summary"
  }

  def reports(mission_state), do: reports(mission_state, default_callbacks())

  def reports(mission_state, opts) when is_list(opts) do
    mission_state = stringify_keys(mission_state || %{})

    source_reports(mission_state, @report_fields, opts) ++
      result_artifact_embedded_reports(
        mission_state,
        Enum.map(@report_fields, &elem(&1, 0)),
        opts
      )
  end

  def reports(mission_state, report_key) when is_binary(report_key) do
    reports(mission_state, report_key, default_callbacks())
  end

  def prior_plan_reports(prior_plan, opts \\ prior_plan_callbacks()) do
    prior_plan = stringify_keys(prior_plan || %{})

    SourceReportArtifacts.direct_reports(prior_plan, @prior_report_fields, &stringify_keys/1) ++
      prior_plan_result_artifact_reports(prior_plan, opts)
  end

  def candidate_refresh_source_inputs(mission_state) do
    report_inputs =
      @report_paths
      |> Map.keys()
      |> Map.new(fn report_key ->
        {report_key, candidate_refresh_report_input(mission_state, report_key)}
      end)

    summary_inputs =
      @summary_paths
      |> Map.keys()
      |> Map.new(fn summary_key ->
        {summary_key, candidate_refresh_summary_input(mission_state, summary_key)}
      end)

    Map.merge(report_inputs, summary_inputs)
  end

  def reports(mission_state, report_key, opts) do
    case Map.fetch(@report_paths, report_key) do
      {:ok, source_path} -> source_reports(mission_state, [{report_key, source_path}], opts)
      :error -> []
    end
  end

  def summaries(mission_state, summary_key) do
    summaries(mission_state, summary_key, default_callbacks())
  end

  def summaries(mission_state, summary_key, opts) do
    case Map.fetch(@summary_paths, summary_key) do
      {:ok, source_path} -> source_reports(mission_state, [{summary_key, source_path}], opts)
      :error -> []
    end
  end

  defp source_reports(mission_state, fields, opts) do
    SourceReportArtifacts.source_reports(mission_state, fields, opts, &stringify_keys/1)
  end

  defp candidate_refresh_report_input(mission_state, report_key) do
    BranchRefreshSourceInputs.source_reports_or_reports(
      mission_state,
      &reports(&1, report_key)
    )
  end

  defp candidate_refresh_summary_input(mission_state, summary_key) do
    BranchRefreshSourceInputs.source_reports_or_reports(
      mission_state,
      &summaries(&1, summary_key)
    )
  end

  defp result_artifact_embedded_reports(mission_state, report_keys, opts) do
    SourceReportArtifacts.embedded_reports(mission_state, report_keys, opts)
  end

  defp prior_plan_result_artifact_reports(prior_plan, opts) do
    report_keys = Enum.map(@report_fields, &elem(&1, 0))
    SourceReportArtifacts.embedded_reports(prior_plan, report_keys, opts)
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
