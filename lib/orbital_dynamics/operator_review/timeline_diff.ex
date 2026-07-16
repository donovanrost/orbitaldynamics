defmodule OrbitalDynamics.OperatorReview.TimelineDiff do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def report_package(report) do
    {rows, source_artifact_id, provenance} = report_package_input(report)

    build_package(rows, "timeline_diff_report.v1", source_artifact_id, provenance)
  end

  def summary_package(summary) do
    {rows, source_artifact_id, provenance} = summary_package_input(summary)

    build_package(rows, "timeline_diff_summary.v1", source_artifact_id, provenance)
  end

  def report_package_input(report) do
    report = stringify_keys(report || %{})

    {
      rows(Map.get(report, "rows", [])),
      Map.get(report, "id") || Map.get(report, "source") || "timeline_diff_report",
      Map.get(report, "provenance", %{})
    }
  end

  def summary_package_input(summary) do
    summary = stringify_keys(summary || %{})
    summary = Map.put_new(summary, "schema_contract", "timeline_diff_summary.v1")

    {
      summary_rows(summary),
      Map.get(summary, "id") || Map.get(summary, "source") || "timeline_diff_summary",
      Map.get(summary, "provenance", %{})
    }
  end

  def candidate_refresh_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_diff_report",
         get_in(artifact, ["accepted_planning_state", "source_timeline_diff_report"])},
        {"candidate_refresh.accepted_planning_state.timeline_diff_report",
         get_in(artifact, ["accepted_planning_state", "timeline_diff_report"])},
        {"candidate_refresh.mission_state.source_timeline_diff_report",
         get_in(artifact, ["mission_state", "source_timeline_diff_report"])},
        {"candidate_refresh.mission_state.timeline_diff_report",
         get_in(artifact, ["mission_state", "timeline_diff_report"])},
        {"candidate_refresh.source_timeline_diff_report",
         artifact["source_timeline_diff_report"]},
        {"candidate_refresh.timeline_diff_report", artifact["timeline_diff_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    summary_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_timeline_diff_summary",
         get_in(artifact, ["accepted_planning_state", "source_timeline_diff_summary"])},
        {"candidate_refresh.accepted_planning_state.timeline_diff_summary",
         get_in(artifact, ["accepted_planning_state", "timeline_diff_summary"])},
        {"candidate_refresh.mission_state.source_timeline_diff_summary",
         get_in(artifact, ["mission_state", "source_timeline_diff_summary"])},
        {"candidate_refresh.mission_state.timeline_diff_summary",
         get_in(artifact, ["mission_state", "timeline_diff_summary"])},
        {"candidate_refresh.source_timeline_diff_summary",
         artifact["source_timeline_diff_summary"]},
        {"candidate_refresh.timeline_diff_summary", artifact["timeline_diff_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_summary_rows(summary_or_summaries, source)
      end)

    direct_rows ++ summary_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  defp source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> rows("#{source}.rows")
  end

  defp source_report_rows(_report, _source), do: []

  defp source_summary_rows(summaries, source) when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_summary_rows(summary, "#{source}[#{index}]")
    end)
  end

  defp source_summary_rows(%{} = summary, source) do
    summary
    |> stringify_keys()
    |> summary_rows("#{source}.review_rows")
  end

  defp source_summary_rows(_summary, _source), do: []

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
         %{"schema_contract" => "timeline_diff_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(
         %{"schema_contract" => "timeline_diff_summary.v1"} = summary,
         source
       ) do
    source_summary_rows(summary, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_diff_report", artifact["source_timeline_diff_report"]},
      {"#{source}.timeline_diff_report", artifact["timeline_diff_report"]},
      {"#{source}.source_timeline_diff_summary", artifact["source_timeline_diff_summary"]},
      {"#{source}.timeline_diff_summary", artifact["timeline_diff_summary"]}
    ]
    |> Enum.flat_map(fn
      {summary_source, %{} = summary_or_report} ->
        summary_or_report = stringify_keys(summary_or_report)

        case summary_or_report["schema_contract"] do
          "timeline_diff_summary.v1" ->
            source_summary_rows(summary_or_report, summary_source)

          _contract ->
            source_report_rows(summary_or_report, summary_source)
        end

      {summary_source, summaries_or_reports} ->
        source_report_rows(summaries_or_reports, summary_source) ++
          source_summary_rows(summaries_or_reports, summary_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  def rows(rows, source \\ "timeline_diff_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&Map.get(&1, "requires_operator_review", false))
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      review_row(row, index, source)
    end)
  end

  def summary_rows(summary, source \\ "timeline_diff_summary.review_rows")

  def summary_rows(%{} = summary, source) do
    summary
    |> Map.get("review_rows", [])
    |> rows(source)
    |> Enum.map(&put_summary_context(&1, summary))
  end

  def put_summary_context(row, summary) do
    %{
      "source_artifact_type" => summary["source_artifact_type"],
      "source_timeline_diff_summary_source_activity_count" => summary["source_activity_count"],
      "source_timeline_diff_summary_replacement_activity_count" =>
        summary["replacement_activity_count"],
      "source_timeline_diff_summary_row_count" => summary["row_count"],
      "source_timeline_diff_summary_added_count" => summary["added_count"],
      "source_timeline_diff_summary_removed_count" => summary["removed_count"],
      "source_timeline_diff_summary_changed_count" => summary["changed_count"],
      "source_timeline_diff_summary_unchanged_count" => summary["unchanged_count"],
      "source_timeline_diff_summary_review_required_count" => summary["review_required_count"],
      "source_timeline_diff_summary_duplicate_timeline_identity_count" =>
        summary["duplicate_timeline_identity_count"],
      "source_timeline_diff_summary_invalid_source_activity_input_count" =>
        summary["invalid_source_activity_input_count"],
      "source_timeline_diff_summary_invalid_replacement_activity_input_count" =>
        summary["invalid_replacement_activity_input_count"],
      "source_timeline_diff_summary_diff_status_counts" => summary["diff_status_counts"],
      "source_timeline_diff_summary_transition_decision_counts" =>
        summary["transition_decision_counts"],
      "source_timeline_diff_summary_required_operator_action_counts" =>
        summary["required_operator_action_counts"],
      "source_timeline_diff_summary_changed_field_counts" => summary["changed_field_counts"],
      "source_timeline_diff_summary_status_transition_category_counts" =>
        summary["status_transition_category_counts"],
      "source_timeline_diff_summary_approval_transition_category_counts" =>
        summary["approval_transition_category_counts"],
      "source_timeline_diff_summary_added_timeline_ids" => summary["added_timeline_ids"],
      "source_timeline_diff_summary_removed_timeline_ids" => summary["removed_timeline_ids"],
      "source_timeline_diff_summary_changed_timeline_ids" => summary["changed_timeline_ids"],
      "source_timeline_diff_summary_unchanged_timeline_ids" => summary["unchanged_timeline_ids"],
      "source_timeline_diff_summary_duplicate_timeline_identity_ids" =>
        summary["duplicate_timeline_identity_ids"],
      "source_timeline_diff_summary_invalid_source_activity_input_ids" =>
        summary["invalid_source_activity_input_ids"],
      "source_timeline_diff_summary_invalid_replacement_activity_input_ids" =>
        summary["invalid_replacement_activity_input_ids"],
      "source_timeline_diff_summary_review_timeline_ids" => summary["review_timeline_ids"],
      "source_timeline_diff_summary_review_timeline_ids_by_required_operator_action" =>
        summary["review_timeline_ids_by_required_operator_action"],
      "source_timeline_diff_summary_review_timeline_ids_by_status_transition_category" =>
        summary["review_timeline_ids_by_status_transition_category"],
      "source_timeline_diff_summary_review_timeline_ids_by_approval_transition_category" =>
        summary["review_timeline_ids_by_approval_transition_category"],
      "source_timeline_diff_summary_timeline_ids_by_changed_field" =>
        summary["timeline_ids_by_changed_field"],
      "source_timeline_diff_summary" => summary
    }
    |> compact_map()
    |> then(&Map.merge(row, &1))
  end

  def review_row(row, index, source) do
    %{
      "id" => review_id(["timeline_diff", row["timeline_id"], index]),
      "review_type" => "timeline_diff_review",
      "source" => source,
      "subject_id" => row["timeline_id"],
      "timeline_id" => row["timeline_id"],
      "diff_status" => row["diff_status"],
      "activity_id" => row["replacement_activity_id"] || row["source_activity_id"],
      "activity_type" => row["replacement_activity_type"] || row["source_activity_type"],
      "source_activity_id" => row["source_activity_id"],
      "replacement_activity_id" => row["replacement_activity_id"],
      "source_activity_type" => row["source_activity_type"],
      "replacement_activity_type" => row["replacement_activity_type"],
      "source_spacecraft_id" => row["source_spacecraft_id"],
      "replacement_spacecraft_id" => row["replacement_spacecraft_id"],
      "source_ground_station_id" => row["source_ground_station_id"],
      "replacement_ground_station_id" => row["replacement_ground_station_id"],
      "source_target_id" => row["source_target_id"],
      "replacement_target_id" => row["replacement_target_id"],
      "source_source_window_id" => row["source_source_window_id"],
      "replacement_source_window_id" => row["replacement_source_window_id"],
      "action" => row["required_operator_action"],
      "required_operator_action" => row["required_operator_action"],
      "approval_status" => "operator_review_required",
      "reason" => row["reason"],
      "operator_action_reason" => row["operator_action_reason"] || row["reason"],
      "scenario_id" => row["scenario_id"],
      "source_starts_at_s" => row["source_starts_at_s"],
      "source_ends_at_s" => row["source_ends_at_s"],
      "replacement_starts_at_s" => row["replacement_starts_at_s"],
      "replacement_ends_at_s" => row["replacement_ends_at_s"],
      "start_delta_s" => row["start_delta_s"],
      "end_delta_s" => row["end_delta_s"],
      "source_status" => row["source_status"],
      "replacement_status" => row["replacement_status"],
      "source_approval_status" => row["source_approval_status"],
      "replacement_approval_status" => row["replacement_approval_status"],
      "source_locked" => row["source_locked"],
      "replacement_locked" => row["replacement_locked"],
      "source_protection_decision" => row["source_protection_decision"],
      "source_protection_category" => row["source_protection_category"],
      "source_protection_reason" => row["source_protection_reason"],
      "replacement_protection_decision" => row["replacement_protection_decision"],
      "replacement_protection_category" => row["replacement_protection_category"],
      "replacement_protection_reason" => row["replacement_protection_reason"],
      "source_timeline_integrity_status" => row["source_timeline_integrity_status"],
      "source_timeline_integrity_issue_count" => row["source_timeline_integrity_issue_count"],
      "source_timeline_integrity_issue_types" => row["source_timeline_integrity_issue_types"],
      "source_timeline_integrity_issues" => row["source_timeline_integrity_issues"],
      "source_missing_dependency_activity_ids" => row["source_missing_dependency_activity_ids"],
      "source_missing_dependency_timeline_ids" => row["source_missing_dependency_timeline_ids"],
      "source_self_dependency_activity_ids" => row["source_self_dependency_activity_ids"],
      "source_self_dependency_timeline_ids" => row["source_self_dependency_timeline_ids"],
      "source_dependency_cycle_activity_ids" => row["source_dependency_cycle_activity_ids"],
      "source_dependency_cycle_timeline_ids" => row["source_dependency_cycle_timeline_ids"],
      "replacement_timeline_integrity_status" => row["replacement_timeline_integrity_status"],
      "replacement_timeline_integrity_issue_count" =>
        row["replacement_timeline_integrity_issue_count"],
      "replacement_timeline_integrity_issue_types" =>
        row["replacement_timeline_integrity_issue_types"],
      "replacement_timeline_integrity_issues" => row["replacement_timeline_integrity_issues"],
      "replacement_missing_dependency_activity_ids" =>
        row["replacement_missing_dependency_activity_ids"],
      "replacement_missing_dependency_timeline_ids" =>
        row["replacement_missing_dependency_timeline_ids"],
      "replacement_self_dependency_activity_ids" =>
        row["replacement_self_dependency_activity_ids"],
      "replacement_self_dependency_timeline_ids" =>
        row["replacement_self_dependency_timeline_ids"],
      "replacement_dependency_cycle_activity_ids" =>
        row["replacement_dependency_cycle_activity_ids"],
      "replacement_dependency_cycle_timeline_ids" =>
        row["replacement_dependency_cycle_timeline_ids"],
      "status_transition" => row["status_transition"],
      "approval_transition" => row["approval_transition"],
      "changed_fields" => Map.get(row, "changed_fields", []),
      "timeline_identity_collision" => row["timeline_identity_collision"],
      "duplicate_timeline_identity_scope" => row["duplicate_timeline_identity_scope"],
      "source_duplicate_activity_count" => row["source_duplicate_activity_count"],
      "replacement_duplicate_activity_count" => row["replacement_duplicate_activity_count"],
      "source_duplicate_activity_ids" => row["source_duplicate_activity_ids"],
      "replacement_duplicate_activity_ids" => row["replacement_duplicate_activity_ids"],
      "source_duplicate_activities" => row["source_duplicate_activities"],
      "replacement_duplicate_activities" => row["replacement_duplicate_activities"],
      "source_invalid_activity_input" => row["source_invalid_activity_input"],
      "source_invalid_activity_input_reason" => row["source_invalid_activity_input_reason"],
      "source_activity" => row["source_activity"],
      "replacement_invalid_activity_input" => row["replacement_invalid_activity_input"],
      "replacement_invalid_activity_input_reason" =>
        row["replacement_invalid_activity_input_reason"],
      "replacement_activity" => row["replacement_activity"],
      "transition_decision" => row["transition_decision"],
      "transition_decision_reason" => row["transition_decision_reason"],
      "requires_operator_review" => row["requires_operator_review"],
      "source_timeline_identity" => row["source_timeline_identity"],
      "replacement_timeline_identity" => row["replacement_timeline_identity"],
      "source_activity_context" => row["source_activity_context"],
      "replacement_activity_context" => row["replacement_activity_context"],
      "application_status" => row["application_status"],
      "selected_activity_source" => row["selected_activity_source"],
      "selected_activity" => row["selected_activity"],
      "selected_timeline_integrity_status" => row["selected_timeline_integrity_status"],
      "selected_timeline_integrity_issue_count" => row["selected_timeline_integrity_issue_count"],
      "selected_timeline_integrity_issue_types" => row["selected_timeline_integrity_issue_types"],
      "selected_timeline_integrity_issues" => row["selected_timeline_integrity_issues"],
      "selected_missing_dependency_activity_ids" =>
        row["selected_missing_dependency_activity_ids"],
      "selected_missing_dependency_timeline_ids" =>
        row["selected_missing_dependency_timeline_ids"],
      "selected_self_dependency_activity_ids" => row["selected_self_dependency_activity_ids"],
      "selected_self_dependency_timeline_ids" => row["selected_self_dependency_timeline_ids"],
      "selected_duplicate_dependency_activity_ids" =>
        row["selected_duplicate_dependency_activity_ids"],
      "selected_duplicate_dependency_timeline_ids" =>
        row["selected_duplicate_dependency_timeline_ids"],
      "selected_duplicate_exclusivity_activity_ids" =>
        row["selected_duplicate_exclusivity_activity_ids"],
      "selected_duplicate_exclusivity_timeline_ids" =>
        row["selected_duplicate_exclusivity_timeline_ids"],
      "selected_dependency_cycle_activity_ids" => row["selected_dependency_cycle_activity_ids"],
      "selected_dependency_cycle_timeline_ids" => row["selected_dependency_cycle_timeline_ids"],
      "selected_dependency_order_violation_activity_ids" =>
        row["selected_dependency_order_violation_activity_ids"],
      "selected_dependency_order_violation_timeline_ids" =>
        row["selected_dependency_order_violation_timeline_ids"],
      "selected_exclusivity_violation_activity_ids" =>
        row["selected_exclusivity_violation_activity_ids"],
      "selected_exclusivity_violation_timeline_ids" =>
        row["selected_exclusivity_violation_timeline_ids"],
      "selected_exclusivity_violation_group" => row["selected_exclusivity_violation_group"],
      "source_timeline_diff" => row
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
