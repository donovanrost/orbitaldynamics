defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationReviewSummaryFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def from_summary(summary, affected_rows, provider_rows) do
    %{
      "schema_contract" => "station_reservation_report.v1",
      "model" => "preserved_station_reservation_review_summary",
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "trust_boundary" => Map.get(summary, "trust_boundary"),
      "affected_contacts" => affected_rows,
      "provider_calendar_contention_groups" => provider_rows,
      "reservation_review_status" => summary["reservation_review_status"],
      "reservation_expiration_count" => summary["reservation_expiration_count"],
      "earliest_reservation_expires_at_s" => summary["earliest_reservation_expires_at_s"],
      "reservation_expiration_status_counts" => summary["reservation_expiration_status_counts"],
      "reservation_ids_by_expiration_status" => summary["reservation_ids_by_expiration_status"],
      "review_reservation_ids" => summary["review_reservation_ids"],
      "assumptions" => summary["assumptions"]
    }
    |> maybe_put("provenance", summary["provenance"])
    |> compact_map()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
