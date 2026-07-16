defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.LineageIds.StationCalendarIds.FieldValues do
  @moduledoc false

  alias __MODULE__.Paths

  def entry_values(row) do
    Paths.values(row, Paths.entry_paths())
  end

  def provider_values(row) do
    Paths.values(row, Paths.provider_paths())
  end

  def provider_entry_values(row) do
    Paths.values(row, Paths.provider_entry_paths())
  end
end
