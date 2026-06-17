defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def report_input_summary([], _callbacks), do: nil

  def report_input_summary(sources, callbacks) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" =>
        callback!(callbacks, :timeline_transition_application_input_summary_contract).(reports),
      "count" => length(sources),
      "row_count" =>
        count_sum(reports, callbacks, :timeline_transition_application_report_source_row_count),
      "application_count" =>
        count_sum(reports, callbacks, :timeline_transition_application_report_application_count),
      "selected_activity_count" =>
        count_sum(
          reports,
          callbacks,
          :timeline_transition_application_report_selected_activity_count
        ),
      "selected_timeline_integrity_review_count" =>
        count_sum(
          reports,
          callbacks,
          :timeline_transition_application_report_selected_integrity_review_count
        ),
      "selected_timeline_integrity_issue_count" =>
        count_sum(
          reports,
          callbacks,
          :timeline_transition_application_report_selected_integrity_issue_count
        ),
      "selected_timeline_integrity_issue_type_counts" =>
        count_map_merge(
          reports,
          callbacks,
          :timeline_transition_application_report_selected_integrity_issue_type_counts
        ),
      "selected_activity_id_counts" =>
        count_map_merge(
          reports,
          callbacks,
          :timeline_transition_application_report_selected_activity_id_counts
        ),
      "review_activity_id_counts" =>
        count_map_merge(
          reports,
          callbacks,
          :timeline_transition_application_report_review_activity_id_counts
        ),
      "review_required_count" =>
        count_sum(
          reports,
          callbacks,
          :timeline_transition_application_report_review_required_count
        ),
      "preserved_source_count" =>
        count_sum(
          reports,
          callbacks,
          :timeline_transition_application_report_preserved_source_count
        ),
      "recorded_replacement_count" =>
        count_sum(
          reports,
          callbacks,
          :timeline_transition_application_report_recorded_replacement_count
        ),
      "withheld_review_count" =>
        count_sum(
          reports,
          callbacks,
          :timeline_transition_application_report_withheld_review_count
        ),
      "duplicate_timeline_identity_count" =>
        count_sum(
          reports,
          callbacks,
          :timeline_transition_application_report_duplicate_timeline_identity_count
        ),
      "duplicate_source_timeline_identity_count" =>
        count_sum(
          reports,
          callbacks,
          :timeline_transition_application_report_duplicate_source_timeline_identity_count
        ),
      "duplicate_replacement_timeline_identity_count" =>
        count_sum(
          reports,
          callbacks,
          :timeline_transition_application_report_duplicate_replacement_timeline_identity_count
        ),
      "application_status_counts" =>
        count_map_merge(
          reports,
          callbacks,
          :timeline_transition_application_report_application_status_counts
        ),
      "transition_decision_counts" =>
        count_map_merge(
          reports,
          callbacks,
          :timeline_transition_application_report_transition_decision_counts
        ),
      "required_operator_action_counts" =>
        count_map_merge(
          reports,
          callbacks,
          :timeline_transition_application_report_required_operator_action_counts
        ),
      "duplicate_timeline_identity_scope_counts" =>
        count_map_merge(
          reports,
          callbacks,
          :timeline_transition_application_report_duplicate_identity_scope_counts
        ),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_timeline_transition_application_report_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(
          callbacks,
          :source_timeline_transition_application_report_trust_boundaries
        ).(reports)
    }
    |> compact_map()
  end

  defp count_sum(reports, callbacks, key),
    do: sum_report_count(reports, callback!(callbacks, key))

  defp count_map_merge(reports, callbacks, key) do
    extractor = callback!(callbacks, key)

    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end

  defp trust_boundary_status(reports, trust_boundaries) when is_function(trust_boundaries, 1) do
    case trust_boundaries.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
