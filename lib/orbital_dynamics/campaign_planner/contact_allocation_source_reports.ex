defmodule OrbitalDynamics.CampaignPlanner.ContactAllocationSourceReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{BranchRefreshSourceInputs, SourceReportArtifacts}

  @report_fields [
    {"source_contact_allocation_report", "mission_state.source_contact_allocation_report"},
    {"contact_allocation_report", "mission_state.contact_allocation_report"}
  ]

  @prior_report_fields [
    {"source_contact_allocation_report", "prior_plan.source_contact_allocation_report"},
    {"contact_allocation_report", "prior_plan.contact_allocation_report"}
  ]

  @summary_pairs %{
    "source_contact_allocation_summary" => "contact_allocation_summary",
    "source_contact_allocation_station_pressure_summary" =>
      "contact_allocation_station_pressure_summary",
    "source_contact_allocation_reservation_conflict_summary" =>
      "contact_allocation_reservation_conflict_summary",
    "source_contact_allocation_capacity_pack_summary" =>
      "contact_allocation_capacity_pack_summary",
    "source_contact_allocation_provider_reservation_request_summary" =>
      "contact_allocation_provider_reservation_request_summary"
  }

  @pressure_summary_fields [
    "source_contact_allocation_summary",
    "contact_allocation_summary",
    "source_contact_allocation_station_pressure_summary",
    "contact_allocation_station_pressure_summary",
    "source_contact_allocation_reservation_conflict_summary",
    "contact_allocation_reservation_conflict_summary",
    "source_contact_allocation_capacity_pack_summary",
    "contact_allocation_capacity_pack_summary",
    "source_contact_allocation_provider_reservation_request_summary",
    "contact_allocation_provider_reservation_request_summary"
  ]

  def reports(mission_state), do: reports(mission_state, default_callbacks())

  def reports(mission_state, report_key) when is_binary(report_key) do
    reports(mission_state, report_key, default_callbacks())
  end

  def reports(mission_state, opts) do
    mission_state = stringify_keys(mission_state || %{})

    source_reports(mission_state, @report_fields, opts) ++
      result_artifact_embedded_reports(mission_state, "source_contact_allocation_report", opts) ++
      result_artifact_embedded_reports(mission_state, "contact_allocation_report", opts)
  end

  def reports(mission_state, "source_contact_allocation_report", opts) do
    source_reports(
      mission_state,
      [
        {"source_contact_allocation_report", "mission_state.source_contact_allocation_report"}
      ],
      opts
    )
  end

  def reports(mission_state, "contact_allocation_report", opts) do
    source_reports(
      mission_state,
      [
        {"contact_allocation_report", "mission_state.contact_allocation_report"}
      ],
      opts
    )
  end

  def prior_plan_reports(prior_plan, opts \\ prior_plan_callbacks()) do
    prior_plan = stringify_keys(prior_plan || %{})

    SourceReportArtifacts.direct_reports(prior_plan, @prior_report_fields, &stringify_keys/1) ++
      prior_plan_result_artifact_reports(prior_plan, opts)
  end

  def candidate_refresh_source_inputs(mission_state) do
    report_inputs =
      @report_fields
      |> Enum.map(&elem(&1, 0))
      |> Map.new(fn report_key ->
        {report_key, candidate_refresh_report_input(mission_state, report_key)}
      end)

    summary_inputs =
      Map.new(@pressure_summary_fields, fn summary_key ->
        {summary_key, candidate_refresh_summary_input(mission_state, summary_key)}
      end)

    Map.merge(report_inputs, summary_inputs)
  end

  def summaries(mission_state, summary_key) do
    summaries(mission_state, summary_key, default_callbacks())
  end

  def summaries(mission_state, source_key, opts) when is_map_key(@summary_pairs, source_key) do
    source_reports_with_result_artifact_reports(
      mission_state,
      {source_key, "mission_state.#{source_key}"},
      [source_key, Map.fetch!(@summary_pairs, source_key)],
      opts
    )
  end

  def summaries(mission_state, canonical_key, opts) do
    source_reports(
      mission_state,
      [
        {canonical_key, "mission_state.#{canonical_key}"}
      ],
      opts
    )
  end

  def pressure_summaries(mission_state),
    do: pressure_summaries(mission_state, default_callbacks())

  def pressure_summaries(mission_state, opts) do
    Enum.flat_map(@pressure_summary_fields, &summaries(mission_state, &1, opts))
  end

  def prior_plan_pressure_summaries(prior_plan, opts \\ prior_plan_callbacks()) do
    prior_plan = stringify_keys(prior_plan || %{})

    direct_summaries =
      @pressure_summary_fields
      |> Enum.map(&{&1, "prior_plan.#{&1}"})
      |> then(fn fields ->
        SourceReportArtifacts.direct_reports(prior_plan, fields, &stringify_keys/1)
      end)

    direct_summaries ++
      prior_plan_result_artifact_pressure_summaries(prior_plan, opts)
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

  defp source_reports_with_result_artifact_reports(
         mission_state,
         {field, source_path},
         result_artifact_keys,
         opts
       ) do
    SourceReportArtifacts.source_reports_with_embedded_reports(
      mission_state,
      {field, source_path},
      result_artifact_keys,
      opts,
      &stringify_keys/1
    )
  end

  defp result_artifact_embedded_reports(mission_state, report_key, opts) do
    SourceReportArtifacts.embedded_reports(mission_state, report_key, opts)
  end

  defp prior_plan_result_artifact_reports(prior_plan, opts) do
    report_keys = Enum.map(@report_fields, &elem(&1, 0))
    SourceReportArtifacts.embedded_reports(prior_plan, report_keys, opts)
  end

  defp prior_plan_result_artifact_pressure_summaries(prior_plan, opts) do
    SourceReportArtifacts.embedded_reports(prior_plan, @pressure_summary_fields, opts)
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
