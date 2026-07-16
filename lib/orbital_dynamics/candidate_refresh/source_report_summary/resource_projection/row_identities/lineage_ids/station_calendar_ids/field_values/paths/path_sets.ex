defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.LineageIds.StationCalendarIds.FieldValues.Paths.PathSets do
  @moduledoc false

  alias __MODULE__.EntryPaths
  alias __MODULE__.ProviderPaths

  def entry_paths, do: EntryPaths.paths()

  def provider_paths, do: ProviderPaths.provider_paths()

  def provider_entry_paths, do: ProviderPaths.provider_entry_paths()
end
