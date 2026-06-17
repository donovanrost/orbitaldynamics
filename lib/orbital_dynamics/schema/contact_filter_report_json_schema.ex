defmodule OrbitalDynamics.Schema.ContactFilterReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "input_candidate_count",
    "kept_candidate_count",
    "suppressed_candidate_count",
    "invalid_contact_input_count",
    "duplicate_suppressed_candidate_row_count",
    "duplicate_suppressed_candidate_id_count"
  ]

  @count_map_fields [
    "suppression_reason_counts",
    "station_reservation_match_status_counts"
  ]

  @string_list_map_fields [
    "suppressed_candidate_ids_by_reason",
    "suppressed_candidate_ids_by_reservation_match_status",
    "suppressed_candidate_ids_by_station_calendar_trust_boundary_status"
  ]

  def property("invalid_contact_input_ids", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("station_calendar_trust_boundary_status_counts", opts) do
    Keyword.fetch!(opts, :trust_boundary_count_map_schema)
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, _opts) when field in @string_list_map_fields do
    CommonJsonSchema.string_list_map()
  end

  def property("model_limits", opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :model_limits)}
    }
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "thin_ground_network_availability_filter"
    }
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def property("suppressed_candidates", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :suppressed_candidate_schema)}
  end
end
