defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.LineageIds.StationCalendarIds.FieldValues.Paths.PathSets.ProviderPaths do
  @moduledoc false

  alias __MODULE__.ProviderEntryPaths
  alias __MODULE__.ProviderIdPaths

  def provider_paths, do: ProviderIdPaths.paths()

  def provider_entry_paths, do: ProviderEntryPaths.paths()
end
