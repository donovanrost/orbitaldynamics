defmodule OrbitalDynamics.CampaignPlanner.ModelAcceptanceSourceReports do
  @moduledoc false

  alias __MODULE__.PressureRows
  alias OrbitalDynamics.CampaignPlanner.{BranchRefreshSourceInputs, SourceReportArtifacts}

  def model_acceptance_reports(mission_state, opts \\ default_callbacks())

  def model_acceptance_reports(mission_state, opts) when is_list(opts) do
    mission_state = stringify_keys(mission_state || %{})

    source_reports(
      mission_state,
      [
        {"source_model_acceptance_report", "mission_state.source_model_acceptance_report"},
        {"model_acceptance_report", "mission_state.model_acceptance_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_model_acceptance_report", opts) ++
      result_artifact_embedded_reports(mission_state, "model_acceptance_report", opts)
  end

  def model_acceptance_reports(mission_state, "source_model_acceptance_report") do
    source_model_acceptance_reports(mission_state)
  end

  def model_acceptance_reports(mission_state, "model_acceptance_report") do
    canonical_model_acceptance_reports(mission_state)
  end

  def model_acceptance_reports(mission_state, "source_model_acceptance_report", opts) do
    source_model_acceptance_reports(mission_state, opts)
  end

  def model_acceptance_reports(mission_state, "model_acceptance_report", opts) do
    canonical_model_acceptance_reports(mission_state, opts)
  end

  def source_model_acceptance_reports(mission_state, opts \\ default_callbacks()) do
    source_reports(
      mission_state,
      [
        {"source_model_acceptance_report", "mission_state.source_model_acceptance_report"}
      ],
      opts
    )
  end

  def canonical_model_acceptance_reports(mission_state, opts \\ default_callbacks()) do
    source_reports(
      mission_state,
      [
        {"model_acceptance_report", "mission_state.model_acceptance_report"}
      ],
      opts
    )
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
      {"source_model_acceptance_report",
       &model_acceptance_reports(&1, "source_model_acceptance_report")},
      {"model_acceptance_report", &model_acceptance_reports(&1, "model_acceptance_report")}
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
