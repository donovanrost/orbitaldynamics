defmodule OrbitalDynamics.Schema.ContactAllocationStationPressureRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "contact_allocation_station_pressure_summary.v1" => %{
        "schema_contract" => "contact_allocation_station_pressure_summary.v1",
        "artifact_family" => "contact_allocation_station_pressure_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "input_contact_count",
          "station_pressure_contact_count",
          "station_pressure_review_contact_count",
          "station_pressure_contact_ids",
          "station_pressure_review_contact_ids",
          "station_pressure_contact_ids_by_ground_station_id",
          "station_pressure_contact_counts_by_ground_station_id",
          "station_pressure_contact_ids_by_availability",
          "station_pressure_contact_counts_by_availability",
          "station_pressure_contact_ids_by_precedence_availability",
          "station_pressure_contact_counts_by_precedence_availability",
          "station_pressure_contact_ids_by_precedence_rank",
          "station_pressure_contact_counts_by_precedence_rank",
          "rows",
          "review_rows",
          "assumptions"
        ],
        "optional_fields" => [
          "source",
          "station_pressure_contact_ids_by_status",
          "station_pressure_contact_counts_by_status",
          "station_pressure_contact_ids_by_direction_and_ground_station_id",
          "model_limits"
        ],
        "nested_contracts" => ["contact_allocation_report.v1"]
      }
    }
  end
end
