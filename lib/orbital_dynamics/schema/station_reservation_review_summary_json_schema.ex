defmodule OrbitalDynamics.Schema.StationReservationReviewSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "reservation_count",
    "affected_contact_reservation_count",
    "provider_calendar_contention_group_count",
    "reservation_expiration_count",
    "expired_reservation_count",
    "active_reservation_count",
    "missing_reservation_expiration_count"
  ]

  def property("schema_contract", _opts) do
    %{"type" => "string", "const" => "station_reservation_review_summary.v1"}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_station_reservation_review_summary"}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "enum" => ["station_reservation_report.v1"]}
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

  def property("earliest_reservation_expires_at_s", _opts) do
    %{"type" => "number"}
  end

  def property("reservation_review_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "review_required"]}
  end

  def property("reservation_expiration_status_counts", _opts) do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property("reservation_ids_by_expiration_status", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property("review_reservation_ids", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def review_row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    base_schema = Keyword.fetch!(opts, :base_schema)

    base_schema
    |> put_in(
      ["properties", "reservation_review_row_type"],
      %{
        "type" => "string",
        "enum" => ["affected_contact", "provider_calendar_contention_group"]
      }
    )
    |> put_in(
      ["properties", "reservation_ids"],
      CommonJsonSchema.stable_id_array(stable_id_pattern)
    )
    |> put_in(["properties", "reservation_statuses"], CommonJsonSchema.string_array())
    |> put_in(["properties", "reserved_by"], CommonJsonSchema.string_array())
    |> put_in(["properties", "reservation_expires_at_s"], CommonJsonSchema.number_array())
    |> put_in(
      ["properties", "station_reservation_expiration_status"],
      %{"type" => "string", "enum" => ["missing", "expired", "active", "declared"]}
    )
  end
end
