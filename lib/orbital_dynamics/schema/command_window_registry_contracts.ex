defmodule OrbitalDynamics.Schema.CommandWindowRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "command_window_report.v1" => %{
        "schema_contract" => "command_window_report.v1",
        "artifact_family" => "command_window_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "window_count",
          "command_count",
          "tracking_count",
          "uplink_count",
          "health_check_count",
          "review_required_count",
          "source_window_lineage_count",
          "rows",
          "assumptions"
        ],
        "optional_fields" => [
          "model_limits",
          "activity_ids_by_window_type",
          "review_activity_ids_by_required_operator_action"
        ],
        "nested_contracts" => ["operational_timeline_report.v1"]
      }
    }
  end
end
