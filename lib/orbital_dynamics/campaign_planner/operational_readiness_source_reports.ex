defmodule OrbitalDynamics.CampaignPlanner.OperationalReadinessSourceReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchRefreshSourceInputs,
    OperationalReadinessSourceReports.Context,
    OperationalReadinessSourceReports.PressureRows,
    OperationalReadinessSourceReports.ResultArtifacts,
    SourceReportArtifacts
  }

  @operational_readiness_report_fields [
    {"source_operational_readiness_report", "mission_state.source_operational_readiness_report"},
    {"operational_readiness_report", "mission_state.operational_readiness_report"}
  ]

  @prior_operational_readiness_report_fields [
    {"source_operational_readiness_report", "prior_plan.source_operational_readiness_report"},
    {"operational_readiness_report", "prior_plan.operational_readiness_report"}
  ]

  @operational_readiness_gate_summary_fields [
    {"source_operational_readiness_gate_summary",
     "mission_state.source_operational_readiness_gate_summary"},
    {"operational_readiness_gate_summary", "mission_state.operational_readiness_gate_summary"}
  ]

  @prior_operational_readiness_gate_summary_fields [
    {"source_operational_readiness_gate_summary",
     "prior_plan.source_operational_readiness_gate_summary"},
    {"operational_readiness_gate_summary", "prior_plan.operational_readiness_gate_summary"}
  ]

  def operational_readiness_reports(mission_state, opts \\ default_callbacks())

  def operational_readiness_reports(mission_state, opts) when is_list(opts) do
    source_reports(mission_state, @operational_readiness_report_fields, opts) ++
      result_artifact_embedded_reports(
        mission_state,
        "source_operational_readiness_report",
        opts
      ) ++
      result_artifact_embedded_reports(mission_state, "operational_readiness_report", opts)
  end

  def operational_readiness_reports(
        mission_state,
        "source_operational_readiness_report"
      ) do
    source_operational_readiness_reports(mission_state)
  end

  def operational_readiness_reports(mission_state, "operational_readiness_report") do
    canonical_operational_readiness_reports(mission_state)
  end

  def operational_readiness_reports(
        mission_state,
        "source_operational_readiness_report",
        opts
      ) do
    source_operational_readiness_reports(mission_state, opts)
  end

  def operational_readiness_reports(mission_state, "operational_readiness_report", opts) do
    canonical_operational_readiness_reports(mission_state, opts)
  end

  def prior_plan_operational_readiness_reports(prior_plan, opts \\ prior_plan_callbacks()) do
    prior_plan = stringify_keys(prior_plan || %{})

    source_reports(prior_plan, @prior_operational_readiness_report_fields, opts) ++
      prior_plan_result_artifact_operational_readiness_reports(prior_plan, opts)
  end

  def candidate_refresh_source_inputs(mission_state) do
    Map.new(candidate_refresh_source_input_collectors(), fn {key, collector} ->
      {key, BranchRefreshSourceInputs.source_reports_or_reports(mission_state, collector)}
    end)
  end

  def source_operational_readiness_reports(mission_state, opts \\ default_callbacks()) do
    source_reports(
      mission_state,
      [
        {"source_operational_readiness_report",
         "mission_state.source_operational_readiness_report"}
      ],
      opts
    )
  end

  def canonical_operational_readiness_reports(mission_state, opts \\ default_callbacks()) do
    source_reports(
      mission_state,
      [
        {"operational_readiness_report", "mission_state.operational_readiness_report"}
      ],
      opts
    )
  end

  def operational_summary_reports(mission_state, report_key, opts \\ default_callbacks())
      when is_binary(report_key) do
    source_reports(mission_state, [{report_key, "mission_state.#{report_key}"}], opts)
  end

  def operational_readiness_gate_summaries(mission_state, opts \\ default_callbacks()) do
    source_reports(mission_state, @operational_readiness_gate_summary_fields, opts) ++
      result_artifact_operational_readiness_gate_summaries(mission_state, opts)
  end

  def prior_plan_operational_readiness_gate_summaries(
        prior_plan,
        opts \\ prior_plan_callbacks()
      ) do
    prior_plan = stringify_keys(prior_plan || %{})

    source_reports(prior_plan, @prior_operational_readiness_gate_summary_fields, opts) ++
      prior_plan_result_artifact_operational_readiness_gate_summaries(prior_plan, opts)
  end

  def source_operational_readiness_gate_summaries(mission_state, opts \\ default_callbacks()) do
    source_reports(
      mission_state,
      [
        {"source_operational_readiness_gate_summary",
         "mission_state.source_operational_readiness_gate_summary"}
      ],
      opts
    )
  end

  def canonical_operational_readiness_gate_summaries(
        mission_state,
        opts \\ default_callbacks()
      ) do
    source_reports(
      mission_state,
      [
        {"operational_readiness_gate_summary", "mission_state.operational_readiness_gate_summary"}
      ],
      opts
    )
  end

  def pressure_rows(sources) do
    PressureRows.pressure_rows(sources)
  end

  def pressure_sources(mission_state) do
    operational_readiness_reports(mission_state) ++
      operational_readiness_gate_summaries(mission_state)
  end

  def prior_plan_pressure_sources(prior_plan) do
    prior_plan_operational_readiness_reports(prior_plan) ++
      prior_plan_operational_readiness_gate_summaries(prior_plan)
  end

  def pressure_rows_for_report(report) do
    PressureRows.pressure_rows_for_report(report)
  end

  def operator_training_context(%{} = row) do
    Context.operator_training_context(row)
  end

  def import_readiness_context(%{} = row) do
    Context.import_readiness_context(row)
  end

  def schema_validation_context(%{} = row) do
    Context.schema_validation_context(row)
  end

  def resource_availability_context(%{} = row) do
    Context.resource_availability_context(row)
  end

  defp candidate_refresh_source_input_collectors do
    [
      {"source_operational_readiness_report",
       &operational_readiness_reports(&1, "source_operational_readiness_report")},
      {"operational_readiness_report",
       &operational_readiness_reports(&1, "operational_readiness_report")},
      {"source_operational_import_eligibility_summary",
       &operational_summary_reports(&1, "source_operational_import_eligibility_summary")},
      {"operational_import_eligibility_summary",
       &operational_summary_reports(&1, "operational_import_eligibility_summary")},
      {"source_operational_readiness_gate_summary",
       &source_operational_readiness_gate_summaries/1},
      {"operational_readiness_gate_summary", &canonical_operational_readiness_gate_summaries/1},
      {"source_operational_execution_boundary_summary",
       &operational_summary_reports(&1, "source_operational_execution_boundary_summary")},
      {"operational_execution_boundary_summary",
       &operational_summary_reports(&1, "operational_execution_boundary_summary")}
    ]
  end

  defp source_reports(mission_state, fields, opts) do
    SourceReportArtifacts.source_reports(mission_state, fields, opts, &stringify_keys/1)
  end

  defp result_artifact_embedded_reports(mission_state, report_key, opts) do
    SourceReportArtifacts.embedded_reports(mission_state, report_key, opts)
  end

  defp result_artifact_operational_readiness_gate_summaries(mission_state, opts) do
    callbacks = callbacks!(opts)
    callbacks.result_artifact_operational_readiness_gate_summaries.(mission_state)
  end

  defp default_callbacks do
    [
      source_report_entries: &BranchRefreshSourceInputs.source_report_entries/2,
      result_artifact_embedded_reports: &mission_state_result_artifact_embedded_reports/2,
      result_artifact_operational_readiness_gate_summaries:
        &mission_state_result_artifact_operational_readiness_gate_summaries/1
    ]
  end

  defp mission_state_result_artifact_embedded_reports(mission_state, report_keys) do
    BranchRefreshSourceInputs.result_artifact_embedded_reports(
      mission_state,
      "mission_state",
      report_keys
    )
  end

  defp mission_state_result_artifact_operational_readiness_gate_summaries(mission_state) do
    BranchRefreshSourceInputs.operational_readiness_gate_summaries_from_result_artifacts(
      mission_state,
      "mission_state"
    )
  end

  defp prior_plan_result_artifact_operational_readiness_reports(prior_plan, opts) do
    ResultArtifacts.operational_readiness_reports(prior_plan, opts)
  end

  defp prior_plan_result_artifact_operational_readiness_gate_summaries(prior_plan, opts) do
    ResultArtifacts.operational_readiness_gate_summaries(prior_plan, opts)
  end

  defp callbacks!(opts) do
    %{
      result_artifact_operational_readiness_gate_summaries:
        Keyword.fetch!(opts, :result_artifact_operational_readiness_gate_summaries)
    }
  end

  defp prior_plan_callbacks do
    [
      source_report_entries: &BranchRefreshSourceInputs.source_report_entries/2,
      result_artifacts_with_source: &prior_plan_result_artifacts_with_source/1,
      put_inherited_result_artifact_trust_boundary:
        &BranchRefreshSourceInputs.put_inherited_result_artifact_trust_boundary/2
    ]
  end

  defp prior_plan_result_artifacts_with_source(prior_plan) do
    BranchRefreshSourceInputs.result_artifacts_with_source(prior_plan, "prior_plan")
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
