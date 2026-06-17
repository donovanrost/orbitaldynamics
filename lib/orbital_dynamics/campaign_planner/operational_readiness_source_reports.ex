defmodule OrbitalDynamics.CampaignPlanner.OperationalReadinessSourceReports do
  @moduledoc false

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

  def operational_readiness_reports(mission_state, opts) do
    source_reports(mission_state, @operational_readiness_report_fields, opts) ++
      result_artifact_embedded_reports(
        mission_state,
        "source_operational_readiness_report",
        opts
      ) ++
      result_artifact_embedded_reports(mission_state, "operational_readiness_report", opts)
  end

  def prior_plan_operational_readiness_reports(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    source_reports(prior_plan, @prior_operational_readiness_report_fields, opts) ++
      prior_plan_result_artifact_operational_readiness_reports(prior_plan, opts)
  end

  def source_operational_readiness_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_operational_readiness_report",
         "mission_state.source_operational_readiness_report"}
      ],
      opts
    )
  end

  def canonical_operational_readiness_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"operational_readiness_report", "mission_state.operational_readiness_report"}
      ],
      opts
    )
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

  def operational_readiness_gate_summaries(mission_state, opts) do
    source_reports(mission_state, @operational_readiness_gate_summary_fields, opts) ++
      result_artifact_operational_readiness_gate_summaries(mission_state, opts)
  end

  def prior_plan_operational_readiness_gate_summaries(prior_plan, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    source_reports(prior_plan, @prior_operational_readiness_gate_summary_fields, opts) ++
      prior_plan_result_artifact_operational_readiness_gate_summaries(prior_plan, opts)
  end

  def source_operational_readiness_gate_summaries(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_operational_readiness_gate_summary",
         "mission_state.source_operational_readiness_gate_summary"}
      ],
      opts
    )
  end

  def canonical_operational_readiness_gate_summaries(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"operational_readiness_gate_summary", "mission_state.operational_readiness_gate_summary"}
      ],
      opts
    )
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

  def pressure_rows_for_report(report) do
    report = stringify_keys(report || %{})

    if report["schema_contract"] == "operational_readiness_gate_summary.v1" do
      operational_readiness_gate_summary_pressure_rows(report)
    else
      operational_readiness_report_pressure_rows(report)
    end
  end

  def operator_training_context(%{} = row) do
    evidence = Map.get(row, "evidence") || %{}

    %{
      "operator_training_requirement_count" =>
        row["operator_training_requirement_count"] ||
          evidence["operator_training_requirement_count"],
      "operator_training_requirement_counts" =>
        row["operator_training_requirement_counts"] ||
          evidence["operator_training_requirement_counts"],
      "required_operator_roles" =>
        row["required_operator_roles"] || evidence["required_operator_roles"],
      "required_training_ids" =>
        row["required_training_ids"] || evidence["required_training_ids"],
      "required_certification_ids" =>
        row["required_certification_ids"] || evidence["required_certification_ids"],
      "required_qualification_ids" =>
        row["required_qualification_ids"] || evidence["required_qualification_ids"]
    }
  end

  def import_readiness_context(%{} = row) do
    evidence = Map.get(row, "evidence") || %{}

    %{
      "import_readiness_row_count" =>
        row_or_evidence(row, evidence, "import_readiness_row_count"),
      "ready_for_import_count" => row_or_evidence(row, evidence, "ready_for_import_count"),
      "manifest_review_required_count" =>
        row_or_evidence(row, evidence, "manifest_review_required_count"),
      "blocked_import_count" => row_or_evidence(row, evidence, "blocked_import_count"),
      "missing_import_count" => row_or_evidence(row, evidence, "missing_import_count"),
      "invalid_cadence_import_count" =>
        row_or_evidence(row, evidence, "invalid_cadence_import_count"),
      "current_freshness_count" => row_or_evidence(row, evidence, "current_freshness_count"),
      "stale_freshness_count" => row_or_evidence(row, evidence, "stale_freshness_count"),
      "unknown_freshness_count" => row_or_evidence(row, evidence, "unknown_freshness_count"),
      "freshness_status_counts" => row_or_evidence(row, evidence, "freshness_status_counts"),
      "freshness_status_ids" => row_or_evidence(row, evidence, "freshness_status_ids"),
      "import_status_counts" => row_or_evidence(row, evidence, "import_status_counts"),
      "import_status_ids" => row_or_evidence(row, evidence, "import_status_ids"),
      "cadence_import_status_counts" =>
        row_or_evidence(row, evidence, "cadence_import_status_counts"),
      "cadence_import_status_ids" => row_or_evidence(row, evidence, "cadence_import_status_ids"),
      "freshness_review_required" => row_or_evidence(row, evidence, "freshness_review_required"),
      "import_preparation_required" =>
        row_or_evidence(row, evidence, "import_preparation_required"),
      "import_blocked" => row_or_evidence(row, evidence, "import_blocked"),
      "stale_or_unknown_freshness_quality_gate_row_ids" =>
        row_or_evidence(row, evidence, "stale_or_unknown_freshness_quality_gate_row_ids"),
      "import_preparation_quality_gate_row_ids" =>
        row_or_evidence(row, evidence, "import_preparation_quality_gate_row_ids"),
      "blocked_import_quality_gate_row_ids" =>
        row_or_evidence(row, evidence, "blocked_import_quality_gate_row_ids")
    }
  end

  def schema_validation_context(%{} = row) do
    evidence = Map.get(row, "evidence") || %{}

    %{
      "schema_validation_row_count" =>
        row_or_evidence(row, evidence, "schema_validation_row_count"),
      "schema_validation_pass_count" =>
        row_or_evidence(row, evidence, "schema_validation_pass_count"),
      "schema_validation_fail_count" =>
        row_or_evidence(row, evidence, "schema_validation_fail_count"),
      "schema_validation_error_count" =>
        row_or_evidence(row, evidence, "schema_validation_error_count"),
      "schema_validation_warning_count" =>
        row_or_evidence(row, evidence, "schema_validation_warning_count"),
      "schema_validation_remediation_count" =>
        row_or_evidence(row, evidence, "schema_validation_remediation_count"),
      "schema_validation_status_counts" =>
        row_or_evidence(row, evidence, "schema_validation_status_counts"),
      "schema_validation_status_ids" =>
        row_or_evidence(row, evidence, "schema_validation_status_ids"),
      "schema_validation_import_blocked" =>
        row_or_evidence(row, evidence, "schema_validation_import_blocked"),
      "failed_schema_validation_quality_gate_row_ids" =>
        row_or_evidence(row, evidence, "failed_schema_validation_quality_gate_row_ids")
    }
  end

  def resource_availability_context(%{} = row) do
    evidence = Map.get(row, "evidence") || %{}

    %{
      "resource_availability_pressure_count" =>
        row["resource_availability_pressure_count"] ||
          evidence["resource_availability_pressure_count"],
      "resource_availability_reason_counts" =>
        row["resource_availability_reason_counts"] ||
          evidence["resource_availability_reason_counts"],
      "resource_availability_reason_ids" =>
        row["resource_availability_reason_ids"] || evidence["resource_availability_reason_ids"],
      "unavailable_resource_reason_counts" =>
        row["unavailable_resource_reason_counts"] ||
          evidence["unavailable_resource_reason_counts"],
      "unavailable_resource_reason_ids" =>
        row["unavailable_resource_reason_ids"] || evidence["unavailable_resource_reason_ids"],
      "station_availability_reason_counts" =>
        row["station_availability_reason_counts"] ||
          evidence["station_availability_reason_counts"],
      "station_availability_reason_ids" =>
        row["station_availability_reason_ids"] || evidence["station_availability_reason_ids"],
      "resource_blocking_dimension_counts" =>
        row["resource_blocking_dimension_counts"] ||
          evidence["resource_blocking_dimension_counts"],
      "blocked_contact_ids_by_blocking_dimension" =>
        row["blocked_contact_ids_by_blocking_dimension"] ||
          evidence["blocked_contact_ids_by_blocking_dimension"],
      "blocked_contact_ids_by_spacecraft_id" =>
        row["blocked_contact_ids_by_spacecraft_id"] ||
          evidence["blocked_contact_ids_by_spacecraft_id"],
      "blocked_contact_ids_by_status" =>
        row["blocked_contact_ids_by_status"] || evidence["blocked_contact_ids_by_status"]
    }
  end

  defp pressure_row_source(row, source_path) do
    row_source = Map.get(row, "source", "operational_readiness_report")

    cond do
      String.starts_with?(row_source, "operational_readiness_report") ->
        String.replace_prefix(row_source, "operational_readiness_report", source_path)

      String.starts_with?(row_source, "operational_readiness_gate_summary") ->
        String.replace_prefix(row_source, "operational_readiness_gate_summary", source_path)

      true ->
        source_path
    end
  end

  defp operational_readiness_report_pressure_rows(report) do
    classification = report["import_classification"] || "review_only"

    summary_row =
      %{
        "source" => "operational_readiness_report",
        "report_id" => report["report_id"],
        "source_artifact_type" => report["source_artifact_type"],
        "source_artifact_id" => report["source_artifact_id"],
        "readiness_level" => report["readiness_level"],
        "import_classification" => classification,
        "operational_readiness_status" => report["status"],
        "gate_count" => report["gate_count"],
        "passed_gate_count" => report["passed_gate_count"],
        "review_gate_count" => report["review_gate_count"],
        "analysis_gate_count" => report["analysis_gate_count"],
        "blocked_gate_count" => report["blocked_gate_count"],
        "evidence" => report["evidence"],
        "required_operator_action" => operational_readiness_pressure_action(classification),
        "source_operational_readiness_report" => report
      }
      |> Map.merge(import_readiness_context(report))
      |> Map.merge(schema_validation_context(report))
      |> Map.merge(resource_availability_context(report))
      |> compact_map()

    gate_rows =
      report
      |> Map.get("gates", [])
      |> List.wrap()
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&(Map.get(&1, "status") not in [nil, "passed"]))
      |> Enum.map(fn gate ->
        classification = operational_readiness_gate_pressure_classification(gate)
        gate_status = gate["status"] || "review_required"

        %{
          "source" => "operational_readiness_report.gates",
          "report_id" => report["report_id"],
          "source_artifact_type" => report["source_artifact_type"],
          "source_artifact_id" => report["source_artifact_id"],
          "readiness_level" => operational_readiness_pressure_level(classification),
          "import_classification" => classification,
          "operational_readiness_status" => gate_status,
          "readiness_gate_id" => gate["id"] || "operational_gate",
          "readiness_gate_status" => gate_status,
          "readiness_gate_classification" => classification,
          "readiness_gate_reason" => gate["reason"],
          "analysis_mode" => gate["analysis_mode"],
          "analysis_mode_source" => gate["analysis_mode_source"],
          "required_operator_action" => operational_readiness_pressure_action(classification),
          "source_operational_readiness_gate" => gate,
          "source_operational_readiness_report" => report
        }
        |> Map.merge(operator_training_context(gate))
        |> Map.merge(import_readiness_context(gate))
        |> Map.merge(schema_validation_context(gate))
        |> Map.merge(resource_availability_context(gate))
        |> compact_map()
      end)

    [summary_row | gate_rows]
  end

  defp operational_readiness_gate_summary_pressure_rows(summary) do
    summary = stringify_keys(summary || %{})
    classification = summary["import_classification"] || "review_only"
    non_passed_gates = operational_readiness_gate_summary_non_passed_gates(summary)
    gate_routing = operational_readiness_gate_summary_row_routing(summary, non_passed_gates)

    summary_row =
      %{
        "source" => "operational_readiness_gate_summary",
        "source_artifact_type" => summary["source_artifact_type"],
        "source_artifact_id" => summary["source_artifact_id"],
        "readiness_level" => summary["readiness_level"],
        "import_classification" => classification,
        "operational_readiness_status" => summary["status"],
        "gate_count" => summary["gate_count"],
        "passed_gate_count" => summary["passed_gate_count"],
        "review_gate_count" => summary["review_gate_count"],
        "analysis_gate_count" => summary["analysis_gate_count"],
        "blocked_gate_count" => summary["blocked_gate_count"],
        "gate_status_counts" => summary["gate_status_counts"],
        "gate_classification_counts" => summary["gate_classification_counts"],
        "passed_gate_ids" => summary["passed_gate_ids"],
        "review_required_gate_ids" => summary["review_required_gate_ids"],
        "analysis_only_gate_ids" => summary["analysis_only_gate_ids"],
        "blocked_gate_ids" => summary["blocked_gate_ids"],
        "non_passed_gate_ids" => summary["non_passed_gate_ids"],
        "assumptions" => summary["assumptions"],
        "required_operator_action" => operational_readiness_pressure_action(classification)
      }
      |> Map.merge(import_readiness_context(summary))
      |> Map.merge(schema_validation_context(summary))
      |> Map.merge(resource_availability_context(summary))
      |> compact_map()

    gate_rows =
      non_passed_gates
      |> Enum.map(fn gate ->
        classification = operational_readiness_gate_pressure_classification(gate)
        gate_status = gate["status"] || "review_required"

        %{
          "source" => "operational_readiness_gate_summary.non_passed_gates",
          "source_artifact_type" => summary["source_artifact_type"],
          "source_artifact_id" => summary["source_artifact_id"],
          "readiness_level" => operational_readiness_pressure_level(classification),
          "import_classification" => classification,
          "operational_readiness_status" => gate_status,
          "readiness_gate_id" => gate["id"] || "operational_gate",
          "readiness_gate_status" => gate_status,
          "readiness_gate_classification" => classification,
          "readiness_gate_reason" => gate["reason"],
          "analysis_mode" => gate["analysis_mode"],
          "analysis_mode_source" => gate["analysis_mode_source"],
          "gate_status_counts" => gate_routing["gate_status_counts"],
          "gate_classification_counts" => gate_routing["gate_classification_counts"],
          "passed_gate_ids" => summary["passed_gate_ids"],
          "review_required_gate_ids" => gate_routing["review_required_gate_ids"],
          "analysis_only_gate_ids" => gate_routing["analysis_only_gate_ids"],
          "blocked_gate_ids" => gate_routing["blocked_gate_ids"],
          "non_passed_gate_ids" => gate_routing["non_passed_gate_ids"],
          "assumptions" => summary["assumptions"],
          "required_operator_action" => operational_readiness_pressure_action(classification),
          "source_operational_readiness_gate" => gate
        }
        |> Map.merge(operator_training_context(gate))
        |> Map.merge(import_readiness_context(gate))
        |> Map.merge(schema_validation_context(gate))
        |> Map.merge(resource_availability_context(gate))
        |> compact_map()
      end)

    [summary_row | gate_rows]
  end

  defp operational_readiness_gate_summary_non_passed_gates(summary) do
    summary
    |> Map.get("non_passed_gates", [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
  end

  defp operational_readiness_gate_summary_row_routing(summary, []),
    do: %{
      "gate_status_counts" => summary["gate_status_counts"],
      "gate_classification_counts" => summary["gate_classification_counts"],
      "review_required_gate_ids" => summary["review_required_gate_ids"],
      "analysis_only_gate_ids" => summary["analysis_only_gate_ids"],
      "blocked_gate_ids" => summary["blocked_gate_ids"],
      "non_passed_gate_ids" => summary["non_passed_gate_ids"]
    }

  defp operational_readiness_gate_summary_row_routing(_summary, gates) do
    Enum.reduce(
      gates,
      %{
        "gate_status_counts" => %{},
        "gate_classification_counts" => %{},
        "review_required_gate_ids" => [],
        "analysis_only_gate_ids" => [],
        "blocked_gate_ids" => [],
        "non_passed_gate_ids" => []
      },
      fn gate, routing ->
        gate_id = gate["id"] || "operational_gate"
        status = gate["status"] || "review_required"
        classification = operational_readiness_gate_pressure_classification(gate)

        routing
        |> update_in(["gate_status_counts", status], &((&1 || 0) + 1))
        |> update_in(["gate_classification_counts", classification], &((&1 || 0) + 1))
        |> update_in(["non_passed_gate_ids"], &(&1 ++ [gate_id]))
        |> operational_readiness_gate_summary_put_status_gate_id(status, gate_id)
      end
    )
  end

  defp operational_readiness_gate_summary_put_status_gate_id(routing, "review_required", gate_id) do
    update_in(routing, ["review_required_gate_ids"], &(&1 ++ [gate_id]))
  end

  defp operational_readiness_gate_summary_put_status_gate_id(routing, "analysis_only", gate_id) do
    update_in(routing, ["analysis_only_gate_ids"], &(&1 ++ [gate_id]))
  end

  defp operational_readiness_gate_summary_put_status_gate_id(routing, "blocked", gate_id) do
    update_in(routing, ["blocked_gate_ids"], &(&1 ++ [gate_id]))
  end

  defp operational_readiness_gate_summary_put_status_gate_id(routing, _status, _gate_id),
    do: routing

  defp operational_readiness_gate_pressure_classification(%{"status" => "blocked"}),
    do: "blocked"

  defp operational_readiness_gate_pressure_classification(%{"status" => "analysis_only"}),
    do: "analysis_only"

  defp operational_readiness_gate_pressure_classification(%{"classification" => classification})
       when classification not in [nil, ""],
       do: classification

  defp operational_readiness_gate_pressure_classification(_gate), do: "review_only"

  defp operational_readiness_pressure_action("analysis_only"),
    do: "record_operational_readiness_analysis_only"

  defp operational_readiness_pressure_action("blocked"),
    do: "review_blocked_operational_readiness"

  defp operational_readiness_pressure_action(_classification),
    do: "review_operational_readiness"

  defp operational_readiness_pressure_level("analysis_only"), do: "analysis_only"
  defp operational_readiness_pressure_level("blocked"), do: "blocked"
  defp operational_readiness_pressure_level("importable"), do: "import_eligible"
  defp operational_readiness_pressure_level(_classification), do: "operator_review"

  defp row_or_evidence(row, evidence, key) do
    if Map.has_key?(row, key), do: row[key], else: evidence[key]
  end

  defp source_reports(mission_state, fields, opts) do
    source_report_entries = Keyword.fetch!(opts, :source_report_entries)
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      source_report_entries.(Map.get(mission_state, field), source_path)
    end)
  end

  defp result_artifact_embedded_reports(mission_state, report_key, opts) do
    callbacks = callbacks!(opts)
    callbacks.result_artifact_embedded_reports.(mission_state, report_key)
  end

  defp result_artifact_operational_readiness_gate_summaries(mission_state, opts) do
    callbacks = callbacks!(opts)
    callbacks.result_artifact_operational_readiness_gate_summaries.(mission_state)
  end

  defp prior_plan_result_artifact_operational_readiness_reports(prior_plan, opts) do
    callbacks = prior_plan_callbacks!(opts)

    prior_plan
    |> callbacks.result_artifacts_with_source.()
    |> Enum.flat_map(fn {artifact, source_path} ->
      result_artifact_operational_readiness_reports(artifact, source_path, callbacks)
    end)
  end

  defp result_artifact_operational_readiness_reports(artifact, source_path, callbacks) do
    artifact = stringify_keys(artifact)

    if artifact["schema_contract"] == "operational_readiness_report.v1" do
      [{callbacks.put_inherited_result_artifact_trust_boundary.(artifact, artifact), source_path}]
    else
      ["source_operational_readiness_report", "operational_readiness_report"]
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

  defp prior_plan_result_artifact_operational_readiness_gate_summaries(prior_plan, opts) do
    callbacks = prior_plan_callbacks!(opts)

    prior_plan
    |> callbacks.result_artifacts_with_source.()
    |> Enum.flat_map(fn {artifact, source_path} ->
      result_artifact_operational_readiness_gate_summaries(artifact, source_path, callbacks)
    end)
  end

  defp result_artifact_operational_readiness_gate_summaries(artifact, source_path, callbacks) do
    artifact = stringify_keys(artifact)

    if artifact["schema_contract"] == "operational_readiness_gate_summary.v1" do
      [{callbacks.put_inherited_result_artifact_trust_boundary.(artifact, artifact), source_path}]
    else
      ["source_operational_readiness_gate_summary", "operational_readiness_gate_summary"]
      |> Enum.flat_map(fn summary_key ->
        result_artifact_embedded_report_entries(
          Map.get(artifact, summary_key),
          artifact,
          "#{source_path}.#{summary_key}",
          callbacks
        )
      end)
    end
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
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports),
      result_artifact_operational_readiness_gate_summaries:
        Keyword.fetch!(opts, :result_artifact_operational_readiness_gate_summaries)
    }
  end

  defp prior_plan_callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      result_artifacts_with_source: Keyword.fetch!(opts, :result_artifacts_with_source),
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

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

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
