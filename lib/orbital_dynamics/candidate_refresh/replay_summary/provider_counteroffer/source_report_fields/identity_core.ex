defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer.SourceReportFields.IdentityCore do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_provider_counteroffer_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_provider_counteroffer_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_provider_counteroffer_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_provider_counteroffer_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_provider_counteroffer_reviewable_count" =>
        source_report_family_count(source_reports, "reviewable_count"),
      "source_report_provider_counteroffer_cost_delta_count" =>
        source_report_family_count(source_reports, "counteroffer_cost_delta_count"),
      "source_report_provider_counteroffer_cost_delta_total" =>
        source_report_family_numeric_sum(source_reports, "counteroffer_cost_delta_total"),
      "source_report_provider_counteroffer_timing_shift_count" =>
        source_report_family_count(source_reports, "counteroffer_timing_shift_count"),
      "source_report_provider_counteroffer_start_delta_count" =>
        source_report_family_count(source_reports, "counteroffer_start_delta_count"),
      "source_report_provider_counteroffer_end_delta_count" =>
        source_report_family_count(source_reports, "counteroffer_end_delta_count"),
      "source_report_provider_counteroffer_duration_delta_count" =>
        source_report_family_count(source_reports, "counteroffer_duration_delta_count"),
      "source_report_provider_counteroffer_lock_deadline_count" =>
        source_report_family_count(source_reports, "counteroffer_lock_deadline_count"),
      "source_report_provider_counteroffer_earliest_lock_deadline_s" =>
        source_report_family_numeric_min(
          source_reports,
          "earliest_counteroffer_lock_deadline_s"
        ),
      "source_report_provider_counteroffer_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "counteroffer_status_counts"),
      "source_report_provider_counteroffer_required_operator_action_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "required_operator_action_counts"
        )
    }
  end
end
