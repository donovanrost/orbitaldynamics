defmodule OrbitalDynamics.Schema.StationCalendarPrecedenceSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "affected_contact_count",
    "reserved_under_higher_precedence_contact_count"
  ]

  @count_map_fields [
    "applied_availability_counts",
    "applied_status_counts",
    "overlap_availability_counts"
  ]

  @stable_id_array_map_fields [
    "affected_contact_ids_by_applied_availability",
    "affected_contact_ids_by_applied_status",
    "affected_contact_ids_by_overlap_availability",
    "reserved_under_higher_precedence_contact_ids_by_applied_availability",
    "reserved_under_higher_precedence_contact_ids_by_applied_status",
    "reserved_under_higher_precedence_reservation_ids_by_status",
    "reserved_under_higher_precedence_reservation_ids_by_reserved_by",
    "reserved_under_higher_precedence_contact_ids_by_reservation_status",
    "reserved_under_higher_precedence_contact_ids_by_reserved_by"
  ]

  @stable_id_array_fields [
    "reserved_under_higher_precedence_contact_ids",
    "reserved_under_higher_precedence_reservation_ids",
    "unavailable_contact_ids",
    "reserved_overlap_contact_ids",
    "reduced_capacity_contact_ids"
  ]

  def property("schema_contract", _opts) do
    %{"type" => "string", "const" => "station_calendar_precedence_summary.v1"}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "enum" => ["station_calendar_report.v1"]}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_station_calendar_precedence_summary"}
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

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("precedence_review_status", _opts) do
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
