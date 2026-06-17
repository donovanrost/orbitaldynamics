defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer.SourceReportFields.ReviewImport do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_provider_counteroffer_review_summary_count" =>
        source_report_family_count(source_reports, "review_summary_count"),
      "source_report_provider_counteroffer_review_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "counteroffer_review_status_counts"
        ),
      "source_report_provider_counteroffer_negotiation_state_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "counteroffer_negotiation_state_counts"
        ),
      "source_report_provider_counteroffer_import_readiness_summary_count" =>
        source_report_family_count(source_reports, "import_readiness_summary_count"),
      "source_report_provider_counteroffer_import_readiness_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "import_readiness_status_counts"),
      "source_report_provider_counteroffer_import_classification_counts" =>
        source_report_family_merge_count_maps(source_reports, "import_classification_counts"),
      "source_report_provider_counteroffer_import_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "provider_counteroffer_import_status_counts"
        ),
      "source_report_provider_counteroffer_lock_deadline_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "counteroffer_lock_deadline_status_counts"
        ),
      "source_report_provider_counteroffer_counteroffer_ids_by_import_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "counteroffer_ids_by_import_status"
        ),
      "source_report_provider_counteroffer_counteroffer_ids_by_required_import_action" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "counteroffer_ids_by_required_import_action"
        ),
      "source_report_provider_counteroffer_counteroffer_ids_by_lock_deadline_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "counteroffer_ids_by_lock_deadline_status"
        ),
      "source_report_provider_counteroffer_review_counteroffer_ids" =>
        source_report_family_merge_string_lists(source_reports, "review_counteroffer_ids"),
      "source_report_provider_counteroffer_no_import_required_counteroffer_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "no_import_required_counteroffer_ids"
        )
    }
  end
end
