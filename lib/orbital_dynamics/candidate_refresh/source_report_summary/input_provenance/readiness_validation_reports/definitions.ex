defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ReadinessValidationReports.Definitions do
  @moduledoc false

  alias __MODULE__.DefinitionGroups

  def definitions do
    DefinitionGroups.freshness_definitions() ++
      DefinitionGroups.readiness_definitions() ++ DefinitionGroups.validation_definitions()
  end
end
