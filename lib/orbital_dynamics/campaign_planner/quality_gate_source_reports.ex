defmodule OrbitalDynamics.CampaignPlanner.QualityGateSourceReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{BranchRefreshSourceInputs, SourceReportArtifacts}
  alias __MODULE__.{PressureRows, ResultArtifacts, SummaryRows}

  @quality_gate_report_fields [
    {"source_quality_gate_report", "mission_state.source_quality_gate_report"},
    {"quality_gate_report", "mission_state.quality_gate_report"}
  ]

  @prior_quality_gate_report_fields [
    {"source_quality_gate_report", "prior_plan.source_quality_gate_report"},
    {"quality_gate_report", "prior_plan.quality_gate_report"}
  ]

  @operational_quality_gate_summary_fields [
    {"source_operational_quality_gate_summary",
     "mission_state.source_operational_quality_gate_summary"},
    {"operational_quality_gate_summary", "mission_state.operational_quality_gate_summary"},
    {"source_operational_quality_gate_unavailable_resource_summary",
     "mission_state.source_operational_quality_gate_unavailable_resource_summary"},
    {"operational_quality_gate_unavailable_resource_summary",
     "mission_state.operational_quality_gate_unavailable_resource_summary"},
    {"source_operational_quality_gate_operator_training_summary",
     "mission_state.source_operational_quality_gate_operator_training_summary"},
    {"operational_quality_gate_operator_training_summary",
     "mission_state.operational_quality_gate_operator_training_summary"},
    {"source_operational_quality_gate_schema_validation_summary",
     "mission_state.source_operational_quality_gate_schema_validation_summary"},
    {"operational_quality_gate_schema_validation_summary",
     "mission_state.operational_quality_gate_schema_validation_summary"},
    {"source_operational_quality_gate_import_readiness_summary",
     "mission_state.source_operational_quality_gate_import_readiness_summary"},
    {"operational_quality_gate_import_readiness_summary",
     "mission_state.operational_quality_gate_import_readiness_summary"}
  ]

  @prior_operational_quality_gate_summary_fields [
    {"source_operational_quality_gate_summary",
     "prior_plan.source_operational_quality_gate_summary"},
    {"operational_quality_gate_summary", "prior_plan.operational_quality_gate_summary"},
    {"source_operational_quality_gate_unavailable_resource_summary",
     "prior_plan.source_operational_quality_gate_unavailable_resource_summary"},
    {"operational_quality_gate_unavailable_resource_summary",
     "prior_plan.operational_quality_gate_unavailable_resource_summary"},
    {"source_operational_quality_gate_operator_training_summary",
     "prior_plan.source_operational_quality_gate_operator_training_summary"},
    {"operational_quality_gate_operator_training_summary",
     "prior_plan.operational_quality_gate_operator_training_summary"},
    {"source_operational_quality_gate_schema_validation_summary",
     "prior_plan.source_operational_quality_gate_schema_validation_summary"},
    {"operational_quality_gate_schema_validation_summary",
     "prior_plan.operational_quality_gate_schema_validation_summary"},
    {"source_operational_quality_gate_import_readiness_summary",
     "prior_plan.source_operational_quality_gate_import_readiness_summary"},
    {"operational_quality_gate_import_readiness_summary",
     "prior_plan.operational_quality_gate_import_readiness_summary"}
  ]

  @operational_quality_gate_summary_report_keys [
    "source_operational_quality_gate_summary",
    "operational_quality_gate_summary",
    "source_operational_quality_gate_unavailable_resource_summary",
    "operational_quality_gate_unavailable_resource_summary",
    "source_operational_quality_gate_operator_training_summary",
    "operational_quality_gate_operator_training_summary",
    "source_operational_quality_gate_schema_validation_summary",
    "operational_quality_gate_schema_validation_summary",
    "source_operational_quality_gate_import_readiness_summary",
    "operational_quality_gate_import_readiness_summary"
  ]

  def quality_gate_reports(mission_state, opts \\ default_callbacks())

  def quality_gate_reports(mission_state, opts) when is_list(opts) do
    source_reports(mission_state, @quality_gate_report_fields, opts) ++
      result_artifact_embedded_reports(mission_state, "source_quality_gate_report", opts) ++
      result_artifact_embedded_reports(mission_state, "quality_gate_report", opts)
  end

  def quality_gate_reports(mission_state, "source_quality_gate_report") do
    source_quality_gate_reports(mission_state)
  end

  def quality_gate_reports(mission_state, "quality_gate_report") do
    canonical_quality_gate_reports(mission_state)
  end

  def quality_gate_reports(mission_state, "source_quality_gate_report", opts) do
    source_quality_gate_reports(mission_state, opts)
  end

  def quality_gate_reports(mission_state, "quality_gate_report", opts) do
    canonical_quality_gate_reports(mission_state, opts)
  end

  def prior_plan_quality_gate_reports(prior_plan, opts \\ prior_plan_callbacks()) do
    prior_plan = stringify_keys(prior_plan || %{})

    source_reports(prior_plan, @prior_quality_gate_report_fields, opts) ++
      ResultArtifacts.quality_gate_reports(prior_plan, opts)
  end

  def candidate_refresh_source_inputs(mission_state) do
    Map.new(candidate_refresh_source_input_collectors(), fn {key, collector} ->
      {key, BranchRefreshSourceInputs.source_reports_or_reports(mission_state, collector)}
    end)
  end

  def source_quality_gate_reports(mission_state, opts \\ default_callbacks()) do
    source_reports(
      mission_state,
      [
        {"source_quality_gate_report", "mission_state.source_quality_gate_report"}
      ],
      opts
    )
  end

  def canonical_quality_gate_reports(mission_state, opts \\ default_callbacks()) do
    source_reports(
      mission_state,
      [
        {"quality_gate_report", "mission_state.quality_gate_report"}
      ],
      opts
    )
  end

  def operational_quality_gate_summary_reports(mission_state, opts \\ default_callbacks())

  def operational_quality_gate_summary_reports(mission_state, opts) when is_list(opts) do
    source_reports(mission_state, @operational_quality_gate_summary_fields, opts) ++
      result_artifact_embedded_reports(
        mission_state,
        @operational_quality_gate_summary_report_keys,
        opts
      )
  end

  def operational_quality_gate_summary_reports(mission_state, report_key)
      when is_binary(report_key) do
    operational_quality_gate_summary_reports(mission_state, report_key, default_callbacks())
  end

  def operational_quality_gate_summary_reports(mission_state, report_key, opts)
      when is_binary(report_key) and is_list(opts) do
    source_reports(mission_state, [{report_key, "mission_state.#{report_key}"}], opts)
  end

  def prior_plan_quality_gate_summary_reports(prior_plan, opts \\ prior_plan_callbacks()) do
    prior_plan = stringify_keys(prior_plan || %{})

    source_reports(prior_plan, @prior_operational_quality_gate_summary_fields, opts) ++
      ResultArtifacts.operational_quality_gate_summary_reports(prior_plan, opts)
  end

  def pressure_sources(mission_state) do
    quality_gate_reports(mission_state) ++
      operational_quality_gate_summary_reports(mission_state)
  end

  def prior_plan_pressure_sources(prior_plan) do
    prior_plan_quality_gate_reports(prior_plan) ++
      prior_plan_quality_gate_summary_reports(prior_plan)
  end

  def pressure_rows(sources) do
    PressureRows.pressure_rows(sources)
  end

  def pressure_rows_for_report(report), do: SummaryRows.pressure_rows_for_report(report)

  def resource_context(row), do: SummaryRows.resource_context(row)

  def schema_validation_context(row), do: SummaryRows.schema_validation_context(row)

  def import_readiness_context(row), do: SummaryRows.import_readiness_context(row)

  defp candidate_refresh_source_input_collectors do
    [
      {"source_quality_gate_report", &quality_gate_reports(&1, "source_quality_gate_report")},
      {"quality_gate_report", &quality_gate_reports(&1, "quality_gate_report")},
      {"source_operational_quality_gate_summary",
       &operational_quality_gate_summary_reports(
         &1,
         "source_operational_quality_gate_summary"
       )},
      {"operational_quality_gate_summary",
       &operational_quality_gate_summary_reports(&1, "operational_quality_gate_summary")},
      {"source_operational_quality_gate_unavailable_resource_summary",
       &operational_quality_gate_summary_reports(
         &1,
         "source_operational_quality_gate_unavailable_resource_summary"
       )},
      {"operational_quality_gate_unavailable_resource_summary",
       &operational_quality_gate_summary_reports(
         &1,
         "operational_quality_gate_unavailable_resource_summary"
       )},
      {"source_operational_quality_gate_operator_training_summary",
       &operational_quality_gate_summary_reports(
         &1,
         "source_operational_quality_gate_operator_training_summary"
       )},
      {"operational_quality_gate_operator_training_summary",
       &operational_quality_gate_summary_reports(
         &1,
         "operational_quality_gate_operator_training_summary"
       )},
      {"source_operational_quality_gate_schema_validation_summary",
       &operational_quality_gate_summary_reports(
         &1,
         "source_operational_quality_gate_schema_validation_summary"
       )},
      {"operational_quality_gate_schema_validation_summary",
       &operational_quality_gate_summary_reports(
         &1,
         "operational_quality_gate_schema_validation_summary"
       )},
      {"source_operational_quality_gate_import_readiness_summary",
       &operational_quality_gate_summary_reports(
         &1,
         "source_operational_quality_gate_import_readiness_summary"
       )},
      {"operational_quality_gate_import_readiness_summary",
       &operational_quality_gate_summary_reports(
         &1,
         "operational_quality_gate_import_readiness_summary"
       )}
    ]
  end

  defp source_reports(mission_state, fields, opts) do
    SourceReportArtifacts.source_reports(mission_state, fields, opts, &stringify_keys/1)
  end

  defp result_artifact_embedded_reports(mission_state, report_keys, opts) do
    SourceReportArtifacts.embedded_reports(mission_state, report_keys, opts)
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
      report_keys,
      "prior_plan"
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
