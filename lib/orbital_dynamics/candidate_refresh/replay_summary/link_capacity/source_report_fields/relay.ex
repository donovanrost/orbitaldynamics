defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Relay do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Relay.Rows,
    only: [
      explicit_count_map: 2,
      explicit_string_list: 2,
      explicit_string_list_map: 2,
      numeric_value: 1,
      relay_data_path_summary_source?: 1,
      route_ids_by_field: 2,
      row_ids: 2,
      rows_for_summary: 1,
      summary_integer: 2
    ]

  def relay_route_count(report) do
    if relay_data_path_summary_source?(report) do
      summary_integer(report, "relay_route_count")
    else
      report
      |> rows_for_summary()
      |> Enum.count(fn row ->
        case numeric_value(Map.get(row, "relay_hop_count")) do
          hop_count when is_number(hop_count) -> hop_count > 0
          _hop_count -> false
        end
      end)
    end
  end

  def direct_downlink_route_count(report) do
    if relay_data_path_summary_source?(report) do
      summary_integer(report, "direct_downlink_route_count")
    else
      report
      |> rows_for_summary()
      |> Enum.count(fn row ->
        case numeric_value(Map.get(row, "relay_hop_count")) do
          hop_count when is_number(hop_count) -> hop_count == 0
          _hop_count -> false
        end
      end)
    end
  end

  def relay_route_ids(report) do
    explicit_string_list(report, "route_ids") ||
      row_ids(report, ["route_id"])
  end

  def source_spacecraft_ids(report) do
    explicit_string_list(report, "source_spacecraft_ids") ||
      row_ids(report, ["source_spacecraft_id"])
  end

  def relay_spacecraft_ids(report) do
    explicit_string_list(report, "relay_spacecraft_ids") ||
      row_ids(report, ["relay_chain_spacecraft_ids", "relay_spacecraft_id"])
  end

  def ground_downlink_contact_ids(report) do
    explicit_string_list(report, "ground_downlink_contact_ids") ||
      row_ids(report, ["ground_downlink_contact_id"])
  end

  def relay_custody_status_counts(report) do
    explicit_count_map(report, "custody_status_counts") ||
      report
      |> rows_for_summary()
      |> Counts.normalized_rows("custody_status")
  end

  def relay_latency_status_counts(report) do
    explicit_count_map(report, "latency_status_counts") ||
      report
      |> rows_for_summary()
      |> Counts.normalized_rows("latency_status")
  end

  def relay_risk_status_counts(report) do
    explicit_count_map(report, "risk_status_counts") ||
      report
      |> rows_for_summary()
      |> Counts.normalized_rows("risk_status")
  end

  def relay_route_ids_by_custody_status(report) do
    explicit_string_list_map(report, "route_ids_by_custody_status") ||
      route_ids_by_field(report, "custody_status")
  end

  def relay_route_ids_by_latency_status(report) do
    explicit_string_list_map(report, "route_ids_by_latency_status") ||
      route_ids_by_field(report, "latency_status")
  end

  def relay_route_ids_by_risk_status(report) do
    explicit_string_list_map(report, "route_ids_by_risk_status") ||
      route_ids_by_field(report, "risk_status")
  end

  def relay_route_ids_by_ground_station(report) do
    explicit_string_list_map(report, "route_ids_by_ground_station_id") ||
      route_ids_by_field(report, "ground_station_id")
  end
end
