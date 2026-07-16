defmodule OrbitalDynamics.Schema.ProposedContactRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "proposed_contact.v1" => %{
        "schema_contract" => "proposed_contact.v1",
        "artifact_family" => "proposed_contact",
        "schema_version" => 1,
        "required_fields" => [
          "id",
          "type",
          "scenario_id",
          "ground_station_id",
          "starts_at_s",
          "ends_at_s",
          "direction",
          "estimated_throughput_mb",
          "source_window",
          "cadence_import"
        ],
        "optional_fields" => [
          "model_limits",
          "station_availability",
          "schedule_conflict_status",
          "source_window_id",
          "timeline_id",
          "timeline_identity"
        ],
        "nested_contracts" => []
      }
    }
  end
end
