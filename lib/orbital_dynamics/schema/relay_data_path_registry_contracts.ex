defmodule OrbitalDynamics.Schema.RelayDataPathRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "relay_data_path_summary.v1" => %{
        "schema_contract" => "relay_data_path_summary.v1",
        "artifact_family" => "relay_data_path_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "schema_version",
          "model",
          "source",
          "route_count",
          "relay_route_count",
          "direct_downlink_route_count",
          "custody_status_counts",
          "latency_status_counts",
          "risk_status_counts",
          "route_ids",
          "source_spacecraft_ids",
          "relay_spacecraft_ids",
          "ground_station_ids",
          "ground_downlink_contact_ids",
          "route_ids_by_custody_status",
          "route_ids_by_latency_status",
          "route_ids_by_risk_status",
          "route_ids_by_ground_station_id",
          "model_limits",
          "assumptions",
          "rows"
        ],
        "optional_fields" => [
          "maximum_latency_s",
          "maximum_latency_limit_s"
        ],
        "nested_contracts" => []
      }
    }
  end
end
