defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SourceContactValues do
  @moduledoc false

  def source_contact_values(row) do
    source_contact_fields(row)
    |> List.flatten()
  end

  def source_contact_maps(row, normalization) do
    row
    |> source_contact_values()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&normalization.stringify_keys/1)
  end

  defp source_contact_fields(row) do
    [
      row["selected_contact_ids"],
      row["selected_contact_id"],
      row["actual_throughput_contact_ids"],
      row["actual_throughput_contact_id"],
      row["actual_completion_contact_ids"],
      row["actual_completion_contact_id"],
      row["required_downlink_contact_ids"],
      row["required_downlink_contact_id"],
      row["contact_ids"],
      row["contact_id"],
      row["selected_contacts"],
      row["selected_contact"],
      row["actual_throughput_contacts"],
      row["actual_throughput_contact"],
      row["actual_completion_contacts"],
      row["actual_completion_contact"],
      row["required_downlink_contacts"],
      row["required_downlink_contact"],
      row["source_contacts"],
      row["source_contact"],
      row["contacts"],
      row["contact"]
    ]
  end
end
