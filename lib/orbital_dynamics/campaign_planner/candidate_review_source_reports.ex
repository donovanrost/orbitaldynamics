defmodule OrbitalDynamics.CampaignPlanner.CandidateReviewSourceReports do
  @moduledoc false

  alias __MODULE__.PressureRows
  alias OrbitalDynamics.CampaignPlanner.{BranchRefreshSourceInputs, SourceReportArtifacts}

  def candidate_diff_reports(mission_state, opts \\ default_callbacks()) do
    source_reports(
      mission_state,
      [
        {"source_candidate_diff_report", "mission_state.source_candidate_diff_report"},
        {"candidate_diff_report", "mission_state.candidate_diff_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_candidate_diff_report", opts) ++
      result_artifact_embedded_reports(mission_state, "candidate_diff_report", opts)
  end

  def source_candidate_diff_reports(mission_state, opts \\ default_callbacks()) do
    source_reports(
      mission_state,
      [
        {"source_candidate_diff_report", "mission_state.source_candidate_diff_report"}
      ],
      opts
    )
  end

  def source_candidate_diff_reports_with_result_artifact_fallback(
        mission_state,
        opts \\ default_callbacks()
      ) do
    source_reports_with_result_artifact_fallback(
      mission_state,
      &source_candidate_diff_reports(&1, opts),
      ["source_candidate_diff_report", "candidate_diff_report"],
      opts
    )
  end

  def canonical_candidate_diff_reports(mission_state, opts \\ default_callbacks()) do
    source_reports(
      mission_state,
      [
        {"candidate_diff_report", "mission_state.candidate_diff_report"}
      ],
      opts
    )
  end

  def candidate_rejection_reports(mission_state, opts \\ default_callbacks()) do
    source_reports(
      mission_state,
      [
        {"source_candidate_rejection_report", "mission_state.source_candidate_rejection_report"},
        {"candidate_rejection_report", "mission_state.candidate_rejection_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_candidate_rejection_report", opts) ++
      result_artifact_embedded_reports(mission_state, "candidate_rejection_report", opts)
  end

  def source_candidate_rejection_reports(mission_state, opts \\ default_callbacks()) do
    source_reports(
      mission_state,
      [
        {"source_candidate_rejection_report", "mission_state.source_candidate_rejection_report"}
      ],
      opts
    )
  end

  def source_candidate_rejection_reports_with_result_artifact_fallback(
        mission_state,
        opts \\ default_callbacks()
      ) do
    source_reports_with_result_artifact_fallback(
      mission_state,
      &source_candidate_rejection_reports(&1, opts),
      ["source_candidate_rejection_report", "candidate_rejection_report"],
      opts
    )
  end

  def canonical_candidate_rejection_reports(mission_state, opts \\ default_callbacks()) do
    source_reports(
      mission_state,
      [
        {"candidate_rejection_report", "mission_state.candidate_rejection_report"}
      ],
      opts
    )
  end

  def candidate_diff_pressure_rows(reports) do
    PressureRows.candidate_diff_pressure_rows(reports)
  end

  def candidate_rejection_pressure_rows(reports) do
    PressureRows.candidate_rejection_pressure_rows(reports)
  end

  def candidate_diff_replacement_rows(report) do
    PressureRows.candidate_diff_replacement_rows(report)
  end

  def candidate_refresh_source_inputs(mission_state) do
    Map.new(candidate_refresh_source_input_collectors(), fn {key, collector} ->
      {key, BranchRefreshSourceInputs.source_reports_or_reports(mission_state, collector)}
    end)
  end

  defp candidate_refresh_source_input_collectors,
    do: [
      {"source_candidate_diff_report",
       &source_candidate_diff_reports_with_result_artifact_fallback/1},
      {"candidate_diff_report", &canonical_candidate_diff_reports/1},
      {"source_candidate_rejection_report",
       &source_candidate_rejection_reports_with_result_artifact_fallback/1},
      {"candidate_rejection_report", &canonical_candidate_rejection_reports/1}
    ]

  defp source_reports(mission_state, fields, opts) do
    SourceReportArtifacts.source_reports(mission_state, fields, opts, &stringify_keys/1)
  end

  defp result_artifact_embedded_reports(mission_state, report_key, opts) do
    SourceReportArtifacts.embedded_reports(mission_state, report_key, opts)
  end

  defp source_reports_with_result_artifact_fallback(
         mission_state,
         direct_source_fun,
         result_artifact_keys,
         opts
       ) do
    SourceReportArtifacts.source_reports_with_embedded_fallback(
      mission_state,
      direct_source_fun,
      result_artifact_keys,
      opts,
      &stringify_keys/1
    )
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
