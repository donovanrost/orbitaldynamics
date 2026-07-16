defmodule OrbitalDynamics.CampaignPlanner.ContactIntentSourceReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchRefreshSourceInputs,
    SourceReportArtifacts
  }

  alias __MODULE__.Rows

  @contact_intent_source_keys [
    "source_contact_intent",
    "contact_intent",
    "source_contact_intents",
    "contact_intents"
  ]

  @contact_intent_summary_report_keys [
    "source_contact_intent_summary",
    "contact_intent_summary"
  ]

  def prior_plan_rows_with_source(prior_plan),
    do: prior_plan_rows_with_source(prior_plan, prior_plan_callbacks())

  def prior_plan_rows_with_source(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    direct_rows =
      Rows.rows_with_source(
        prior_plan,
        "prior_plan",
        @contact_intent_source_keys,
        &stringify_keys/1
      )

    direct_rows ++ result_artifact_rows_with_source(prior_plan, opts)
  end

  def mission_state_rows_with_source(mission_state),
    do: mission_state_rows_with_source(mission_state, default_callbacks())

  def mission_state_rows_with_source(mission_state, opts) do
    direct_rows =
      Rows.rows_with_source(
        mission_state,
        "mission_state",
        @contact_intent_source_keys,
        &stringify_keys/1
      )

    direct_rows ++ result_artifact_rows_with_source(mission_state, opts)
  end

  def mission_state_source_contact_intent_rows_with_source(mission_state) do
    Rows.rows_with_source(
      mission_state,
      "mission_state",
      ["source_contact_intent"],
      &stringify_keys/1
    )
  end

  def mission_state_source_contact_intents_rows_with_source(mission_state) do
    Rows.rows_with_source(
      mission_state,
      "mission_state",
      ["source_contact_intents"],
      &stringify_keys/1
    )
  end

  def mission_state_canonical_contact_intent_rows_with_source(mission_state) do
    Rows.rows_with_source(mission_state, "mission_state", ["contact_intent"], &stringify_keys/1)
  end

  def mission_state_canonical_contact_intents_rows_with_source(mission_state) do
    Rows.rows_with_source(mission_state, "mission_state", ["contact_intents"], &stringify_keys/1)
  end

  def mission_state_source_contact_intent_summaries(mission_state),
    do: mission_state_source_contact_intent_summaries(mission_state, default_callbacks())

  def mission_state_source_contact_intent_summaries(mission_state, opts) do
    source_report_entries(
      mission_state,
      [{"source_contact_intent_summary", "mission_state.source_contact_intent_summary"}],
      opts
    )
  end

  def mission_state_canonical_contact_intent_summaries(mission_state),
    do: mission_state_canonical_contact_intent_summaries(mission_state, default_callbacks())

  def mission_state_canonical_contact_intent_summaries(mission_state, opts) do
    source_report_entries(
      mission_state,
      [{"contact_intent_summary", "mission_state.contact_intent_summary"}],
      opts
    )
  end

  def candidate_refresh_source_inputs(mission_state) do
    Map.new(candidate_refresh_source_input_collectors(), fn {key, collector} ->
      {key, BranchRefreshSourceInputs.source_reports_or_reports(mission_state, collector)}
    end)
  end

  def prior_plan_summaries_with_source(prior_plan),
    do: prior_plan_summaries_with_source(prior_plan, prior_plan_callbacks())

  def prior_plan_summaries_with_source(prior_plan, opts) do
    source_report_entries(
      prior_plan,
      [
        {"source_contact_intent_summary", "prior_plan.source_contact_intent_summary"},
        {"contact_intent_summary", "prior_plan.contact_intent_summary"}
      ],
      opts
    ) ++
      result_artifact_embedded_reports(
        prior_plan,
        @contact_intent_summary_report_keys,
        opts
      )
  end

  def mission_state_summaries_with_source(mission_state),
    do: mission_state_summaries_with_source(mission_state, default_callbacks())

  def mission_state_summaries_with_source(mission_state, opts) do
    mission_state_source_contact_intent_summaries(mission_state, opts) ++
      mission_state_canonical_contact_intent_summaries(mission_state, opts) ++
      result_artifact_embedded_reports(
        mission_state,
        "source_contact_intent_summary",
        opts
      ) ++
      result_artifact_embedded_reports(mission_state, "contact_intent_summary", opts)
  end

  defp result_artifact_rows_with_source(container, opts) do
    SourceReportArtifacts.inherited_result_artifact_entries(
      container,
      opts,
      &stringify_keys/1,
      fn artifact, source_path ->
        Rows.rows_with_source(
          artifact,
          source_path,
          @contact_intent_source_keys,
          &stringify_keys/1
        )
      end
    )
  end

  defp candidate_refresh_source_input_collectors do
    [
      {"source_contact_intent", &mission_state_source_contact_intent_rows_with_source/1},
      {"source_contact_intents", &mission_state_source_contact_intents_rows_with_source/1},
      {"contact_intent", &mission_state_canonical_contact_intent_rows_with_source/1},
      {"contact_intents", &mission_state_canonical_contact_intents_rows_with_source/1},
      {"source_contact_intent_summary", &mission_state_source_contact_intent_summaries/1},
      {"contact_intent_summary", &mission_state_canonical_contact_intent_summaries/1}
    ]
  end

  defp source_report_entries(container, fields, opts) do
    SourceReportArtifacts.source_reports(container, fields, opts, &stringify_keys/1)
  end

  defp result_artifact_embedded_reports(container, report_keys, opts) do
    SourceReportArtifacts.embedded_reports(container, report_keys, opts)
  end

  defp default_callbacks do
    [
      source_report_entries: &BranchRefreshSourceInputs.source_report_entries/2,
      result_artifacts_with_source: &mission_state_result_artifacts_with_source/1,
      result_artifact_embedded_reports: &mission_state_result_artifact_embedded_reports/2,
      put_inherited_result_artifact_trust_boundary:
        &BranchRefreshSourceInputs.put_inherited_result_artifact_trust_boundary/2
    ]
  end

  defp mission_state_result_artifacts_with_source(mission_state) do
    BranchRefreshSourceInputs.result_artifacts_with_source(mission_state, "mission_state")
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
      source_report_entries: &BranchRefreshSourceInputs.source_report_entries/2,
      result_artifacts_with_source: &prior_plan_result_artifacts_with_source/1,
      result_artifact_embedded_reports: &prior_plan_result_artifact_embedded_reports/2,
      put_inherited_result_artifact_trust_boundary:
        &BranchRefreshSourceInputs.put_inherited_result_artifact_trust_boundary/2
    ]
  end

  defp prior_plan_result_artifacts_with_source(prior_plan) do
    BranchRefreshSourceInputs.result_artifacts_with_source(prior_plan, "prior_plan")
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
