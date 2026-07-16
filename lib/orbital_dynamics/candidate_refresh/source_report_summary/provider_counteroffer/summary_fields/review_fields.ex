defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.ReviewFields do
  @moduledoc false

  alias __MODULE__.ReviewSummaries

  def fields(reports) do
    summaries = ReviewSummaries.reports(reports)

    %{
      "review_summary_count" => length(summaries),
      "counteroffer_review_status_counts" =>
        ReviewSummaries.single_value_counts(summaries, "counteroffer_review_status"),
      "counteroffer_negotiation_state_counts" =>
        ReviewSummaries.count_map(summaries, "counteroffer_negotiation_state_counts"),
      "counteroffer_lock_deadline_status_counts" =>
        ReviewSummaries.counts_with_row_fallback(
          summaries,
          "counteroffer_lock_deadline_status_counts",
          "provider_counteroffer_lock_deadline_status"
        ),
      "counteroffer_ids_by_lock_deadline_status" =>
        ReviewSummaries.string_list_map_with_row_fallback(
          summaries,
          "counteroffer_ids_by_lock_deadline_status",
          "provider_counteroffer_lock_deadline_status"
        ),
      "review_counteroffer_ids" =>
        ReviewSummaries.sorted_string_list(summaries, "review_counteroffer_ids")
    }
    |> ReviewSummaries.reject_empty_fields()
  end
end
