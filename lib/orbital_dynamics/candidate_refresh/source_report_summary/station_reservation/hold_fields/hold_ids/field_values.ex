defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.HoldFields.HoldIds.FieldValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_list_maps: 1,
      merge_string_lists: 1
    ]

  def string_list(reports, field) when is_binary(field) do
    reports
    |> Enum.map(&Map.get(&1, field))
    |> merge_string_lists()
  end

  def string_list_map(reports, field) when is_binary(field) do
    reports
    |> Enum.map(&Map.get(&1, field))
    |> merge_string_list_maps()
  end
end
