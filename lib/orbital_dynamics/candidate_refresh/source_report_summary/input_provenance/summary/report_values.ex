defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary.ReportValues do
  @moduledoc false

  alias __MODULE__.{DefinitionValues, SourceValues}

  def from_definitions(refresh, definitions) do
    DefinitionValues.from_definitions(refresh, definitions, &from_definition/2)
  end

  def deduplicated_from_definitions(refresh, definitions) do
    DefinitionValues.from_definitions(refresh, definitions, &deduplicated_from_definition/2)
  end

  def from_definition(refresh, %{mode: :deduplicated} = definition) do
    deduplicated_from_definition(refresh, definition)
  end

  def from_definition(refresh, definition) do
    SourceValues.summary(refresh, definition.source, definition.summary)
  end

  def deduplicated_from_definition(refresh, definition) do
    SourceValues.deduplicated_summary(
      refresh,
      definition.source,
      definition.summary
    )
  end

  def summary(refresh, source, summarizer) do
    SourceValues.summary(refresh, source, summarizer)
  end

  def deduplicated_summary(refresh, source, summarizer) do
    SourceValues.deduplicated_summary(refresh, source, summarizer)
  end
end
