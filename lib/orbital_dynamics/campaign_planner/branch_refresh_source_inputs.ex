defmodule OrbitalDynamics.CampaignPlanner.BranchRefreshSourceInputs do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ReviewSourceReports,
    StrategyCandidateSource,
    ValueEncoding
  }

  def timeline_feedback_source_report(mission_state) do
    mission_state
    |> direct_source_timeline_feedback_reports()
    |> report_from_reports()
    |> non_empty_report()
  end

  def timeline_feedback_report_input(mission_state) do
    mission_state
    |> direct_canonical_timeline_feedback_reports()
    |> report_from_reports()
    |> non_empty_report()
  end

  def operational_timeline_source_report(mission_state) do
    mission_state
    |> direct_source_operational_timeline_reports()
    |> report_from_reports()
    |> non_empty_report()
  end

  def operational_timeline_report_input(mission_state) do
    mission_state
    |> direct_canonical_operational_timeline_reports()
    |> report_from_reports()
    |> non_empty_report()
  end

  def merge_reports(reports_with_sources) do
    reports = Enum.map(reports_with_sources, fn {report, _source_path} -> report end)

    reports
    |> List.first(%{})
    |> Map.put("rows", Enum.flat_map(reports, &(Map.get(&1, "rows", []) || [])))
    |> Map.put(
      "row_count",
      Enum.sum(Enum.map(reports, &ReviewSourceReports.timeline_feedback_report_row_count/1))
    )
  end

  def source_report_entries(nil, _source_path), do: []

  def source_report_entries(reports, source_path) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_entries(report, "#{source_path}[#{index}]")
    end)
  end

  def source_report_entries(%{} = report, source_path),
    do: [{stringify_keys(report), source_path}]

  def source_report_entries(_report, _source_path), do: []

  def source_artifact_entries(artifacts, source_path) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{} = artifact, index} -> [{stringify_keys(artifact), "#{source_path}[#{index}]"}]
      {_artifact, _index} -> []
    end)
  end

  def source_artifact_entries(%{} = artifact, source_path),
    do: [{stringify_keys(artifact), source_path}]

  def source_artifact_entries(_artifact, _source_path), do: []

  def result_artifacts_with_source(container, source_prefix) do
    [
      {Map.get(container, "source_result_artifact"), "#{source_prefix}.source_result_artifact"},
      {Map.get(container, "result_artifact"), "#{source_prefix}.result_artifact"},
      {if(Map.get(container, "schema_contract") == "result_artifact.v1", do: container),
       source_prefix}
    ]
    |> Enum.flat_map(&result_artifact_entries/1)
  end

  def result_artifact_entries({artifacts, source_path}) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{} = artifact, index} -> [{stringify_keys(artifact), "#{source_path}[#{index}]"}]
      {_artifact, _index} -> []
    end)
  end

  def result_artifact_entries({%{} = artifact, source_path}),
    do: [{stringify_keys(artifact), source_path}]

  def result_artifact_entries({_artifact, _source_path}), do: []

  def result_artifact_embedded_reports(container, source_prefix, report_keys) do
    container
    |> result_artifacts_with_source(source_prefix)
    |> Enum.flat_map(fn {artifact, source_path} ->
      report_keys
      |> List.wrap()
      |> Enum.flat_map(fn report_key ->
        result_artifact_embedded_report_entries(
          Map.get(artifact, report_key),
          artifact,
          "#{source_path}.#{report_key}"
        )
      end)
    end)
  end

  def operational_readiness_gate_summaries_from_result_artifacts(container, source_prefix) do
    container
    |> result_artifacts_with_source(source_prefix)
    |> Enum.flat_map(fn {artifact, source_path} ->
      result_artifact_operational_readiness_gate_summaries(artifact, source_path)
    end)
  end

  def result_artifact_operational_readiness_gate_summaries(artifact, source_path) do
    artifact = stringify_keys(artifact)

    if artifact["schema_contract"] == "operational_readiness_gate_summary.v1" do
      [{put_inherited_result_artifact_trust_boundary(artifact, artifact), source_path}]
    else
      ["source_operational_readiness_gate_summary", "operational_readiness_gate_summary"]
      |> Enum.flat_map(fn summary_key ->
        result_artifact_embedded_report_entries(
          Map.get(artifact, summary_key),
          artifact,
          "#{source_path}.#{summary_key}"
        )
      end)
    end
  end

  def result_artifact_embedded_report_entries(reports, artifact, source_path)
      when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      result_artifact_embedded_report_entries(report, artifact, "#{source_path}[#{index}]")
    end)
  end

  def result_artifact_embedded_report_entries(%{} = report, artifact, source_path) do
    report =
      report
      |> stringify_keys()
      |> put_inherited_result_artifact_trust_boundary(artifact)

    [{report, source_path}]
  end

  def result_artifact_embedded_report_entries(_report, _artifact, _source_path), do: []

  def put_inherited_result_artifact_trust_boundary(report, artifact) do
    trust_boundary =
      Map.get(report, "trust_boundary") ||
        get_in(report, ["provenance", "trust_boundary"]) ||
        Map.get(artifact, "trust_boundary") ||
        get_in(artifact, ["provenance", "trust_boundary"]) ||
        get_in(artifact, ["metadata", "trust_boundary"])

    if trust_boundary in [nil, ""] do
      report
    else
      Map.put_new(report, "trust_boundary", trust_boundary)
    end
  end

  def source_reports_or_reports(mission_state, report_fun) do
    mission_state
    |> report_fun.()
    |> report_or_reports()
  end

  def source_report_key_entries(mission_state, key) do
    mission_state = stringify_keys(mission_state || %{})

    mission_state
    |> Map.get(key)
    |> source_report_entries("mission_state.#{key}")
  end

  def source_reports_with_result_artifact_reports(
        mission_state,
        direct_source_fun,
        report_keys
      ) do
    source_reports_with_result_artifact_reports(
      mission_state,
      direct_source_fun,
      report_keys,
      result_artifact_callbacks()
    )
  end

  def source_reports_with_result_artifact_reports(
        mission_state,
        direct_source_fun,
        report_keys,
        opts
      ) do
    callbacks = result_artifact_callbacks!(opts)

    case direct_source_fun.(mission_state) do
      [] ->
        Enum.flat_map(
          report_keys,
          &callbacks.result_artifact_embedded_reports.(mission_state, &1)
        )

      reports ->
        reports
    end
  end

  def put_missing_candidate_refresh_result_artifact_source_aliases(
        source_reports,
        mission_state
      ) do
    put_missing_candidate_refresh_result_artifact_source_aliases(
      source_reports,
      mission_state,
      result_artifact_callbacks()
    )
  end

  def put_missing_candidate_refresh_result_artifact_source_aliases(
        source_reports,
        mission_state,
        opts
      ) do
    callbacks = result_artifact_callbacks!(opts)

    StrategyCandidateSource.source_report_input_fields()
    |> Enum.reject(fn {source_key, _canonical_key} ->
      source_key in [
        "source_timeline_feedback_report",
        "source_operational_timeline_report"
      ]
    end)
    |> Enum.reduce(source_reports, fn {source_key, canonical_key}, acc ->
      if StrategyCandidateSource.source_report_input_present?(Map.get(acc, source_key)) do
        acc
      else
        reports =
          [source_key, canonical_key]
          |> Enum.flat_map(&callbacks.result_artifact_embedded_reports.(mission_state, &1))

        case report_or_reports(reports) do
          nil -> acc
          value -> Map.put(acc, source_key, value)
        end
      end
    end)
  end

  def resource_projection_flow_summaries(mission_state, fields) do
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      mission_state
      |> Map.get(field)
      |> source_report_entries(source_path)
    end)
  end

  def resource_projection_flow_summary_result_artifacts(mission_state, artifact_key) do
    mission_state = stringify_keys(mission_state || %{})

    mission_state
    |> Map.get(artifact_key)
    |> then(&result_artifact_entries({&1, "mission_state.#{artifact_key}"}))
    |> Enum.flat_map(fn {artifact, _source_path} ->
      artifact = stringify_keys(artifact)

      flow_summary_artifact =
        artifact
        |> Map.take(candidate_refresh_result_artifact_wrapper_payload_keys())
        |> ValueEncoding.compact_map()

      if candidate_refresh_source_report_payload?(flow_summary_artifact) do
        [
          flow_summary_artifact
          |> Map.put_new("schema_contract", "result_artifact.v1")
          |> Map.put_new("artifact_type", "mission_state_result_artifact")
        ]
      else
        []
      end
    end)
    |> case do
      [] -> nil
      [artifact] -> artifact
      artifacts -> artifacts
    end
  end

  def report_or_reports(reports_with_sources) do
    reports =
      reports_with_sources
      |> List.wrap()
      |> Enum.map(fn {report, _source_path} -> stringify_keys(report) end)

    case reports do
      [] -> nil
      [report] -> report
      reports -> reports
    end
  end

  def non_empty_report(%{} = report) when map_size(report) > 0, do: report
  def non_empty_report(_report), do: nil

  defp direct_source_timeline_feedback_reports(mission_state) do
    direct_timeline_feedback_reports(
      mission_state,
      [{"source_timeline_feedback_report", "mission_state.source_timeline_feedback_report"}]
    )
  end

  defp direct_canonical_timeline_feedback_reports(mission_state) do
    direct_timeline_feedback_reports(
      mission_state,
      [{"timeline_feedback_report", "mission_state.timeline_feedback_report"}]
    )
  end

  defp direct_timeline_feedback_reports(mission_state, fields) do
    direct_reports(mission_state, fields)
  end

  defp direct_source_operational_timeline_reports(mission_state) do
    direct_operational_timeline_reports(
      mission_state,
      [
        {"source_operational_timeline_report", "mission_state.source_operational_timeline_report"}
      ]
    )
  end

  defp direct_canonical_operational_timeline_reports(mission_state) do
    direct_operational_timeline_reports(
      mission_state,
      [{"operational_timeline_report", "mission_state.operational_timeline_report"}]
    )
  end

  defp direct_operational_timeline_reports(mission_state, fields) do
    direct_reports(mission_state, fields)
  end

  defp direct_reports(mission_state, fields) do
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      source_report_entries(Map.get(mission_state, field), source_path)
    end)
  end

  defp report_from_reports([{report, _source_path}]), do: report

  defp report_from_reports(reports) when is_list(reports) and reports != [],
    do: merge_reports(reports)

  defp report_from_reports(_reports), do: %{}

  defp result_artifact_callbacks!(opts) do
    %{
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports)
    }
  end

  defp result_artifact_callbacks,
    do: [
      result_artifact_embedded_reports: &mission_state_result_artifact_embedded_reports/2
    ]

  defp mission_state_result_artifact_embedded_reports(mission_state, report_keys) do
    result_artifact_embedded_reports(mission_state, "mission_state", report_keys)
  end

  defp candidate_refresh_source_report_payload?(artifact) do
    Enum.any?(candidate_refresh_source_report_payload_keys(), &Map.has_key?(artifact, &1))
  end

  defp candidate_refresh_result_artifact_wrapper_payload_keys do
    ["schema_contract", "artifact_type", "metadata", "provenance", "trust_boundary"]
    |> Enum.concat(candidate_refresh_source_report_payload_keys())
    |> Enum.uniq()
  end

  defp candidate_refresh_source_report_payload_keys do
    StrategyCandidateSource.source_report_input_fields()
    |> Enum.flat_map(fn {source_key, canonical_key} -> [source_key, canonical_key] end)
    |> Enum.uniq()
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
