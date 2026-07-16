defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.DirectionFields.Aggregates.MapValues.DirectionMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_numeric_maps: 1,
      merge_string_list_maps: 1
    ]

  def values(summaries) do
    %{
      capacity_contact_ids_by_direction:
        summaries
        |> Enum.map(&Map.get(&1, "capacity_pack_contact_ids_by_direction"))
        |> merge_string_list_maps(),
      required_by_direction:
        summaries
        |> Enum.map(&Map.get(&1, "capacity_pack_required_capacity_fraction_by_direction"))
        |> merge_numeric_maps()
    }
  end
end
