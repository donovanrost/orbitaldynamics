defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.ImportReadiness.Summaries do
  @moduledoc false

  alias __MODULE__.FallbackCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  @source_summary_model "artifact_only_provider_counteroffer_import_readiness_summary"

  def import_readiness(reports) do
    Enum.filter(reports, fn report ->
      Map.get(report, "source_summary_model") == @source_summary_model
    end)
  end

  def counts_with_single_value_fallback(summaries, counts_field, value_field) do
    FallbackCounts.single_value(summaries, counts_field, value_field)
  end

  def counts_with_row_fallback(summaries, counts_field, row_field) do
    FallbackCounts.rows(summaries, counts_field, row_field)
  end

  def count_map(summaries, field) do
    summaries
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_count_maps()
  end
end
