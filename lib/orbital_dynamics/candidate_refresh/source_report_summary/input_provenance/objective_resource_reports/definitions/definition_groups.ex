defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ObjectiveResourceReports.Definitions.DefinitionGroups do
  @moduledoc false

  alias __MODULE__.{ObjectiveDefinitions, ResourceDefinitions}

  def objective_definitions do
    ObjectiveDefinitions.definitions()
  end

  def resource_definitions do
    ResourceDefinitions.definitions()
  end
end
