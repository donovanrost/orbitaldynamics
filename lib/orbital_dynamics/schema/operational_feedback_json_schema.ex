defmodule OrbitalDynamics.Schema.OperationalFeedbackJsonSchema do
  @moduledoc false

  def operational_feedback(schemas) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "contact_success_rate" => schemas.probability_map,
        "observation_success_rate" => schemas.probability_map,
        "image_quality_score" => schemas.probability_map,
        "image_quality_status" => schemas.string_value_map,
        "image_quality_source" => schemas.string_value_map,
        "cloud_cover_fraction" => schemas.probability_map,
        "blur_score" => schemas.probability_map,
        "maneuver_success_rate" => schemas.probability_map,
        "command_success_rate" => schemas.probability_map,
        "station_throughput_factor" => schemas.probability_map,
        "downlink_demand_mb" => schemas.non_negative_number_map,
        "downlink_demand_sources" => schemas.string_list_map,
        "downlink_demand_context" => schemas.nested_object_map,
        "target_priority_overrides" => schemas.non_negative_number_map,
        "resource_margin_overrides" => schemas.nested_object_map,
        "resource_availability_overrides" => schemas.nested_object_map,
        "maneuver_execution_uncertainty" => schemas.nested_object_map,
        "trust_boundary" => %{"type" => "string"},
        "provenance" => %{"type" => "object", "additionalProperties" => true},
        "realized_activities" => %{
          "type" => "array",
          "items" => schemas.realized_activity
        }
      }
    }
  end

  def timeline_feedback_provenance(timeline_feedback_report, schemas) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "model" => %{
          "type" => "string",
          "const" => "timeline_feedback_report_rows_to_operational_feedback"
        },
        "merge_order" => schemas.string_array,
        "input_keys" => schemas.string_array,
        "source_count" => %{"type" => "integer", "minimum" => 0},
        "explicit_request_override" => %{"type" => "boolean"},
        "sources" => %{
          "type" => "array",
          "items" => timeline_feedback_provenance_source(timeline_feedback_report, schemas)
        }
      }
    }
  end

  def strategy_provenance do
    string_array = OrbitalDynamics.Schema.CommonJsonSchema.string_array()

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "model",
        "merge_order",
        "input_keys",
        "effective_sources",
        "overridden_sources",
        "source_count",
        "sources",
        "explicit_request_override"
      ],
      "properties" => %{
        "model" => %{
          "type" => "string",
          "const" => "deterministic_merge_explicit_overrides_mission_state_overrides_prior_plan"
        },
        "merge_order" => string_array,
        "input_keys" => string_array,
        "effective_sources" => OrbitalDynamics.Schema.CommonJsonSchema.string_value_map(),
        "overridden_sources" => OrbitalDynamics.Schema.CommonJsonSchema.string_list_map(),
        "source_count" => %{"type" => "integer", "minimum" => 0},
        "sources" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "additionalProperties" => true,
            "required" => ["source", "input_keys"],
            "properties" => %{
              "source" => %{"type" => "string"},
              "input_keys" => string_array
            }
          }
        },
        "explicit_request_override" => %{"type" => "boolean"}
      }
    }
  end

  defp timeline_feedback_provenance_source(timeline_feedback_report, schemas) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "source" => %{"type" => "string"},
        "source_report_contract" => %{
          "type" => "string",
          "const" => timeline_feedback_report
        },
        "source_report_count" => %{"type" => "integer", "minimum" => 0},
        "source_report_row_count" => %{"type" => "integer", "minimum" => 0},
        "realized_activity_count" => %{"type" => "integer", "minimum" => 0},
        "weighted_feedback_row_count" => %{"type" => "integer", "minimum" => 0},
        "source_operational_feedback_excluded_count" => %{"type" => "integer", "minimum" => 0},
        "input_keys" => schemas.string_array,
        "trust_boundary_status" => %{"type" => "string"},
        "trust_boundaries" => schemas.string_array,
        "feedback_weight_sources" => schemas.string_array,
        "source_report_status_counts" => schemas.count_map,
        "source_feedback_kind_counts" => schemas.count_map,
        "source_match_strategy_counts" => schemas.count_map,
        "source_cadence_import_status_counts" => schemas.count_map,
        "source_planned_protection_decision_counts" => schemas.count_map,
        "source_realized_source_quality_counts" => schemas.count_map,
        "feedback_trust_boundaries" => schemas.string_list_map
      }
    }
  end
end
