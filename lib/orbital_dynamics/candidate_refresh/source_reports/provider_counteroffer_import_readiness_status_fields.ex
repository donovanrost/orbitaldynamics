defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessStatusFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessReportValues,
    as: Values

  def fields(summary, rows) do
    %{
      "import_readiness_status_counts" => Values.import_readiness_status_counts(summary, rows),
      "import_classification_counts" => Values.import_classification_counts(summary, rows),
      "provider_counteroffer_import_status_counts" =>
        Values.row_counts_or_summary_counts(
          summary,
          rows,
          "provider_counteroffer_import_status_counts",
          "provider_counteroffer_import_status"
        ),
      "counteroffer_lock_deadline_status_counts" =>
        Values.row_counts_or_summary_counts(
          summary,
          rows,
          "counteroffer_lock_deadline_status_counts",
          "provider_counteroffer_lock_deadline_status"
        ),
      "counteroffer_ids_by_import_status" =>
        Values.row_ids_or_summary_ids(
          summary,
          rows,
          "counteroffer_ids_by_import_status",
          "provider_counteroffer_import_status"
        ),
      "counteroffer_ids_by_required_import_action" =>
        Values.row_ids_or_summary_ids(
          summary,
          rows,
          "counteroffer_ids_by_required_import_action",
          "required_operator_action"
        ),
      "counteroffer_ids_by_lock_deadline_status" =>
        Values.row_ids_or_summary_ids(
          summary,
          rows,
          "counteroffer_ids_by_lock_deadline_status",
          "provider_counteroffer_lock_deadline_status"
        ),
      "review_counteroffer_ids" => Values.review_counteroffer_ids(summary, rows),
      "no_import_required_counteroffer_ids" =>
        Values.no_import_required_counteroffer_ids(summary, rows)
    }
  end
end
