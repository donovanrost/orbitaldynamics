defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.DirectionFields.Aggregates.MapValues.StationMaps do
  @moduledoc false

  alias __MODULE__.FieldSets
  alias __MODULE__.NestedNumericMaps
  alias __MODULE__.NestedStringListMaps

  def from_compact_summaries(summaries), do: fields(summaries, FieldSets.compact())

  def from_input_summaries(summaries), do: fields(summaries, FieldSets.input())

  defp fields(summaries, station_fields) do
    %{
      required_by_direction_and_station:
        NestedNumericMaps.values(summaries, station_fields.required_by_direction_and_station),
      contact_ids_by_direction_and_station:
        NestedStringListMaps.values(
          summaries,
          station_fields.contact_ids_by_direction_and_station
        ),
      capacity_contact_ids_by_direction_and_station:
        NestedStringListMaps.values(
          summaries,
          station_fields.capacity_contact_ids_by_direction_and_station
        )
    }
  end
end
