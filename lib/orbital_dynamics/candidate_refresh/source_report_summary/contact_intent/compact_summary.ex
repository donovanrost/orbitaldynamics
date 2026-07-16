defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.{
    SummaryFields,
    SummaryNormalization
  }

  def input_summary([]), do: nil

  def input_summary(sources) do
    summaries =
      Enum.map(sources, fn {_path, summary} ->
        SummaryNormalization.normalize(summary)
      end)

    SummaryFields.from_compact_sources(sources, summaries)
  end

  def merge_input_summaries(summaries) do
    summaries = Enum.reject(summaries, &is_nil/1)

    case summaries do
      [] ->
        nil

      summaries ->
        SummaryFields.from_input_summaries(summaries)
    end
  end
end
