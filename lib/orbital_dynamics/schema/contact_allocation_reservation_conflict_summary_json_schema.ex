defmodule OrbitalDynamics.Schema.ContactAllocationReservationConflictSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @row_fields [
    "rows",
    "reservation_conflict_rows",
    "reservation_review_rows"
  ]

  @count_fields [
    "input_contact_count",
    "station_reservation_contact_count",
    "reservation_conflict_contact_count",
    "reservation_review_contact_count"
  ]

  @count_map_fields [
    "station_reservation_match_status_counts",
    "reservation_conflict_match_status_counts",
    "station_reservation_status_counts",
    "station_reserved_by_counts",
    "station_reservation_expiration_status_counts"
  ]

  @stable_id_array_fields [
    "station_reservation_ids",
    "reservation_conflict_contact_ids",
    "reservation_review_contact_ids"
  ]

  @stable_id_array_map_fields [
    "station_reservation_contact_ids_by_match_status",
    "reservation_conflict_contact_ids_by_match_status",
    "reservation_conflict_contact_ids_by_direction",
    "station_reservation_contact_ids_by_status",
    "station_reservation_contact_ids_by_reserved_by",
    "station_reservation_contact_ids_by_expiration_status",
    "station_reservation_ids_by_match_status",
    "reservation_conflict_reservation_ids_by_match_status",
    "station_reservation_ids_by_status",
    "station_reservation_ids_by_reserved_by",
    "station_reservation_ids_by_expiration_status"
  ]

  @number_fields [
    "station_reservation_expiration_now_s",
    "earliest_station_reservation_expires_at_s"
  ]

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "enum" => ["contact_allocation_report.v1"]}
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "artifact_only_contact_allocation_reservation_conflict_summary"
    }
  end

  def property("source", _opts) do
    %{"type" => "string"}
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

  def property(field, opts) when field in @row_fields do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property("reservation_conflict_contact_ids_by_direction_and_ground_station_id", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.nested_stable_id_array_map()
  end

  def property("station_reservation_expires_at_s", _opts) do
    %{"type" => "array", "items" => %{"type" => "number"}}
  end

  def property(field, _opts) when field in @number_fields do
    %{"type" => "number"}
  end
end
