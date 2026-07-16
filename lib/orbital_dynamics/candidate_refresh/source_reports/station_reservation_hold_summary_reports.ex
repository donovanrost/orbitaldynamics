defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryReports do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRows

  def hold_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    summary["model"] == "artifact_only_station_reservation_hold_summary" and
      is_list(summary["review_rows"])
  end

  def hold_summary?(_summary), do: false

  def report_from_hold_summary(%{} = summary) do
    summary = stringify_keys(summary)

    %{
      "schema_contract" => "station_reservation_report.v1",
      "model" => "preserved_station_reservation_hold_summary",
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "trust_boundary" => Map.get(summary, "trust_boundary"),
      "assumptions" => summary["assumptions"]
    }
    |> Map.merge(StationReservationHoldSummaryRows.report_fields(summary))
    |> maybe_put("provenance", summary["provenance"])
    |> compact_map()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp stringify_keys(value), do: StationReservationHoldSummaryEncoding.stringify_keys(value)
end
