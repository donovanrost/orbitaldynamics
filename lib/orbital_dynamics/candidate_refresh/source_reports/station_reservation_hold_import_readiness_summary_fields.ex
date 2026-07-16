defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldImportReadinessSummaryFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def from_summary(summary, affected_rows, provider_rows) do
    %{
      "schema_contract" => "station_reservation_report.v1",
      "model" => "preserved_station_reservation_hold_import_readiness_summary",
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "affected_contacts" => affected_rows,
      "provider_calendar_contention_groups" => provider_rows,
      "reservation_hold_count" => summary["reservation_hold_count"],
      "import_readiness_status" => summary["import_readiness_status"],
      "import_classification" => summary["import_classification"],
      "ready_for_import_count" => summary["ready_for_import_count"],
      "review_required_before_import_count" => summary["review_required_before_import_count"],
      "no_import_required_count" => summary["no_import_required_count"],
      "reservation_hold_import_status_counts" => summary["reservation_hold_import_status_counts"],
      "reservation_hold_status_counts" => summary["reservation_hold_status_counts"],
      "reservation_hold_expiration_status_counts" =>
        summary["reservation_hold_expiration_status_counts"],
      "required_import_action_counts" => summary["required_import_action_counts"],
      "reservation_hold_ids" => summary["reservation_hold_ids"],
      "reservation_hold_ids_by_import_status" => summary["reservation_hold_ids_by_import_status"],
      "reservation_hold_ids_by_expiration_status" =>
        summary["reservation_hold_ids_by_expiration_status"],
      "reservation_hold_ids_by_status" => summary["reservation_hold_ids_by_status"],
      "reservation_hold_ids_by_reserved_by" => summary["reservation_hold_ids_by_reserved_by"],
      "reservation_hold_ids_by_required_import_action" =>
        summary["reservation_hold_ids_by_required_import_action"],
      "reservation_hold_ids_by_direction" => summary["reservation_hold_ids_by_direction"],
      "reservation_hold_contact_ids_by_import_status" =>
        summary["reservation_hold_contact_ids_by_import_status"],
      "reservation_hold_contact_ids_by_expiration_status" =>
        summary["reservation_hold_contact_ids_by_expiration_status"],
      "reservation_hold_contact_ids_by_direction" =>
        summary["reservation_hold_contact_ids_by_direction"],
      "review_contact_ids" => summary["review_contact_ids"],
      "assumptions" => summary["assumptions"]
    }
    |> maybe_put("provenance", summary["provenance"])
    |> compact_map()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
