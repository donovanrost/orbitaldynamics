defmodule OrbitalDynamics.Schema.LinkCapacityReportJsonSchema do
  @moduledoc false

  @integer_fields [
    "contact_count",
    "selected_contact_count",
    "effective_contact_count",
    "ignored_contact_count",
    "ignored_selected_contact_count",
    "ambiguous_selected_contact_id_count",
    "duplicate_contact_candidate_count",
    "duplicate_contact_id_count",
    "unmatched_selected_contact_count",
    "required_downlink_contact_count",
    "actual_throughput_contact_count",
    "actual_completion_contact_count",
    "unmatched_actual_throughput_contact_count",
    "ambiguous_actual_throughput_contact_count",
    "unmatched_actual_completion_contact_count",
    "ambiguous_actual_completion_contact_count",
    "invalid_contact_input_count",
    "invalid_selected_contact_input_count",
    "invalid_policy_required_downlink_station_count"
  ]

  @stable_id_array_fields [
    "actual_throughput_contact_ids",
    "ignored_contact_ids",
    "ignored_selected_contact_ids",
    "ambiguous_selected_contact_ids",
    "unmatched_selected_contact_ids",
    "actual_completion_contact_ids",
    "unmatched_actual_throughput_contact_ids",
    "ambiguous_actual_throughput_contact_ids",
    "unmatched_actual_completion_contact_ids",
    "ambiguous_actual_completion_contact_ids",
    "invalid_contact_input_ids",
    "invalid_selected_contact_input_ids",
    "station_reservation_ids"
  ]

  @string_array_fields [
    "required_downlink_contact_ids",
    "invalid_policy_required_downlink_station_ids",
    "downlink_completion_sources",
    "station_reserved_bys",
    "station_reservation_statuses"
  ]

  @number_array_fields ["station_reservation_expires_at_s"]

  @count_map_fields [
    "ignored_contact_reason_counts",
    "ignored_selected_contact_reason_counts",
    "station_reservation_match_status_counts"
  ]

  @invalid_input_fields [
    "invalid_contact_inputs",
    "invalid_selected_contact_inputs"
  ]

  def row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    probability_schema = Keyword.fetch!(opts, :probability_schema)
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)
    string_array_schema = Keyword.fetch!(opts, :string_array_schema)
    count_map_schema = Keyword.fetch!(opts, :count_map_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "ground_station_id",
        "contact_count",
        "selected_contact_count",
        "estimated_throughput_mb",
        "selected_estimated_throughput_mb",
        "contact_ids",
        "selected_contact_ids"
      ],
      "properties" => %{
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "contact_count" => integer_schema(),
        "selected_contact_count" => integer_schema(),
        "estimated_throughput_mb" => %{"type" => "number"},
        "selected_estimated_throughput_mb" => %{"type" => "number"},
        "capacity_adjusted_throughput_mb" => %{"type" => "number"},
        "selected_capacity_adjusted_throughput_mb" => %{"type" => "number"},
        "unused_capacity_adjusted_throughput_mb" => %{"type" => "number"},
        "selected_capacity_utilization_fraction" =>
          property("selected_capacity_utilization_fraction", []),
        "selection_utilization_status" => %{"type" => "string"},
        "capacity_fraction_min" => probability_schema,
        "capacity_fraction_max" => probability_schema,
        "effective_contact_count" => integer_schema(),
        "ignored_contact_count" => integer_schema(),
        "ignored_contact_ids" => stable_id_array_schema,
        "ignored_contact_reason_counts" => count_map_schema,
        "ignored_selected_contact_count" => integer_schema(),
        "ignored_selected_contact_ids" => stable_id_array_schema,
        "ignored_selected_contact_reason_counts" => count_map_schema,
        "ambiguous_selected_contact_id_count" => integer_schema(),
        "ambiguous_selected_contact_ids" => stable_id_array_schema,
        "duplicate_contact_candidate_count" => integer_schema(),
        "duplicate_contact_ids" => stable_id_array_schema,
        "station_calendar_entry_ids" => stable_id_array_schema,
        "station_calendar_provider_ids" => stable_id_array_schema,
        "station_calendar_provider_entry_ids" => stable_id_array_schema,
        "station_calendar_directions" => string_array_schema,
        "station_availability" => %{"type" => "string"},
        "station_reservation_ids" => stable_id_array_schema,
        "station_reserved_bys" => string_array_schema,
        "station_reservation_statuses" => string_array_schema,
        "station_reservation_match_statuses" => string_array_schema,
        "contact_ids" => string_array_schema,
        "selected_contact_ids" => string_array_schema,
        "required_downlink_contact_count" => integer_schema(),
        "required_downlink_contact_ids" => string_array_schema,
        "actual_throughput_mb" => %{"type" => "number"},
        "actual_throughput_contact_count" => integer_schema(),
        "actual_throughput_contact_ids" => stable_id_array_schema,
        "actual_completion_contact_count" => integer_schema(),
        "actual_completion_contact_ids" => stable_id_array_schema,
        "unmatched_actual_throughput_contact_count" => integer_schema(),
        "unmatched_actual_throughput_contact_ids" => stable_id_array_schema,
        "ambiguous_actual_throughput_contact_count" => integer_schema(),
        "ambiguous_actual_throughput_contact_ids" => stable_id_array_schema,
        "unmatched_actual_completion_contact_count" => integer_schema(),
        "unmatched_actual_completion_contact_ids" => stable_id_array_schema,
        "ambiguous_actual_completion_contact_count" => integer_schema(),
        "ambiguous_actual_completion_contact_ids" => stable_id_array_schema,
        "actual_downlink_completion_ratio" => property("actual_downlink_completion_ratio", []),
        "actual_data_rate_throughput_derivations" =>
          Keyword.fetch!(opts, :actual_data_rate_throughput_derivations_schema),
        "policy_decision" => Keyword.fetch!(opts, :policy_decision_schema)
      }
    }
  end

  def property("rows", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :row_schema)
    }
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "fixed_rate_downlink_capacity_summary"
    }
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property("actual_downlink_completion_ratio", _opts) do
    %{"type" => "number", "minimum" => 0, "maximum" => 1}
  end

  def property("selected_capacity_utilization_fraction", _opts) do
    %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
  end

  def property(field, _opts) when field in @integer_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @string_array_fields do
    Keyword.fetch!(opts, :string_array_schema)
  end

  def property(field, opts) when field in @count_map_fields do
    Keyword.fetch!(opts, :count_map_schema)
  end

  def property(field, opts) when field in @number_array_fields do
    Keyword.fetch!(opts, :number_array_schema)
  end

  def property(field, _opts) when field in @invalid_input_fields do
    %{"type" => "array", "items" => %{"type" => "object", "additionalProperties" => true}}
  end

  def property("actual_data_rate_throughput_derivations", opts) do
    Keyword.fetch!(opts, :actual_data_rate_throughput_derivations_schema)
  end

  defp integer_schema do
    %{"type" => "integer", "minimum" => 0}
  end
end
