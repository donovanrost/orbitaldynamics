defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_source_report_values: 1,
      merge_count_maps: 1,
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def timeline_diff_report_input_summary([], _callbacks), do: nil

  def timeline_diff_report_input_summary(sources, callbacks) do
    sources =
      callback!(callbacks, :deduplicate_shadowed_mission_state_result_artifact_sources).(sources)

    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => timeline_diff_input_summary_contract(reports),
      "count" => length(sources),
      "row_count" =>
        sum_report_count(reports, callback!(callbacks, :timeline_diff_report_row_count)),
      "duplicate_timeline_identity_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :timeline_diff_report_duplicate_timeline_identity_count)
        ),
      "duplicate_source_timeline_identity_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :timeline_diff_report_duplicate_source_timeline_identity_count)
        ),
      "duplicate_replacement_timeline_identity_count" =>
        sum_report_count(
          reports,
          callback!(
            callbacks,
            :timeline_diff_report_duplicate_replacement_timeline_identity_count
          )
        ),
      "removed_downlink_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :timeline_diff_report_removed_downlink_count)
        ),
      "removed_observation_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :timeline_diff_report_removed_observation_count)
        ),
      "changed_downlink_shortfall_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :timeline_diff_report_changed_downlink_shortfall_count)
        ),
      "changed_contact_feedback_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :timeline_diff_report_changed_contact_feedback_count)
        ),
      "changed_observation_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :timeline_diff_report_changed_observation_count)
        ),
      "changed_observation_quality_feedback_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :timeline_diff_report_changed_observation_quality_feedback_count)
        ),
      "changed_command_feedback_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :timeline_diff_report_changed_command_feedback_count)
        ),
      "changed_maneuver_feedback_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :timeline_diff_report_changed_maneuver_feedback_count)
        ),
      "diff_status_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :timeline_diff_report_status_counts))
        |> merge_count_maps(),
      "required_operator_action_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :timeline_diff_report_required_operator_action_counts))
        |> merge_count_maps(),
      "duplicate_timeline_identity_scope_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :timeline_diff_report_duplicate_identity_scope_counts))
        |> merge_count_maps(),
      "source_activity_id_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :timeline_diff_report_source_activity_id_counts))
        |> merge_count_maps(),
      "replacement_activity_id_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :timeline_diff_report_replacement_activity_id_counts))
        |> merge_count_maps(),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_timeline_diff_trust_boundaries)
        ),
      "trust_boundaries" => callback!(callbacks, :source_timeline_diff_trust_boundaries).(reports)
    }
    |> compact_map()
  end

  def integrity_report_input_summary([], _callbacks), do: nil

  def integrity_report_input_summary(sources, callbacks) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "timeline_integrity_report.v1",
      "count" => length(sources),
      "row_count" =>
        sum_report_count(reports, &timeline_integrity_report_row_count(&1, callbacks)),
      "timeline_integrity_issue_count" =>
        sum_report_count(reports, &timeline_integrity_report_issue_count(&1, callbacks)),
      "timeline_integrity_review_count" =>
        sum_report_count(reports, &timeline_integrity_report_review_count(&1, callbacks)),
      "dependency_issue_count" =>
        sum_report_count(
          reports,
          &timeline_integrity_report_dependency_issue_count(&1, callbacks)
        ),
      "exclusivity_issue_count" =>
        sum_report_count(
          reports,
          &timeline_integrity_report_exclusivity_issue_count(&1, callbacks)
        ),
      "timeline_integrity_status_counts" =>
        reports
        |> Enum.map(&timeline_integrity_report_status_counts(&1, callbacks))
        |> merge_count_maps(),
      "timeline_integrity_issue_type_counts" =>
        reports
        |> Enum.map(&timeline_integrity_report_issue_type_counts(&1, callbacks))
        |> merge_count_maps(),
      "required_operator_action_counts" =>
        reports
        |> Enum.map(&timeline_integrity_report_required_operator_action_counts(&1, callbacks))
        |> merge_count_maps(),
      "operator_action_reason_counts" =>
        reports
        |> Enum.map(&timeline_integrity_report_operator_action_reason_counts(&1, callbacks))
        |> merge_count_maps(),
      "review_activity_id_counts" =>
        reports
        |> Enum.map(&timeline_integrity_report_review_activity_id_counts(&1, callbacks))
        |> merge_count_maps(),
      "review_timeline_id_counts" =>
        reports
        |> Enum.map(&timeline_integrity_report_review_timeline_id_counts(&1, callbacks))
        |> merge_count_maps(),
      "missing_dependency_activity_id_counts" =>
        reports
        |> Enum.map(
          &timeline_integrity_report_id_counts(
            &1,
            ["missing_dependency_activity_ids", "missing_dependency_activity_id"],
            callbacks
          )
        )
        |> merge_count_maps(),
      "missing_dependency_timeline_id_counts" =>
        reports
        |> Enum.map(
          &timeline_integrity_report_id_counts(
            &1,
            ["missing_dependency_timeline_ids", "missing_dependency_timeline_id"],
            callbacks
          )
        )
        |> merge_count_maps(),
      "self_dependency_activity_id_counts" =>
        reports
        |> Enum.map(
          &timeline_integrity_report_id_counts(
            &1,
            ["self_dependency_activity_ids", "self_dependency_activity_id"],
            callbacks
          )
        )
        |> merge_count_maps(),
      "self_dependency_timeline_id_counts" =>
        reports
        |> Enum.map(
          &timeline_integrity_report_id_counts(
            &1,
            ["self_dependency_timeline_ids", "self_dependency_timeline_id"],
            callbacks
          )
        )
        |> merge_count_maps(),
      "dependency_cycle_activity_id_counts" =>
        reports
        |> Enum.map(
          &timeline_integrity_report_id_counts(
            &1,
            ["dependency_cycle_activity_ids", "dependency_cycle_activity_id"],
            callbacks
          )
        )
        |> merge_count_maps(),
      "dependency_cycle_timeline_id_counts" =>
        reports
        |> Enum.map(
          &timeline_integrity_report_id_counts(
            &1,
            ["dependency_cycle_timeline_ids", "dependency_cycle_timeline_id"],
            callbacks
          )
        )
        |> merge_count_maps(),
      "dependency_order_violation_activity_id_counts" =>
        reports
        |> Enum.map(
          &timeline_integrity_report_id_counts(
            &1,
            ["dependency_order_violation_activity_ids", "dependency_order_violation_activity_id"],
            callbacks
          )
        )
        |> merge_count_maps(),
      "dependency_order_violation_timeline_id_counts" =>
        reports
        |> Enum.map(
          &timeline_integrity_report_id_counts(
            &1,
            ["dependency_order_violation_timeline_ids", "dependency_order_violation_timeline_id"],
            callbacks
          )
        )
        |> merge_count_maps(),
      "exclusivity_violation_activity_id_counts" =>
        reports
        |> Enum.map(
          &timeline_integrity_report_id_counts(
            &1,
            ["exclusivity_violation_activity_ids", "exclusivity_violation_activity_id"],
            callbacks
          )
        )
        |> merge_count_maps(),
      "exclusivity_violation_timeline_id_counts" =>
        reports
        |> Enum.map(
          &timeline_integrity_report_id_counts(
            &1,
            ["exclusivity_violation_timeline_ids", "exclusivity_violation_timeline_id"],
            callbacks
          )
        )
        |> merge_count_maps(),
      "exclusivity_violation_group_counts" =>
        reports
        |> Enum.map(
          &timeline_integrity_report_id_counts(
            &1,
            ["exclusivity_violation_groups", "exclusivity_violation_group"],
            callbacks
          )
        )
        |> merge_count_maps(),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_timeline_integrity_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(callbacks, :source_timeline_integrity_trust_boundaries).(reports)
    }
    |> compact_map()
  end

  defp timeline_diff_input_summary_contract(reports) do
    reports
    |> Enum.map(fn report ->
      Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")
    end)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> case do
      [contract] -> contract
      [] -> nil
      _contracts -> "timeline_diff_report.v1"
    end
  end

  defp timeline_integrity_report_row_count(report, callbacks) do
    case timeline_integrity_report_rows(report, callbacks) do
      [] -> numeric_report_count(report, "row_count")
      rows -> length(rows)
    end
  end

  defp timeline_integrity_report_issue_count(report, callbacks) do
    case timeline_integrity_report_issue_type_values(report, callbacks) do
      [] -> numeric_report_count(report, "timeline_integrity_issue_count")
      issue_types -> length(issue_types)
    end
  end

  defp timeline_integrity_report_review_count(report, callbacks) do
    case timeline_integrity_report_rows(report, callbacks) do
      [] ->
        numeric_report_count(report, "timeline_integrity_review_count")

      rows ->
        Enum.count(rows, fn row ->
          normalized_timeline_diff_token(callbacks, Map.get(row, "timeline_integrity_status")) ==
            "review_required" or
            Map.get(row, "required_operator_action") not in [nil, "", "none"]
        end)
    end
  end

  defp timeline_integrity_report_dependency_issue_count(report, callbacks) do
    report
    |> timeline_integrity_report_issue_type_values(callbacks)
    |> Enum.count(&timeline_dependency_integrity_issue_type?(&1, callbacks))
    |> case do
      0 -> numeric_report_count(report, "dependency_issue_count")
      count -> count
    end
  end

  defp timeline_integrity_report_exclusivity_issue_count(report, callbacks) do
    report
    |> timeline_integrity_report_issue_type_values(callbacks)
    |> Enum.count(&timeline_exclusivity_integrity_issue_type?(&1, callbacks))
    |> case do
      0 -> numeric_report_count(report, "exclusivity_issue_count")
      count -> count
    end
  end

  defp timeline_integrity_report_status_counts(report, callbacks) do
    timeline_integrity_report_row_counts(
      report,
      "timeline_integrity_status_counts",
      "timeline_integrity_status",
      callbacks
    )
  end

  defp timeline_integrity_report_required_operator_action_counts(report, callbacks) do
    timeline_integrity_report_row_counts(
      report,
      "required_operator_action_counts",
      "required_operator_action",
      callbacks
    )
  end

  defp timeline_integrity_report_operator_action_reason_counts(report, callbacks) do
    timeline_integrity_report_row_counts(
      report,
      "operator_action_reason_counts",
      "operator_action_reason",
      callbacks
    )
  end

  defp timeline_integrity_report_issue_type_counts(report, callbacks) do
    case timeline_integrity_report_issue_type_values(report, callbacks) do
      [] -> Map.get(report, "timeline_integrity_issue_type_counts")
      issue_types -> count_source_report_values(issue_types)
    end
  end

  defp timeline_integrity_report_review_activity_id_counts(report, callbacks) do
    timeline_integrity_report_row_id_counts(
      report,
      ["review_activity_ids", "activity_id"],
      callbacks
    )
  end

  defp timeline_integrity_report_review_timeline_id_counts(report, callbacks) do
    timeline_integrity_report_row_id_counts(
      report,
      ["review_timeline_ids", "timeline_id"],
      callbacks
    )
  end

  defp timeline_integrity_report_row_counts(report, top_level_field, row_field, callbacks) do
    case timeline_integrity_report_rows(report, callbacks) do
      [] ->
        Map.get(report, top_level_field)

      rows ->
        rows
        |> Enum.map(&Map.get(&1, row_field))
        |> count_source_report_values()
    end
  end

  defp timeline_integrity_report_id_counts(report, fields, callbacks) do
    report_values =
      fields
      |> Enum.flat_map(&timeline_integrity_report_values(report, &1))

    row_values =
      report
      |> timeline_integrity_report_rows(callbacks)
      |> Enum.flat_map(fn row ->
        Enum.flat_map(fields, &timeline_integrity_report_values(row, &1))
      end)

    if(row_values == [], do: report_values, else: row_values)
    |> count_source_report_values()
  end

  defp timeline_integrity_report_row_id_counts(report, fields, callbacks) do
    report_values =
      fields
      |> Enum.flat_map(&timeline_integrity_report_values(report, &1))
      |> Enum.uniq()

    row_values =
      report
      |> timeline_integrity_report_rows(callbacks)
      |> Enum.flat_map(fn row ->
        fields
        |> Enum.flat_map(&timeline_integrity_report_values(row, &1))
        |> Enum.uniq()
      end)

    if(row_values == [], do: report_values, else: row_values)
    |> count_source_report_values()
  end

  defp timeline_integrity_report_issue_type_values(report, callbacks) do
    report
    |> timeline_integrity_report_rows(callbacks)
    |> Enum.flat_map(fn row ->
      row
      |> Map.get("timeline_integrity_issues", [])
      |> case do
        issues when is_list(issues) and issues != [] ->
          issues
          |> Enum.map(&stringify_keys(callbacks, &1))
          |> Enum.flat_map(&timeline_integrity_report_values(&1, "type"))

        _issues ->
          timeline_integrity_report_values(row, "timeline_integrity_issue_types")
      end
    end)
  end

  defp timeline_integrity_report_values(%{} = source, field) do
    case Map.get(source, field) do
      values when is_list(values) -> values
      value when value in [nil, ""] -> []
      value -> [value]
    end
  end

  defp timeline_integrity_report_values(_source, _field), do: []

  defp timeline_integrity_report_rows(report, callbacks) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys(callbacks, &1))
  end

  defp timeline_dependency_integrity_issue_type?(issue_type, callbacks) do
    normalized_timeline_diff_token(callbacks, issue_type) in [
      "missing_dependency_activity",
      "missing_dependency_timeline",
      "self_dependency_activity",
      "self_dependency_timeline",
      "duplicate_dependency_activity",
      "duplicate_dependency_timeline",
      "dependency_cycle",
      "dependency_order_violation"
    ]
  end

  defp timeline_exclusivity_integrity_issue_type?(issue_type, callbacks) do
    normalized_timeline_diff_token(callbacks, issue_type) in [
      "duplicate_exclusivity_activity",
      "duplicate_exclusivity_timeline",
      "exclusivity_overlap",
      "exclusivity_group_overlap"
    ]
  end

  defp trust_boundary_status(reports, trust_boundaries) when is_function(trust_boundaries, 1) do
    case trust_boundaries.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp stringify_keys(callbacks, value), do: callback!(callbacks, :stringify_keys).(value)

  defp normalized_timeline_diff_token(callbacks, value),
    do: callback!(callbacks, :normalized_timeline_diff_token).(value)

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
