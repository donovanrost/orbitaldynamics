defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.LineageIds.StationCalendarIds do
  @moduledoc false

  alias __MODULE__.FieldValues
  alias __MODULE__.IdLists

  def entry_ids(row) do
    IdLists.values(row, &FieldValues.entry_values/1)
  end

  def provider_ids(row) do
    IdLists.values(row, &FieldValues.provider_values/1)
  end

  def provider_entry_ids(row) do
    IdLists.values(row, &FieldValues.provider_entry_values/1)
  end
end
