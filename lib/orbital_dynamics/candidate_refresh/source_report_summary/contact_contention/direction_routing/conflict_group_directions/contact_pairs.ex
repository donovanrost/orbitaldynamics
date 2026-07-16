defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs do
  @moduledoc false

  alias __MODULE__.Direction
  alias __MODULE__.GroupPairs

  def direction_contact_pairs(report) do
    report
    |> Map.get("conflict_groups", [])
    |> Enum.flat_map(&GroupPairs.group_pairs/1)
  end

  def normalize_direction(direction), do: Direction.normalize(direction)
end
