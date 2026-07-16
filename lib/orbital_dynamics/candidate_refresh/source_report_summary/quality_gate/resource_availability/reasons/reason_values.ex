defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.ReasonValues do
  @moduledoc false

  alias __MODULE__.AllowedReasons
  alias __MODULE__.ReasonIds

  def fields(reports) do
    %{
      "resource_availability_reason_ids" =>
        reason_ids(reports, &ReasonIds.resource_availability_reason_ids/1),
      "station_availability_reason_ids" =>
        reason_ids(reports, &ReasonIds.station_availability_reason_ids/1),
      "unavailable_resource_reason_ids" =>
        reason_ids(reports, &ReasonIds.unavailable_resource_reason_ids/1)
    }
  end

  def station_reason_count_map(%{} = counts) do
    AllowedReasons.station_reason_count_map(counts)
  end

  def station_reason_count_map(_counts), do: %{}

  defp reason_ids(reports, extractor) do
    reports
    |> Enum.flat_map(extractor)
    |> ReasonIds.sorted_non_empty_values()
  end
end
