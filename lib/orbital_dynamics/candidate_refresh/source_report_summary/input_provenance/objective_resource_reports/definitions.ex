defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ObjectiveResourceReports.Definitions do
  @moduledoc false

  alias __MODULE__.DefinitionGroups

  def definitions do
    DefinitionGroups.objective_definitions() ++
      DefinitionGroups.resource_definitions()
  end
end
