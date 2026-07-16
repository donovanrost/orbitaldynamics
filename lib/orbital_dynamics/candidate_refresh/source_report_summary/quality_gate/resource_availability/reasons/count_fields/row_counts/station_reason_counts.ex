defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.CountFields.RowCounts.StationReasonCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.CountFields.RowCounts.RowMaps

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.ReasonValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  def counts(report) do
    case RowMaps.rows(report) do
      [] ->
        report
        |> Map.get("station_availability_reason_counts", %{})
        |> ReasonValues.station_reason_count_map()

      rows ->
        rows
        |> Enum.map(&station_reason_counts_from_context/1)
        |> merge_count_maps()
    end
  end

  defp station_reason_counts_from_context(%{} = context) do
    station_counts =
      context
      |> Map.get("station_availability_reason_counts")
      |> ReasonValues.station_reason_count_map()

    resource_counts =
      context
      |> Map.get("resource_availability_reason_counts")
      |> ReasonValues.station_reason_count_map()

    if station_counts == %{}, do: resource_counts, else: station_counts
  end
end
