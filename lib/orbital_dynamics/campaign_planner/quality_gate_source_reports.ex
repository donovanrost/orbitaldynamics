defmodule OrbitalDynamics.CampaignPlanner.QualityGateSourceReports do
  @moduledoc false

  alias __MODULE__.SummaryRows

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

  def quality_gate_reports(mission_state, opts) do
    source_reports(mission_state, @quality_gate_report_fields, opts) ++
      result_artifact_embedded_reports(mission_state, "source_quality_gate_report", opts) ++
      result_artifact_embedded_reports(mission_state, "quality_gate_report", opts)
  end

  def prior_plan_quality_gate_reports(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    source_reports(prior_plan, @prior_quality_gate_report_fields, opts) ++
      prior_plan_result_artifact_quality_gate_reports(prior_plan, opts)
  end

  def source_quality_gate_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_quality_gate_report", "mission_state.source_quality_gate_report"}
      ],
      opts
    )
  end

  def canonical_quality_gate_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"quality_gate_report", "mission_state.quality_gate_report"}
      ],
      opts
    )
  end

  def quality_gate_reports(mission_state, "source_quality_gate_report", opts) do
    source_quality_gate_reports(mission_state, opts)
  end

  def quality_gate_reports(mission_state, "quality_gate_report", opts) do
    canonical_quality_gate_reports(mission_state, opts)
  end

  def operational_quality_gate_summary_reports(mission_state, opts) do
    source_reports(mission_state, @operational_quality_gate_summary_fields, opts) ++
      result_artifact_embedded_reports(
        mission_state,
        @operational_quality_gate_summary_report_keys,
        opts
      )
  end

  def prior_plan_quality_gate_summary_reports(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    source_reports(prior_plan, @prior_operational_quality_gate_summary_fields, opts) ++
      prior_plan_result_artifact_quality_gate_summary_reports(prior_plan, opts)
  end

  def pressure_rows(sources) do
    sources
    |> Enum.flat_map(fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> pressure_rows_for_report()
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        row =
          row
          |> Map.put("_source_report_trust_boundary", trust_boundary)

        {row, pressure_row_source(row, source_path), index}
      end)
    end)
  end

  def pressure_rows_for_report(report), do: SummaryRows.pressure_rows_for_report(report)

  def resource_context(row), do: SummaryRows.resource_context(row)

  def schema_validation_context(row), do: SummaryRows.schema_validation_context(row)

  def import_readiness_context(row), do: SummaryRows.import_readiness_context(row)

  defp pressure_row_source(row, source_path) do
    row_source = Map.get(row, "source", "quality_gate_report")

    cond do
      String.starts_with?(row_source, "quality_gate_report") ->
        String.replace_prefix(row_source, "quality_gate_report", source_path)

      String.starts_with?(row_source, "operational_quality_gate_summary") ->
        String.replace_prefix(row_source, "operational_quality_gate_summary", source_path)

      String.starts_with?(row_source, "operational_quality_gate_unavailable_resource_summary") ->
        String.replace_prefix(
          row_source,
          "operational_quality_gate_unavailable_resource_summary",
          source_path
        )

      String.starts_with?(row_source, "operational_quality_gate_operator_training_summary") ->
        String.replace_prefix(
          row_source,
          "operational_quality_gate_operator_training_summary",
          source_path
        )

      String.starts_with?(row_source, "operational_quality_gate_schema_validation_summary") ->
        String.replace_prefix(
          row_source,
          "operational_quality_gate_schema_validation_summary",
          source_path
        )

      String.starts_with?(row_source, "operational_quality_gate_import_readiness_summary") ->
        String.replace_prefix(
          row_source,
          "operational_quality_gate_import_readiness_summary",
          source_path
        )

      true ->
        source_path
    end
  end

  defp source_reports(mission_state, fields, opts) do
    callbacks = callbacks!(opts)
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      callbacks.source_report_entries.(Map.get(mission_state, field), source_path)
    end)
  end

  defp result_artifact_embedded_reports(mission_state, report_keys, opts)
       when is_list(report_keys) do
    Enum.flat_map(report_keys, &result_artifact_embedded_reports(mission_state, &1, opts))
  end

  defp result_artifact_embedded_reports(mission_state, report_key, opts) do
    callbacks = callbacks!(opts)
    callbacks.result_artifact_embedded_reports.(mission_state, report_key)
  end

  defp prior_plan_result_artifact_quality_gate_reports(prior_plan, opts) do
    callbacks = prior_plan_callbacks!(opts)

    prior_plan
    |> callbacks.result_artifacts_with_source.()
    |> Enum.flat_map(fn {artifact, source_path} ->
      result_artifact_quality_gate_reports(artifact, source_path, callbacks)
    end)
  end

  defp result_artifact_quality_gate_reports(artifact, source_path, callbacks) do
    artifact = stringify_keys(artifact)

    if artifact["schema_contract"] == "quality_gate_report.v1" do
      [{callbacks.put_inherited_result_artifact_trust_boundary.(artifact, artifact), source_path}]
    else
      ["source_quality_gate_report", "quality_gate_report"]
      |> Enum.flat_map(fn report_key ->
        result_artifact_embedded_report_entries(
          Map.get(artifact, report_key),
          artifact,
          "#{source_path}.#{report_key}",
          callbacks
        )
      end)
    end
  end

  defp prior_plan_result_artifact_quality_gate_summary_reports(prior_plan, opts) do
    callbacks = prior_plan_callbacks!(opts)

    callbacks.result_artifact_embedded_reports.(
      prior_plan,
      @operational_quality_gate_summary_report_keys
    )
  end

  defp result_artifact_embedded_report_entries(reports, artifact, source_path, callbacks)
       when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      result_artifact_embedded_report_entries(
        report,
        artifact,
        "#{source_path}[#{index}]",
        callbacks
      )
    end)
  end

  defp result_artifact_embedded_report_entries(%{} = report, artifact, source_path, callbacks) do
    report =
      report
      |> stringify_keys()
      |> callbacks.put_inherited_result_artifact_trust_boundary.(artifact)

    [{report, source_path}]
  end

  defp result_artifact_embedded_report_entries(_report, _artifact, _source_path, _callbacks),
    do: []

  defp callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports)
    }
  end

  defp prior_plan_callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      result_artifacts_with_source: Keyword.fetch!(opts, :result_artifacts_with_source),
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports),
      put_inherited_result_artifact_trust_boundary:
        Keyword.fetch!(opts, :put_inherited_result_artifact_trust_boundary)
    }
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
