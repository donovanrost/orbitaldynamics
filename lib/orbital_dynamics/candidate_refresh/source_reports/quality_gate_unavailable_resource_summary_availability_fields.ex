defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateUnavailableResourceSummaryAvailabilityFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusFields

  def fields(%{} = summary, row_ids_by_status) do
    reason_counts =
      [
        summary["unavailable_resource_reason_counts"],
        summary["station_availability_reason_counts"]
      ]
      |> merge_count_maps()

    %{
      row_count:
        QualityGateStatusFields.row_count(
          row_ids_by_status,
          summary["resource_availability_row_count"]
        ),
      reason_counts: reason_counts,
      pressure_count: pressure_count(reason_counts)
    }
  end

  defp pressure_count(reason_counts) do
    reason_counts
    |> Map.values()
    |> Enum.filter(&is_integer/1)
    |> Enum.sum()
  end
end
