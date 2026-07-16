defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ContactNetworkReports.Definitions do
  @moduledoc false

  alias __MODULE__.DefinitionGroups

  def definitions do
    DefinitionGroups.station_definitions() ++ DefinitionGroups.contact_definitions()
  end
end
