defmodule OrbitalDynamics.Schema.StationReservationHoldImportReadinessSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "reservation_hold_count",
    "ready_for_import_count",
    "review_required_before_import_count",
    "no_import_required_count"
  ]

  @count_map_fields [
    "reservation_hold_import_status_counts",
    "reservation_hold_status_counts",
    "reservation_hold_expiration_status_counts",
    "required_import_action_counts"
  ]

  @stable_id_array_map_fields [
    "reservation_hold_ids_by_import_status",
    "reservation_hold_ids_by_expiration_status",
    "reservation_hold_ids_by_status",
    "reservation_hold_ids_by_reserved_by",
    "reservation_hold_ids_by_required_import_action",
    "reservation_hold_ids_by_direction",
    "reservation_hold_contact_ids_by_import_status",
    "reservation_hold_contact_ids_by_expiration_status",
    "reservation_hold_contact_ids_by_direction"
  ]

  @nested_stable_id_array_map_fields [
    "reservation_hold_ids_by_direction_and_ground_station_id",
    "reservation_hold_contact_ids_by_direction_and_ground_station_id"
  ]

  @stable_id_array_fields [
    "reservation_hold_ids",
    "review_contact_ids"
  ]

  def property("schema_contract", _opts) do
    %{
      "type" => "string",
      "const" => "station_reservation_hold_import_readiness_summary.v1"
    }
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "enum" => ["station_reservation_report.v1"]}
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "artifact_only_station_reservation_hold_import_readiness_summary"
    }
  end

  def property("import_readiness_rows", opts) do
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

  def property("import_readiness_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "review_required"]}
  end

  def property("import_classification", _opts) do
    %{"type" => "string", "enum" => ["not_applicable", "review_only"]}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property(field, opts) when field in @nested_stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.nested_stable_id_array_map()
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def import_readiness_row(opts) do
    opts
    |> Keyword.fetch!(:review_row_schema)
    |> put_in(
      ["properties", "station_reservation_hold_import_status"],
      %{"type" => "string", "enum" => ["review_required_before_import"]}
    )
  end
end
