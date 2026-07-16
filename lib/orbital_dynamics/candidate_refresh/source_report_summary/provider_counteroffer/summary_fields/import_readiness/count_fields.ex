defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.ImportReadiness.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.ImportReadiness.Summaries

  def fields(summaries) do
    %{
      "import_readiness_summary_count" => length(summaries),
      "import_readiness_status_counts" =>
        Summaries.counts_with_single_value_fallback(
          summaries,
          "import_readiness_status_counts",
          "import_readiness_status"
        ),
      "import_classification_counts" =>
        Summaries.counts_with_single_value_fallback(
          summaries,
          "import_classification_counts",
          "import_classification"
        ),
      "provider_counteroffer_import_status_counts" =>
        Summaries.count_map(summaries, "provider_counteroffer_import_status_counts"),
      "counteroffer_lock_deadline_status_counts" =>
        Summaries.counts_with_row_fallback(
          summaries,
          "counteroffer_lock_deadline_status_counts",
          "provider_counteroffer_lock_deadline_status"
        )
    }
  end
end
