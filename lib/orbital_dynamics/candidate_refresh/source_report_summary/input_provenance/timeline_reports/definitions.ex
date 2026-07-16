defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.TimelineReports.Definitions do
  @moduledoc false

  alias __MODULE__.DefinitionGroups

  def definitions do
    DefinitionGroups.report_definitions() ++
      DefinitionGroups.state_definitions() ++ DefinitionGroups.summary_definitions()
  end
end
