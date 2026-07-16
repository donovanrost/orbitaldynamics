defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.ImportReadiness.CounterofferIds do
  @moduledoc false

  alias __MODULE__.Aggregates

  def fields(summaries) do
    %{
      "counteroffer_ids_by_import_status" =>
        Aggregates.string_list_map(summaries, "counteroffer_ids_by_import_status"),
      "counteroffer_ids_by_required_import_action" =>
        Aggregates.string_list_map(summaries, "counteroffer_ids_by_required_import_action"),
      "counteroffer_ids_by_lock_deadline_status" =>
        Aggregates.string_list_map_with_row_fallback(
          summaries,
          "counteroffer_ids_by_lock_deadline_status",
          "provider_counteroffer_lock_deadline_status"
        ),
      "review_counteroffer_ids" =>
        Aggregates.sorted_string_list(summaries, "review_counteroffer_ids"),
      "no_import_required_counteroffer_ids" =>
        Aggregates.sorted_string_list(summaries, "no_import_required_counteroffer_ids")
    }
  end
end
