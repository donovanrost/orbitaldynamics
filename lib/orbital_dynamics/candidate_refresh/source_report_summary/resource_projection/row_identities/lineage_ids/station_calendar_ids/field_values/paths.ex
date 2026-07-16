defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.LineageIds.StationCalendarIds.FieldValues.Paths do
  @moduledoc false

  alias __MODULE__.PathSets

  def entry_paths, do: PathSets.entry_paths()

  def provider_paths, do: PathSets.provider_paths()

  def provider_entry_paths, do: PathSets.provider_entry_paths()

  def values(row, paths) do
    Enum.map(paths, &get_in(row, &1))
  end
end
