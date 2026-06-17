defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer.SourceReportFields.PlanImpact do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_provider_counteroffer_plan_impact_summary_count" =>
        source_report_family_count(source_reports, "plan_impact_summary_count"),
      "source_report_provider_counteroffer_plan_impact_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "plan_impact_status_counts"),
      "source_report_provider_counteroffer_affected_station_calendar_entry_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "affected_station_calendar_entry_ids"
        ),
      "source_report_provider_counteroffer_affected_provider_entry_ids" =>
        source_report_family_merge_string_lists(source_reports, "affected_provider_entry_ids"),
      "source_report_provider_counteroffer_impact_counteroffer_ids" =>
        source_report_family_merge_string_lists(source_reports, "impact_counteroffer_ids"),
      "source_report_provider_counteroffer_timing_shift_counteroffer_ids" =>
        source_report_family_merge_string_lists(source_reports, "timing_shift_counteroffer_ids"),
      "source_report_provider_counteroffer_cost_delta_counteroffer_ids" =>
        source_report_family_merge_string_lists(source_reports, "cost_delta_counteroffer_ids")
    }
  end
end
