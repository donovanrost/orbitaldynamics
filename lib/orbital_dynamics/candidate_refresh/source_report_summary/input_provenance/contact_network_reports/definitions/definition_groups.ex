defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ContactNetworkReports.Definitions.DefinitionGroups do
  @moduledoc false

  alias __MODULE__.{ContactDefinitions, StationDefinitions}

  def station_definitions do
    StationDefinitions.definitions()
  end

  def contact_definitions do
    ContactDefinitions.definitions()
  end
end
