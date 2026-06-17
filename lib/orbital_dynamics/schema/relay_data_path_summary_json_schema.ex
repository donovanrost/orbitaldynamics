defmodule OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema do
  @moduledoc false

  @summary "relay_data_path_summary.v1"

  @integer_fields [
    "route_count",
    "relay_route_count",
    "direct_downlink_route_count"
  ]

  @number_fields [
    "maximum_latency_s",
    "maximum_latency_limit_s"
  ]

  @count_map_fields [
    "custody_status_counts",
    "latency_status_counts",
    "risk_status_counts"
  ]

  @stable_id_array_fields [
    "route_ids",
    "source_spacecraft_ids",
    "relay_spacecraft_ids",
    "ground_station_ids",
    "ground_downlink_contact_ids"
  ]

  @stable_id_array_map_fields [
    "route_ids_by_custody_status",
    "route_ids_by_latency_status",
    "route_ids_by_risk_status",
    "route_ids_by_ground_station_id"
  ]

  def property("schema_contract", _opts) do
    %{"type" => "string", "const" => @summary}
  end

  def property("schema_version", _opts) do
    %{"type" => "integer", "const" => 1}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_relay_data_path_summary"}
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

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property(field, _opts) when field in @integer_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @number_fields do
    %{"type" => "number"}
  end

  def property(field, opts) when field in @count_map_fields do
    Keyword.fetch!(opts, :count_map_schema)
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    Keyword.fetch!(opts, :stable_id_array_map_schema)
  end
end
