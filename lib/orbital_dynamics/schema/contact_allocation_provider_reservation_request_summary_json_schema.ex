defmodule OrbitalDynamics.Schema.ContactAllocationProviderReservationRequestSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @row_fields [
    "rows",
    "provider_reservation_request_rows",
    "provider_reservation_review_rows"
  ]

  @count_fields [
    "input_contact_count",
    "provider_reservation_candidate_contact_count",
    "provider_reservation_request_contact_count",
    "provider_reservation_review_contact_count",
    "provider_reservation_no_request_contact_count"
  ]

  @stable_id_array_fields [
    "provider_reservation_request_contact_ids",
    "provider_reservation_review_contact_ids",
    "provider_reservation_no_request_contact_ids"
  ]

  @stable_id_array_map_fields [
    "provider_reservation_request_contact_ids_by_ground_station_id",
    "provider_reservation_review_contact_ids_by_ground_station_id",
    "provider_reservation_no_request_contact_ids_by_direction",
    "provider_reservation_request_contact_ids_by_direction",
    "provider_reservation_review_contact_ids_by_direction",
    "provider_reservation_request_contact_ids_by_match_status",
    "provider_reservation_review_contact_ids_by_match_status",
    "provider_reservation_request_ids_by_match_status",
    "provider_reservation_review_ids_by_match_status"
  ]

  @nested_stable_id_array_map_fields [
    "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
    "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
    "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
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
      "const" => "artifact_only_contact_allocation_provider_reservation_request_summary"
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

  def property("provider_reservation_request_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "request_ready", "review_required"]}
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

  def property(field, opts) when field in @nested_stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.nested_stable_id_array_map()
  end
end
