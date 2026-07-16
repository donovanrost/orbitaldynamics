defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.ReviewFields.ReviewSummaries do
  @moduledoc false

  alias __MODULE__.SummaryValues

  defdelegate reports(reports), to: SummaryValues
  defdelegate single_value_counts(summaries, value_field), to: SummaryValues
  defdelegate counts_with_row_fallback(summaries, counts_field, row_field), to: SummaryValues
  defdelegate count_map(summaries, field), to: SummaryValues

  defdelegate string_list_map_with_row_fallback(summaries, ids_field, row_field),
    to: SummaryValues

  defdelegate sorted_string_list(summaries, field), to: SummaryValues

  def reject_empty_fields(fields) do
    fields
    |> Enum.reject(fn
      {_key, nil} -> true
      {_key, 0} -> true
      {_key, []} -> true
      {_key, map} when map == %{} -> true
      _entry -> false
    end)
    |> Map.new()
  end
end
