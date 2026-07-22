defmodule OrbitalDynamics.CadenceImport.ManifestBuilder do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.{
    ManifestMapNormalization,
    ManifestRowNormalization,
    ManifestStatistics,
    SourceIdentifierPolicy
  }

  def build(rows, provenance, context, opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)
    schema_version = Keyword.fetch!(opts, :schema_version)
    accepted_statuses = Keyword.fetch!(opts, :accepted_statuses)
    capability = Keyword.fetch!(opts, :capability)
    rows = Enum.map(rows, &ManifestRowNormalization.normalize(&1, accepted_statuses))

    %{
      "schema_contract" => schema_contract,
      "schema_version" => schema_version,
      "model" => "artifact_only_cadence_import_manifest",
      "manifest_id" => SourceIdentifierPolicy.manifest(context["source_artifact_id"]),
      "source_artifact_type" => context["source_artifact_type"],
      "source_artifact_id" => context["source_artifact_id"],
      "row_count" => length(rows),
      "ready_count" => Enum.count(rows, &(&1["import_status"] == "ready_for_import")),
      "review_required_count" =>
        Enum.count(rows, &(&1["import_status"] == "review_required_before_import")),
      "blocked_count" =>
        Enum.count(rows, &(&1["import_status"] == "blocked_missing_cadence_import")),
      "missing_import_count" => Enum.count(rows, &(&1["cadence_import_status"] == "missing")),
      "import_action_counts" => ManifestStatistics.count_by(rows, "import_action"),
      "import_status_counts" => ManifestStatistics.count_by(rows, "import_status"),
      "cadence_import_status_counts" =>
        ManifestStatistics.count_by(rows, "cadence_import_status"),
      "source_review_type_counts" => ManifestStatistics.count_by(rows, "source_review_type"),
      "source_review_action_counts" => ManifestStatistics.count_by(rows, "source_review_action"),
      "source_review_queue_counts" =>
        ManifestStatistics.count_by(rows, "source_review_queue_key"),
      "source_readiness_report_id" => context["source_readiness_report_id"],
      "readiness_level" => context["readiness_level"],
      "import_classification" => context["import_classification"],
      "status" => context["status"],
      "gate_count" => context["gate_count"],
      "passed_gate_count" => context["passed_gate_count"],
      "review_gate_count" => context["review_gate_count"],
      "analysis_gate_count" => context["analysis_gate_count"],
      "blocked_gate_count" => context["blocked_gate_count"],
      "gate_status_counts" => context["gate_status_counts"],
      "gate_classification_counts" => context["gate_classification_counts"],
      "gate_ids_by_status" => context["gate_ids_by_status"],
      "gate_ids_by_classification" => context["gate_ids_by_classification"],
      "quality_gate_row_ids_by_status" => context["quality_gate_row_ids_by_status"],
      "quality_gate_row_ids_by_classification" =>
        context["quality_gate_row_ids_by_classification"],
      "passed_gate_ids" => context["passed_gate_ids"],
      "review_required_gate_ids" => context["review_required_gate_ids"],
      "analysis_only_gate_ids" => context["analysis_only_gate_ids"],
      "blocked_gate_ids" => context["blocked_gate_ids"],
      "calendar_entry_trust_boundary_status_counts" =>
        context["calendar_entry_trust_boundary_status_counts"],
      "station_reservation_ids" => context["station_reservation_ids"],
      "station_reservation_expires_at_s" => context["station_reservation_expires_at_s"],
      "station_reservation_expiration_status_counts" =>
        context["station_reservation_expiration_status_counts"],
      "resource_blocking_dimension_counts" => context["resource_blocking_dimension_counts"],
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        context["resource_blocked_contact_ids_by_blocking_dimension"],
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        context["resource_blocked_contact_ids_by_spacecraft_id"],
      "station_pressure_contact_count" => context["station_pressure_contact_count"],
      "station_pressure_contact_ids" => context["station_pressure_contact_ids"],
      "station_pressure_review_contact_count" => context["station_pressure_review_contact_count"],
      "station_pressure_review_contact_ids" => context["station_pressure_review_contact_ids"],
      "station_pressure_contact_counts_by_ground_station_id" =>
        context["station_pressure_contact_counts_by_ground_station_id"],
      "station_pressure_contact_ids_by_ground_station_id" =>
        context["station_pressure_contact_ids_by_ground_station_id"],
      "station_pressure_contact_counts_by_availability" =>
        context["station_pressure_contact_counts_by_availability"],
      "station_pressure_contact_ids_by_availability" =>
        context["station_pressure_contact_ids_by_availability"],
      "station_pressure_contact_counts_by_precedence_availability" =>
        context["station_pressure_contact_counts_by_precedence_availability"],
      "station_pressure_contact_ids_by_precedence_availability" =>
        context["station_pressure_contact_ids_by_precedence_availability"],
      "station_pressure_contact_counts_by_precedence_rank" =>
        context["station_pressure_contact_counts_by_precedence_rank"],
      "station_pressure_contact_ids_by_precedence_rank" =>
        context["station_pressure_contact_ids_by_precedence_rank"],
      "station_pressure_contact_counts_by_status" =>
        context["station_pressure_contact_counts_by_status"],
      "station_pressure_contact_ids_by_status" =>
        context["station_pressure_contact_ids_by_status"],
      "station_pressure_contact_ids_by_direction" =>
        context["station_pressure_contact_ids_by_direction"],
      "station_pressure_contact_ids_by_direction_and_ground_station_id" =>
        context["station_pressure_contact_ids_by_direction_and_ground_station_id"],
      "capacity_pack_required_capacity_fraction" =>
        context["capacity_pack_required_capacity_fraction"],
      "capacity_pack_selected_required_capacity_fraction" =>
        context["capacity_pack_selected_required_capacity_fraction"],
      "capacity_pack_deferred_required_capacity_fraction" =>
        context["capacity_pack_deferred_required_capacity_fraction"],
      "capacity_pack_required_capacity_fraction_by_status" =>
        context["capacity_pack_required_capacity_fraction_by_status"],
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        context["capacity_pack_required_capacity_fraction_by_ground_station_id"],
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" =>
        context["capacity_pack_selected_required_capacity_fraction_by_ground_station_id"],
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" =>
        context["capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"],
      "capacity_pack_status_counts" => context["capacity_pack_status_counts"],
      "capacity_pack_contact_ids_by_status" => context["capacity_pack_contact_ids_by_status"],
      "capacity_pack_contact_ids_by_direction" =>
        context["capacity_pack_contact_ids_by_direction"],
      "capacity_pack_selected_contact_ids_by_direction" =>
        context["capacity_pack_selected_contact_ids_by_direction"],
      "capacity_pack_deferred_contact_ids_by_direction" =>
        context["capacity_pack_deferred_contact_ids_by_direction"],
      "capacity_pack_contact_ids_by_ground_station_id" =>
        context["capacity_pack_contact_ids_by_ground_station_id"],
      "capacity_pack_selected_contact_ids_by_ground_station_id" =>
        context["capacity_pack_selected_contact_ids_by_ground_station_id"],
      "capacity_pack_deferred_contact_ids_by_ground_station_id" =>
        context["capacity_pack_deferred_contact_ids_by_ground_station_id"],
      "required_capacity_fraction_source_counts" =>
        context["required_capacity_fraction_source_counts"],
      "required_capacity_fraction_contact_ids_by_source" =>
        context["required_capacity_fraction_contact_ids_by_source"],
      "provider_reservation_candidate_contact_count" =>
        context["provider_reservation_candidate_contact_count"],
      "provider_reservation_request_contact_count" =>
        context["provider_reservation_request_contact_count"],
      "provider_reservation_review_contact_count" =>
        context["provider_reservation_review_contact_count"],
      "provider_reservation_no_request_contact_count" =>
        context["provider_reservation_no_request_contact_count"],
      "provider_reservation_request_status_counts" =>
        context["provider_reservation_request_status_counts"],
      "provider_reservation_request_contact_ids" =>
        context["provider_reservation_request_contact_ids"],
      "provider_reservation_review_contact_ids" =>
        context["provider_reservation_review_contact_ids"],
      "provider_reservation_no_request_contact_ids" =>
        context["provider_reservation_no_request_contact_ids"],
      "provider_reservation_request_contact_ids_by_ground_station_id" =>
        context["provider_reservation_request_contact_ids_by_ground_station_id"],
      "provider_reservation_review_contact_ids_by_ground_station_id" =>
        context["provider_reservation_review_contact_ids_by_ground_station_id"],
      "provider_reservation_no_request_contact_ids_by_direction" =>
        context["provider_reservation_no_request_contact_ids_by_direction"],
      "provider_reservation_request_contact_ids_by_direction" =>
        context["provider_reservation_request_contact_ids_by_direction"],
      "provider_reservation_review_contact_ids_by_direction" =>
        context["provider_reservation_review_contact_ids_by_direction"],
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" =>
        context["provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"],
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id" =>
        context["provider_reservation_request_contact_ids_by_direction_and_ground_station_id"],
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id" =>
        context["provider_reservation_review_contact_ids_by_direction_and_ground_station_id"],
      "provider_reservation_request_contact_ids_by_match_status" =>
        context["provider_reservation_request_contact_ids_by_match_status"],
      "provider_reservation_review_contact_ids_by_match_status" =>
        context["provider_reservation_review_contact_ids_by_match_status"],
      "provider_reservation_request_ids_by_match_status" =>
        context["provider_reservation_request_ids_by_match_status"],
      "provider_reservation_review_ids_by_match_status" =>
        context["provider_reservation_review_ids_by_match_status"],
      "reservation_conflict_contact_ids_by_direction" =>
        context["reservation_conflict_contact_ids_by_direction"],
      "reservation_conflict_contact_ids_by_direction_and_ground_station_id" =>
        context["reservation_conflict_contact_ids_by_direction_and_ground_station_id"],
      "reduced_capacity_pack_group_count" => context["reduced_capacity_pack_group_count"],
      "reduced_capacity_pack_status_counts" => context["reduced_capacity_pack_status_counts"],
      "capacity_pack_group_ids" => context["capacity_pack_group_ids"],
      "capacity_pack_group_ids_by_status" => context["capacity_pack_group_ids_by_status"],
      "reduced_capacity_packed_contact_ids" => context["reduced_capacity_packed_contact_ids"],
      "reduced_capacity_deferred_contact_ids" => context["reduced_capacity_deferred_contact_ids"],
      "station_reservation_declared_expiration_contact_count" =>
        context["station_reservation_declared_expiration_contact_count"],
      "station_reservation_missing_expiration_contact_count" =>
        context["station_reservation_missing_expiration_contact_count"],
      "earliest_station_reservation_expires_at_s" =>
        context["earliest_station_reservation_expires_at_s"],
      "station_reservation_contact_ids_by_expiration_status" =>
        context["station_reservation_contact_ids_by_expiration_status"],
      "station_reservation_ids_by_expiration_status" =>
        context["station_reservation_ids_by_expiration_status"],
      "station_reservation_contact_ids_by_match_status" =>
        context["station_reservation_contact_ids_by_match_status"],
      "station_reservation_contact_ids_by_status" =>
        context["station_reservation_contact_ids_by_status"],
      "station_reservation_contact_ids_by_reserved_by" =>
        context["station_reservation_contact_ids_by_reserved_by"],
      "station_reservation_ids_by_match_status" =>
        context["station_reservation_ids_by_match_status"],
      "station_reservation_ids_by_status" => context["station_reservation_ids_by_status"],
      "station_reservation_ids_by_reserved_by" =>
        context["station_reservation_ids_by_reserved_by"],
      "station_reserved_bys" => context["station_reserved_bys"],
      "station_reservation_statuses" => context["station_reservation_statuses"],
      "station_reservation_match_status_counts" =>
        context["station_reservation_match_status_counts"],
      "rows" => rows,
      "provenance" => ManifestMapNormalization.compact(provenance),
      "model_limits" => ManifestStatistics.model_limits(capability),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_api_writes",
        "authorization_boundary" => "operator_review_or_cadence_adapter_must_authorize_import",
        "row_source" => context["row_source"],
        "deterministic_ordering" => context["deterministic_ordering"]
      }
    }
    |> ManifestMapNormalization.compact()
  end
end
