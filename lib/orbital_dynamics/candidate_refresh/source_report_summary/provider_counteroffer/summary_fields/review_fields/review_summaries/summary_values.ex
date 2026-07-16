defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.ReviewFields.ReviewSummaries.SummaryValues do
  @moduledoc false

  alias __MODULE__.DirectValues
  alias __MODULE__.RowFallbacks

  def reports(reports) do
    Enum.filter(reports, fn report ->
      Map.get(report, "source_summary_model") ==
        "artifact_only_provider_counteroffer_review_summary"
    end)
  end

  def single_value_counts(summaries, value_field) do
    DirectValues.single_value_counts(summaries, value_field)
  end

  def counts_with_row_fallback(summaries, counts_field, row_field) do
    RowFallbacks.counts(summaries, counts_field, row_field)
  end

  def count_map(summaries, field) do
    DirectValues.count_map(summaries, field)
  end

  def string_list_map_with_row_fallback(summaries, ids_field, row_field) do
    RowFallbacks.string_list_map(summaries, ids_field, row_field)
  end

  def sorted_string_list(summaries, field) do
    DirectValues.sorted_string_list(summaries, field)
  end
end
