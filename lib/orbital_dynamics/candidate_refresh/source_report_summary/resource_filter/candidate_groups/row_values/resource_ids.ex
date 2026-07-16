defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.RowValues.ResourceIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  def value(row) do
    row
    |> resource_id_value()
    |> StableIds.stable_id_or_nil()
  end

  defp resource_id_value(row) do
    row["resource_id"] ||
      row["resource_summary_id"] ||
      row["resource_name"] ||
      row["battery_id"] ||
      row["storage_resource_id"] ||
      row["energy_resource_id"] ||
      row["resource"]
  end
end
