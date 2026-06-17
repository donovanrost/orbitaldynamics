defmodule OrbitalDynamics.Schema.StationReservationHoldSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "reservation_hold_count",
    "affected_contact_reservation_hold_count",
    "provider_calendar_contention_hold_count",
    "reservation_hold_expiration_count"
  ]

  @count_map_fields [
    "reservation_hold_expiration_status_counts",
    "reservation_hold_status_counts"
  ]

  @stable_id_array_map_fields [
    "reservation_hold_ids_by_expiration_status",
    "reservation_hold_ids_by_status",
    "reservation_hold_ids_by_reserved_by",
    "reservation_hold_ids_by_row_type",
    "reservation_hold_contact_ids_by_expiration_status"
  ]

  @stable_id_array_fields [
    "reservation_hold_ids",
    "review_contact_ids"
  ]

  def property("schema_contract", _opts) do
    %{"type" => "string", "const" => "station_reservation_hold_summary.v1"}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "enum" => ["station_reservation_report.v1"]}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_station_reservation_hold_summary"}
  end

  def property("review_rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("earliest_reservation_hold_expires_at_s", _opts) do
    %{"type" => "number"}
  end

  def property("reservation_hold_review_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "review_required"]}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end
end
