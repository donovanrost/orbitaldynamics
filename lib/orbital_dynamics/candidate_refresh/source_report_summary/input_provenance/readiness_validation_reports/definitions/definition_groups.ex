defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ReadinessValidationReports.Definitions.DefinitionGroups do
  @moduledoc false

  alias __MODULE__.{FreshnessDefinitions, ReadinessDefinitions, ValidationDefinitions}

  def freshness_definitions do
    FreshnessDefinitions.definitions()
  end

  def readiness_definitions do
    ReadinessDefinitions.definitions()
  end

  def validation_definitions do
    ValidationDefinitions.definitions()
  end
end
