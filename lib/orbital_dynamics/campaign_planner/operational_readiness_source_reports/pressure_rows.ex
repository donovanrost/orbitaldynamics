defmodule OrbitalDynamics.CampaignPlanner.OperationalReadinessSourceReports.PressureRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.OperationalReadinessSourceReports.Context

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
      |> Map.merge(Context.import_readiness_context(report))
      |> Map.merge(Context.schema_validation_context(report))
      |> Map.merge(Context.resource_availability_context(report))
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
        |> Map.merge(Context.operator_training_context(gate))
        |> Map.merge(Context.import_readiness_context(gate))
        |> Map.merge(Context.schema_validation_context(gate))
        |> Map.merge(Context.resource_availability_context(gate))
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
      |> Map.merge(Context.import_readiness_context(summary))
      |> Map.merge(Context.schema_validation_context(summary))
      |> Map.merge(Context.resource_availability_context(summary))
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
        |> Map.merge(Context.operator_training_context(gate))
        |> Map.merge(Context.import_readiness_context(gate))
        |> Map.merge(Context.schema_validation_context(gate))
        |> Map.merge(Context.resource_availability_context(gate))
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
