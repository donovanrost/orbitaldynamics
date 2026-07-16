defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryReviewFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryBaseFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryReviewRows

  def review_fields(%{} = summary) do
    rows = ProviderCounterofferSummaryReviewRows.rows(summary)

    summary
    |> ProviderCounterofferSummaryBaseFields.fields(
      rows,
      "preserved_provider_counteroffer_review_summary"
    )
    |> Map.merge(%{
      "counteroffer_status_counts" =>
        Map.get(summary, "counteroffer_status_counts") ||
          ProviderCounterofferSummaryReviewRows.count_rows(rows, "provider_counteroffer_status"),
      "counteroffer_review_status" => Map.get(summary, "counteroffer_review_status"),
      "counteroffer_review_status_counts" =>
        ProviderCounterofferSummaryReviewRows.review_status_counts(summary),
      "counteroffer_negotiation_state_counts" =>
        Map.get(summary, "counteroffer_negotiation_state_counts") ||
          ProviderCounterofferSummaryReviewRows.count_rows(
            rows,
            "provider_counteroffer_negotiation_state"
          ),
      "required_operator_action_counts" =>
        ProviderCounterofferSummaryReviewRows.count_rows(rows, "required_operator_action"),
      "review_summary_count" => 1,
      "counteroffer_lock_deadline_status_counts" =>
        Map.get(summary, "counteroffer_lock_deadline_status_counts") ||
          ProviderCounterofferSummaryReviewRows.count_rows(
            rows,
            "provider_counteroffer_lock_deadline_status"
          ),
      "counteroffer_ids_by_lock_deadline_status" =>
        ProviderCounterofferSummaryReviewRows.summary_string_list_map(
          summary,
          "counteroffer_ids_by_lock_deadline_status"
        ),
      "review_counteroffer_ids" =>
        ProviderCounterofferSummaryReviewRows.review_counteroffer_ids(summary),
      "assumptions" => Map.get(summary, "assumptions")
    })
  end
end
