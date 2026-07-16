defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary do
  @moduledoc false

  alias __MODULE__.CompactMap
  alias __MODULE__.ReportValues

  def from_definitions(refresh, definitions) do
    ReportValues.from_definitions(refresh, definitions)
  end

  def deduplicated_from_definitions(refresh, definitions) do
    ReportValues.deduplicated_from_definitions(refresh, definitions)
  end

  def from_definition(refresh, %{mode: :deduplicated} = definition) do
    ReportValues.from_definition(refresh, definition)
  end

  def from_definition(refresh, definition) do
    ReportValues.from_definition(refresh, definition)
  end

  def deduplicated_from_definition(refresh, definition) do
    ReportValues.deduplicated_from_definition(refresh, definition)
  end

  def summary(refresh, source, summarizer), do: ReportValues.summary(refresh, source, summarizer)

  def deduplicated_summary(refresh, source, summarizer) do
    ReportValues.deduplicated_summary(refresh, source, summarizer)
  end

  def compact(map) do
    CompactMap.compact(map)
  end
end
