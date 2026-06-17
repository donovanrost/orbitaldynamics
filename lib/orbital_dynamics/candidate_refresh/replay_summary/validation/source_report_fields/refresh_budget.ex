defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.SourceReportFields.RefreshBudget do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_refresh_budget_input_candidate_count" =>
        source_report_family_count(
          source_reports,
          "refresh_budget_report",
          "input_candidate_count"
        ),
      "source_report_refresh_budget_contract" =>
        source_report_family_field(source_reports, "refresh_budget_report", "contract"),
      "source_report_refresh_budget_count" =>
        source_report_family_identity_count(source_reports, "refresh_budget_report", "count"),
      "source_report_refresh_budget_row_count" =>
        source_report_family_identity_count(source_reports, "refresh_budget_report", "row_count"),
      "source_report_refresh_budget_paths" =>
        source_report_family_identity_field(source_reports, "refresh_budget_report", "paths"),
      "source_report_refresh_budget_kept_candidate_count" =>
        source_report_family_count(
          source_reports,
          "refresh_budget_report",
          "kept_candidate_count"
        ),
      "source_report_refresh_budget_dropped_candidate_count" =>
        source_report_family_count(
          source_reports,
          "refresh_budget_report",
          "dropped_candidate_count"
        ),
      "source_report_refresh_budget_invalid_candidate_limit_policy_count" =>
        source_report_family_count(
          source_reports,
          "refresh_budget_report",
          "invalid_candidate_limit_policy_count"
        ),
      "source_report_refresh_budget_invalid_candidate_limit_policy_reason_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "refresh_budget_report",
          "invalid_candidate_limit_policy_reason_counts"
        ),
      "source_report_refresh_budget_kept_candidate_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "refresh_budget_report",
          "kept_candidate_ids"
        ),
      "source_report_refresh_budget_dropped_candidate_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "refresh_budget_report",
          "dropped_candidate_ids"
        )
    }
  end
end
