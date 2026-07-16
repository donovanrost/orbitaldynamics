defmodule OrbitalDynamics.OperatorReview.TimelineIntegrity do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def report_package(report) do
    {rows, source_artifact_id, provenance} = report_package_input(report)

    build_package(rows, "timeline_integrity_report.v1", source_artifact_id, provenance)
  end

  def candidate_refresh_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_integrity_report",
         get_in(artifact, ["accepted_planning_state", "source_timeline_integrity_report"])},
        {"candidate_refresh.accepted_planning_state.timeline_integrity_report",
         get_in(artifact, ["accepted_planning_state", "timeline_integrity_report"])},
        {"candidate_refresh.mission_state.source_timeline_integrity_report",
         get_in(artifact, ["mission_state", "source_timeline_integrity_report"])},
        {"candidate_refresh.mission_state.timeline_integrity_report",
         get_in(artifact, ["mission_state", "timeline_integrity_report"])},
        {"candidate_refresh.source_timeline_integrity_report",
         artifact["source_timeline_integrity_report"]},
        {"candidate_refresh.timeline_integrity_report", artifact["timeline_integrity_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  def report_package_input(report) do
    report = stringify_keys(report || %{})
    report = Map.put_new(report, "schema_contract", "timeline_integrity_report.v1")

    {
      report_rows(report),
      Map.get(report, "id") || Map.get(report, "source") || "timeline_integrity_report",
      Map.get(report, "provenance", %{})
    }
  end

  def source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  def source_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> report_rows("#{source}.rows")
  end

  def source_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_rows(
         %{"schema_contract" => "timeline_integrity_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_integrity_report",
       artifact["source_timeline_integrity_report"]},
      {"#{source}.timeline_integrity_report", artifact["timeline_integrity_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  def report_rows(%{} = report) do
    report_rows(report, "timeline_integrity_report.rows")
  end

  def report_rows(%{} = report, source) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      review_row(row, index, report, source)
    end)
  end

  defp review_row(row, index, summary, source) do
    subject_id = row["timeline_id"] || row["activity_id"]
    required_action = row["required_operator_action"] || "review_timeline_integrity"
    reason = row["operator_action_reason"] || row["reason"] || "timeline_integrity_issue"

    %{
      "id" => review_id(["timeline_integrity", subject_id, index]),
      "review_type" => "timeline_integrity_review",
      "source" => source,
      "subject_id" => subject_id,
      "timeline_id" => row["timeline_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "scenario_id" => row["scenario_id"],
      "timeline_identity" => row["timeline_identity"],
      "timeline_integrity_status" => row["timeline_integrity_status"] || "review_required",
      "timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
      "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
      "timeline_integrity_issues" => row["timeline_integrity_issues"],
      "action" => required_action,
      "required_operator_action" => required_action,
      "approval_status" => "operator_review_required",
      "reason" => reason,
      "operator_action_reason" => reason,
      "dependency_activity_ids" => row["dependency_activity_ids"],
      "dependency_timeline_ids" => row["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
      "missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
      "missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
      "self_dependency_activity_ids" => row["self_dependency_activity_ids"],
      "self_dependency_timeline_ids" => row["self_dependency_timeline_ids"],
      "duplicate_dependency_activity_ids" => row["duplicate_dependency_activity_ids"],
      "duplicate_dependency_timeline_ids" => row["duplicate_dependency_timeline_ids"],
      "duplicate_exclusivity_activity_ids" => row["duplicate_exclusivity_activity_ids"],
      "duplicate_exclusivity_timeline_ids" => row["duplicate_exclusivity_timeline_ids"],
      "dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
      "dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
      "dependency_order_violation_activity_ids" => row["dependency_order_violation_activity_ids"],
      "dependency_order_violation_timeline_ids" => row["dependency_order_violation_timeline_ids"],
      "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
      "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
      "exclusivity_violation_group" => row["exclusivity_violation_group"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "source_activity_count" => summary["activity_count"],
      "source_valid_activity_count" => summary["valid_activity_count"],
      "source_invalid_activity_input_count" => summary["invalid_activity_input_count"],
      "source_timeline_integrity_review_count" => summary["timeline_integrity_review_count"],
      "source_timeline_integrity_issue_count" => summary["timeline_integrity_issue_count"],
      "source_timeline_integrity_issue_types" => summary["timeline_integrity_issue_types"],
      "source_timeline_integrity_issue_type_counts" =>
        summary["timeline_integrity_issue_type_counts"],
      "source_dependency_issue_count" => summary["dependency_issue_count"],
      "source_exclusivity_issue_count" => summary["exclusivity_issue_count"],
      "review_activity_ids" => summary["review_activity_ids"],
      "review_timeline_ids" => summary["review_timeline_ids"],
      "dependency_review_activity_ids" => summary["dependency_review_activity_ids"],
      "dependency_review_timeline_ids" => summary["dependency_review_timeline_ids"],
      "exclusivity_review_activity_ids" => summary["exclusivity_review_activity_ids"],
      "exclusivity_review_timeline_ids" => summary["exclusivity_review_timeline_ids"],
      "invalid_activity_input_ids" => summary["invalid_activity_input_ids"],
      "source_timeline_integrity" => row
    }
    |> compact_map()
  end

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp build_package(rows, source_artifact_type, source_artifact_id, provenance) do
    PackageBuilder.build(
      rows,
      source_artifact_type,
      source_artifact_id,
      provenance,
      @schema_contract,
      Capabilities.model_limits()
    )
  end
end
