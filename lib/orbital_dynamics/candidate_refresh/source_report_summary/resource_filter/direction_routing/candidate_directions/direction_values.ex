defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting.CandidateDirections.DirectionValues do
  @moduledoc false

  alias __MODULE__.DirectionAliases

  def from_row(row) do
    row
    |> source_values()
    |> Enum.map(&normalize/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  def normalize(direction), do: DirectionAliases.normalize(direction)

  defp source_values(row) do
    [
      row["direction"],
      row["type"],
      row["activity_type"],
      get_in(row, ["activity_context", "direction"]),
      get_in(row, ["activity_context", "type"]),
      get_in(row, ["activity_context", "activity_type"]),
      get_in(row, ["source_activity_context", "direction"]),
      get_in(row, ["source_activity_context", "type"]),
      get_in(row, ["source_activity_context", "activity_type"]),
      get_in(row, ["source_contact_candidate", "direction"]),
      get_in(row, ["source_contact_candidate", "type"]),
      get_in(row, ["source_contact_candidate", "activity_type"]),
      get_in(row, ["contact_candidate", "direction"]),
      get_in(row, ["contact_candidate", "type"]),
      get_in(row, ["contact_candidate", "activity_type"])
    ]
  end
end
