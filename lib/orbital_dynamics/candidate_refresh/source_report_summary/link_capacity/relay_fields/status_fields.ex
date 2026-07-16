defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.RelayFields.StatusFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Relay,
    as: RelayReport

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.RelayFields.AggregateValues

  def fields(reports) do
    %{
      "relay_custody_status_counts" =>
        AggregateValues.count_map_merge(reports, &RelayReport.relay_custody_status_counts/1),
      "relay_latency_status_counts" =>
        AggregateValues.count_map_merge(reports, &RelayReport.relay_latency_status_counts/1),
      "relay_risk_status_counts" =>
        AggregateValues.count_map_merge(reports, &RelayReport.relay_risk_status_counts/1),
      "relay_route_ids_by_custody_status" =>
        AggregateValues.string_list_map_merge(
          reports,
          &RelayReport.relay_route_ids_by_custody_status/1
        ),
      "relay_route_ids_by_latency_status" =>
        AggregateValues.string_list_map_merge(
          reports,
          &RelayReport.relay_route_ids_by_latency_status/1
        ),
      "relay_route_ids_by_risk_status" =>
        AggregateValues.string_list_map_merge(
          reports,
          &RelayReport.relay_route_ids_by_risk_status/1
        )
    }
  end
end
