defmodule OrbitalDynamics.CampaignPlanner.ReviewSourceReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchRefreshSourceInputs,
    SourceReportArtifacts
  }

  alias __MODULE__.SourceMetadata

  def command_window_reports(mission_state, opts \\ default_callbacks()) do
    command_window_reports(
      mission_state,
      [
        {"source_command_window_report", "mission_state.source_command_window_report"},
        {"command_window_report", "mission_state.command_window_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_command_window_report", opts) ++
      result_artifact_embedded_reports(mission_state, "command_window_report", opts)
  end

  def source_command_window_reports(mission_state, opts \\ default_callbacks()) do
    command_window_reports(
      mission_state,
      [
        {"source_command_window_report", "mission_state.source_command_window_report"}
      ],
      opts
    )
  end

  def canonical_command_window_reports(mission_state, opts \\ default_callbacks()) do
    command_window_reports(
      mission_state,
      [
        {"command_window_report", "mission_state.command_window_report"}
      ],
      opts
    )
  end

  def prior_plan_command_window_reports(prior_plan),
    do: prior_plan_command_window_reports(prior_plan, prior_plan_callbacks())

  def prior_plan_command_window_reports(prior_plan, opts) do
    direct_report_entries(
      prior_plan,
      [
        {"source_command_window_report", "prior_plan.source_command_window_report"},
        {"command_window_report", "prior_plan.command_window_report"}
      ]
    ) ++
      result_artifact_embedded_reports(
        prior_plan,
        ["source_command_window_report", "command_window_report"],
        opts
      )
  end

  def candidate_refresh_source_inputs(mission_state) do
    Map.new(candidate_refresh_source_input_collectors(), fn {key, collector} ->
      {key, BranchRefreshSourceInputs.source_reports_or_reports(mission_state, collector)}
    end)
  end

  def maneuver_review_reports(mission_state, opts \\ default_callbacks()) do
    maneuver_review_reports(
      mission_state,
      [
        {"source_maneuver_review_report", "mission_state.source_maneuver_review_report"},
        {"maneuver_review_report", "mission_state.maneuver_review_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_maneuver_review_report", opts) ++
      result_artifact_embedded_reports(mission_state, "maneuver_review_report", opts)
  end

  def source_maneuver_review_reports(mission_state, opts \\ default_callbacks()) do
    maneuver_review_reports(
      mission_state,
      [
        {"source_maneuver_review_report", "mission_state.source_maneuver_review_report"}
      ],
      opts
    )
  end

  def canonical_maneuver_review_reports(mission_state, opts \\ default_callbacks()) do
    maneuver_review_reports(
      mission_state,
      [
        {"maneuver_review_report", "mission_state.maneuver_review_report"}
      ],
      opts
    )
  end

  def prior_plan_maneuver_review_reports(prior_plan),
    do: prior_plan_maneuver_review_reports(prior_plan, prior_plan_callbacks())

  def prior_plan_maneuver_review_reports(prior_plan, opts) do
    prior_plan_maneuver_review_direct_reports(prior_plan) ++
      result_artifact_embedded_reports(
        prior_plan,
        ["source_maneuver_review_report", "maneuver_review_report"],
        opts
      )
  end

  def prior_plan_maneuver_review_direct_reports(prior_plan) do
    direct_report_entries(
      prior_plan,
      [
        {"source_maneuver_review_report", "prior_plan.source_maneuver_review_report"},
        {"maneuver_review_report", "prior_plan.maneuver_review_report"}
      ]
    )
  end

  def prior_plan_timeline_feedback_reports(prior_plan),
    do: prior_plan_timeline_feedback_reports(prior_plan, prior_plan_callbacks())

  def prior_plan_timeline_feedback_reports(prior_plan, opts) do
    direct_report_entries(
      prior_plan,
      [
        {"source_timeline_feedback_report", "prior_plan.source_timeline_feedback_report"},
        {"timeline_feedback_report", "prior_plan.timeline_feedback_report"}
      ]
    ) ++
      result_artifact_embedded_reports(
        prior_plan,
        ["source_timeline_feedback_report", "timeline_feedback_report"],
        opts
      )
  end

  def prior_plan_operational_timeline_reports(prior_plan),
    do: prior_plan_operational_timeline_reports(prior_plan, prior_plan_callbacks())

  def prior_plan_operational_timeline_reports(prior_plan, opts) do
    direct_report_entries(
      prior_plan,
      [
        {"source_operational_timeline_report", "prior_plan.source_operational_timeline_report"},
        {"operational_timeline_report", "prior_plan.operational_timeline_report"}
      ]
    ) ++
      result_artifact_embedded_reports(
        prior_plan,
        ["source_operational_timeline_report", "operational_timeline_report"],
        opts
      )
  end

  def operational_timeline_reports(mission_state, opts \\ default_callbacks()) do
    source_report_entries(
      mission_state,
      [
        {"source_operational_timeline_report",
         "mission_state.source_operational_timeline_report"},
        {"operational_timeline_report", "mission_state.operational_timeline_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(
        mission_state,
        "source_operational_timeline_report",
        opts
      ) ++
      result_artifact_embedded_reports(mission_state, "operational_timeline_report", opts)
  end

  def timeline_feedback_reports(mission_state, opts \\ default_callbacks()) do
    source_report_entries(
      mission_state,
      [
        {"source_timeline_feedback_report", "mission_state.source_timeline_feedback_report"},
        {"timeline_feedback_report", "mission_state.timeline_feedback_report"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(mission_state, "source_timeline_feedback_report", opts) ++
      result_artifact_embedded_reports(mission_state, "timeline_feedback_report", opts)
  end

  def command_window_source_metadata(reports_with_sources, feedback_rows, opts) do
    SourceMetadata.command_window_source_metadata(reports_with_sources, feedback_rows, opts)
  end

  def maneuver_review_source_metadata(
        reports_with_sources,
        feedback_rows,
        source_rows,
        extra_metadata,
        opts
      ) do
    SourceMetadata.maneuver_review_source_metadata(
      reports_with_sources,
      feedback_rows,
      source_rows,
      extra_metadata,
      opts
    )
  end

  def operational_timeline_source_metadata(reports_with_sources, feedback_rows, opts) do
    SourceMetadata.operational_timeline_source_metadata(reports_with_sources, feedback_rows, opts)
  end

  def timeline_feedback_source_metadata(reports_with_sources, opts) do
    SourceMetadata.timeline_feedback_source_metadata(reports_with_sources, opts)
  end

  def timeline_feedback_report_row_count(report) do
    SourceMetadata.timeline_feedback_report_row_count(report)
  end

  defp command_window_reports(mission_state, fields, opts) do
    source_report_entries(mission_state, fields, opts)
  end

  defp maneuver_review_reports(mission_state, fields, opts) do
    source_report_entries(mission_state, fields, opts)
  end

  defp candidate_refresh_source_input_collectors do
    [
      {"source_command_window_report", &source_command_window_reports/1},
      {"command_window_report", &canonical_command_window_reports/1},
      {"source_maneuver_review_report", &source_maneuver_review_reports/1},
      {"maneuver_review_report", &canonical_maneuver_review_reports/1}
    ]
  end

  defp direct_report_entries(source, fields) do
    SourceReportArtifacts.direct_reports(source, fields, &stringify_keys/1)
  end

  defp source_report_entries(mission_state, fields, opts) do
    SourceReportArtifacts.source_reports(mission_state, fields, opts, &stringify_keys/1)
  end

  defp result_artifact_embedded_reports(mission_state, report_key, opts) do
    SourceReportArtifacts.embedded_reports(mission_state, report_key, opts)
  end

  defp prior_plan_callbacks do
    [
      result_artifact_embedded_reports: &prior_plan_result_artifact_embedded_reports/2
    ]
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
