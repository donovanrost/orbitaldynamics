defmodule OrbitalDynamics.Schema.ContactAllocationStationPressureSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "input_contact_count",
    "station_pressure_contact_count",
    "station_pressure_review_contact_count"
  ]

  @stable_id_array_fields [
    "station_pressure_contact_ids",
    "station_pressure_review_contact_ids"
  ]

  @stable_id_array_map_fields [
    "station_pressure_contact_ids_by_ground_station_id",
    "station_pressure_contact_ids_by_availability",
    "station_pressure_contact_ids_by_precedence_availability",
    "station_pressure_contact_ids_by_precedence_rank",
    "station_pressure_contact_ids_by_status"
  ]

  @count_map_fields [
    "station_pressure_contact_counts_by_ground_station_id",
    "station_pressure_contact_counts_by_availability",
    "station_pressure_contact_counts_by_precedence_availability",
    "station_pressure_contact_counts_by_precedence_rank",
    "station_pressure_contact_counts_by_status"
  ]

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "enum" => ["contact_allocation_report.v1"]}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_contact_allocation_station_pressure_summary"}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, opts) when field in ["rows", "review_rows"] do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    stable_id_array(opts)
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property("station_pressure_contact_ids_by_direction_and_ground_station_id", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.nested_stable_id_array_map()
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  defp stable_id_array(opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end
end
