defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.SourceReportFields.Freshness do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_freshness_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "freshness_report", "status_counts"),
      "source_report_freshness_contract" =>
        source_report_family_field(source_reports, "freshness_report", "contract"),
      "source_report_freshness_count" =>
        source_report_family_identity_count(source_reports, "freshness_report", "count"),
      "source_report_freshness_row_count" =>
        source_report_family_identity_count(source_reports, "freshness_report", "row_count"),
      "source_report_freshness_paths" =>
        source_report_family_identity_field(source_reports, "freshness_report", "paths"),
      "source_report_freshness_stale_reason_count" =>
        source_report_family_count(source_reports, "freshness_report", "stale_reason_count"),
      "source_report_freshness_stale_reasons" =>
        source_report_family_merge_string_lists(
          source_reports,
          "freshness_report",
          "stale_reasons"
        ),
      "source_report_freshness_stale_reason_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "freshness_report",
          "stale_reason_counts"
        ),
      "source_report_freshness_unknown_reason_count" =>
        source_report_family_count(source_reports, "freshness_report", "unknown_reason_count"),
      "source_report_freshness_unknown_reasons" =>
        source_report_family_merge_string_lists(
          source_reports,
          "freshness_report",
          "unknown_reasons"
        ),
      "source_report_freshness_unknown_reason_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "freshness_report",
          "unknown_reason_counts"
        )
    }
  end
end
