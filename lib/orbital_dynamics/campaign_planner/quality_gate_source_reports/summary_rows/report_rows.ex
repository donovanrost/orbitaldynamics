defmodule OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.ReportRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.OperationalReadinessSourceReports
  alias OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.Context

  def operational_quality_gate_summary(summary) do
    summary = stringify_keys(summary)

    rows =
      (Map.get(summary, "non_passed_rows") || Map.get(summary, "rows", []))
      |> List.wrap()
      |> Enum.map(&stringify_keys/1)

    rows
    |> Enum.map(fn row ->
      %{
        "source" => "operational_quality_gate_summary.non_passed_rows",
        "report_id" => summary["source_quality_gate_report_id"],
        "source_artifact_type" => summary["source_artifact_type"],
        "source_artifact_id" => summary["source_artifact_id"],
        "source_readiness_report_id" => summary["source_readiness_report_id"],
        "readiness_level" => summary["readiness_level"],
        "import_classification" => summary["import_classification"],
        "quality_gate_status" => summary["status"],
        "gate_count" => summary["gate_count"],
        "passed_gate_count" => summary["passed_gate_count"],
        "review_gate_count" => summary["review_gate_count"],
        "analysis_gate_count" => summary["analysis_gate_count"],
        "blocked_gate_count" => summary["blocked_gate_count"],
        "gate_id" => row["gate_id"],
        "gate_status" => row["status"],
        "gate_classification" => row["classification"],
        "gate_reason" => row["reason"],
        "analysis_mode" => row["analysis_mode"],
        "analysis_mode_source" => row["analysis_mode_source"],
        "assumptions" => summary["assumptions"],
        "source_quality_gate_row" => row,
        "source_quality_gate_report" => summary
      }
      |> Map.merge(OperationalReadinessSourceReports.operator_training_context(row))
      |> Map.merge(Context.resource_context(row))
      |> compact_map()
    end)
  end

  def quality_gate_report(report) do
    report = stringify_keys(report || %{})

    rows =
      report
      |> Map.get("rows", [])
      |> List.wrap()
      |> Enum.map(&stringify_keys/1)

    summary = quality_gate_report_row_summary(report, rows)

    rows
    |> Enum.map(fn row ->
      %{
        "source" => "quality_gate_report.rows",
        "report_id" => report["report_id"],
        "source_artifact_type" => report["source_artifact_type"],
        "source_artifact_id" => report["source_artifact_id"],
        "source_readiness_report_id" => report["source_readiness_report_id"],
        "readiness_level" => summary["readiness_level"],
        "import_classification" => summary["import_classification"],
        "quality_gate_status" => summary["status"],
        "gate_count" => summary["gate_count"],
        "passed_gate_count" => summary["passed_gate_count"],
        "review_gate_count" => summary["review_gate_count"],
        "analysis_gate_count" => summary["analysis_gate_count"],
        "blocked_gate_count" => summary["blocked_gate_count"],
        "gate_id" => row["gate_id"],
        "gate_status" => row["status"],
        "gate_classification" => row["classification"],
        "gate_reason" => row["reason"],
        "analysis_mode" => row["analysis_mode"],
        "analysis_mode_source" => row["analysis_mode_source"],
        "source_quality_gate_row" => row,
        "source_quality_gate_report" => report
      }
      |> Map.merge(OperationalReadinessSourceReports.operator_training_context(row))
      |> Map.merge(Context.resource_context(row))
      |> compact_map()
    end)
  end

  defp quality_gate_report_row_summary(report, rows) do
    classification =
      rows
      |> quality_gate_report_row_import_classification()
      |> Kernel.||(report["import_classification"])

    status_counts = quality_gate_report_row_counts(rows, "status")

    %{
      "readiness_level" => quality_gate_report_readiness_level(classification, report),
      "import_classification" => classification,
      "status" => quality_gate_report_status(classification, report),
      "gate_count" => length(rows),
      "passed_gate_count" => Map.get(status_counts, "passed", 0),
      "review_gate_count" => Map.get(status_counts, "review_required", 0),
      "analysis_gate_count" => Map.get(status_counts, "analysis_only", 0),
      "blocked_gate_count" => Map.get(status_counts, "blocked", 0)
    }
  end

  defp quality_gate_report_row_import_classification(rows) do
    statuses = Enum.map(rows, & &1["status"])

    cond do
      "blocked" in statuses -> "blocked"
      "analysis_only" in statuses -> "analysis_only"
      "review_required" in statuses -> "review_only"
      "passed" in statuses -> "importable"
      true -> nil
    end
  end

  defp quality_gate_report_row_counts(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
  end

  defp quality_gate_report_readiness_level("importable", _report), do: "import_eligible"
  defp quality_gate_report_readiness_level("review_only", _report), do: "operator_review"
  defp quality_gate_report_readiness_level("analysis_only", _report), do: "analysis_only"
  defp quality_gate_report_readiness_level("blocked", _report), do: "blocked"
  defp quality_gate_report_readiness_level(_classification, report), do: report["readiness_level"]

  defp quality_gate_report_status("importable", _report), do: "passed"
  defp quality_gate_report_status("review_only", _report), do: "review_required"
  defp quality_gate_report_status("analysis_only", _report), do: "analysis_only"
  defp quality_gate_report_status("blocked", _report), do: "blocked"
  defp quality_gate_report_status(_classification, report), do: report["status"]

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
