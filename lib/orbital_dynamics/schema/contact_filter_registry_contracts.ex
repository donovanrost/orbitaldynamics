defmodule OrbitalDynamics.Schema.ContactFilterRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "contact_filter_report.v1" => %{
        "schema_contract" => "contact_filter_report.v1",
        "artifact_family" => "contact_filter_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "input_candidate_count",
          "kept_candidate_count",
          "suppressed_candidate_count",
          "suppressed_candidates"
        ],
        "optional_fields" => [
          "policy",
          "model_limits",
          "assumptions",
          "invalid_contact_input_count",
          "invalid_contact_input_ids",
          "suppression_reason_counts",
          "suppressed_candidate_ids_by_reason",
          "station_calendar_trust_boundary_status_counts",
          "suppressed_candidate_ids_by_station_calendar_trust_boundary_status",
          "station_reservation_match_status_counts",
          "suppressed_candidate_ids_by_reservation_match_status",
          "duplicate_suppressed_candidate_row_count",
          "duplicate_suppressed_candidate_id_count"
        ],
        "nested_contracts" => []
      }
    }
  end
end
