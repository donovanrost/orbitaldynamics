defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.RelayFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.RelayFields.AggregateValues
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.RelayFields.StatusFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Relay,
    as: RelayReport

  def fields(reports) do
    %{
      "relay_route_count" =>
        reports
        |> AggregateValues.non_zero_count_sum(&RelayReport.relay_route_count/1),
      "direct_downlink_route_count" =>
        reports
        |> AggregateValues.non_zero_count_sum(&RelayReport.direct_downlink_route_count/1),
      "relay_route_ids" => AggregateValues.sorted_list(reports, &RelayReport.relay_route_ids/1),
      "source_spacecraft_ids" =>
        AggregateValues.sorted_list(reports, &RelayReport.source_spacecraft_ids/1),
      "relay_spacecraft_ids" =>
        AggregateValues.sorted_list(reports, &RelayReport.relay_spacecraft_ids/1),
      "ground_downlink_contact_ids" =>
        AggregateValues.sorted_list(reports, &RelayReport.ground_downlink_contact_ids/1),
      "relay_route_ids_by_ground_station" =>
        AggregateValues.string_list_map_merge(
          reports,
          &RelayReport.relay_route_ids_by_ground_station/1
        )
    }
    |> Map.merge(StatusFields.fields(reports))
  end
end
