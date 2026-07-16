defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacitySummaryReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewRows

  def link_capacity_summary?(%{} = summary) do
    model = Map.get(summary, "model") || Map.get(summary, :model)
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)

    station_count = Map.get(summary, "station_count") || Map.get(summary, :station_count)

    (is_integer(station_count) or is_float(station_count)) and
      (model == "artifact_only_link_capacity_summary" or
         schema_contract == "link_capacity_summary.v1")
  end

  def link_capacity_summary?(_summary), do: false

  def relay_data_path_summary?(%{} = summary) do
    model = Map.get(summary, "model") || Map.get(summary, :model)
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)
    route_count = Map.get(summary, "route_count") || Map.get(summary, :route_count)

    (is_integer(route_count) or is_float(route_count)) and
      (model == "artifact_only_relay_data_path_summary" or
         schema_contract == "relay_data_path_summary.v1")
  end

  def relay_data_path_summary?(_summary), do: false

  def report_from_summary(%{} = summary) do
    summary = LinkCapacityReviewRows.stringify_keys(summary)

    summary
    |> Map.put("source_summary_schema_contract", Map.get(summary, "schema_contract"))
    |> Map.put("source_summary_model", Map.get(summary, "model"))
    |> Map.put("source_artifact_type", Map.get(summary, "source_artifact_type"))
  end
end
