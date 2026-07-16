defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.TimelineReports.Definitions.DefinitionGroups do
  @moduledoc false

  alias __MODULE__.{ReportDefinitions, StateDefinitions, SummaryDefinitions}

  def report_definitions do
    ReportDefinitions.definitions()
  end

  def state_definitions do
    StateDefinitions.definitions()
  end

  def summary_definitions do
    SummaryDefinitions.definitions()
  end
end
