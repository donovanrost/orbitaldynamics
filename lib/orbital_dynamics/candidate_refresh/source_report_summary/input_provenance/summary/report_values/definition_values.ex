defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary.ReportValues.DefinitionValues do
  @moduledoc false

  def from_definitions(refresh, definitions, resolver) when is_function(resolver, 2) do
    Map.new(definitions, fn definition ->
      {definition.key, resolver.(refresh, definition)}
    end)
  end
end
