defmodule OrbitalDynamics.Schema.ContactIntentSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "contact_intent_count",
    "capacity_pack_required_contact_count"
  ]

  @stable_id_array_map_fields [
    "required_capacity_fraction_contact_ids_by_source",
    "contact_ids_by_ground_station_id",
    "contact_ids_by_direction",
    "capacity_pack_contact_ids_by_ground_station_id",
    "capacity_pack_contact_ids_by_direction"
  ]

  @nested_stable_id_array_map_fields [
    "contact_ids_by_direction_and_ground_station_id",
    "capacity_pack_contact_ids_by_direction_and_ground_station_id"
  ]

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_contact_intent_summary"}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "const" => "contact_intent.v1"}
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

  def property("capacity_pack_required_capacity_fraction", _opts) do
    %{"type" => ["number", "null"], "minimum" => 0}
  end

  def property("capacity_pack_required_capacity_fraction_by_ground_station_id", _opts) do
    %{"type" => ["object", "null"], "additionalProperties" => %{"type" => "number"}}
  end

  def property("capacity_pack_required_capacity_fraction_by_direction", _opts) do
    %{
      "type" => ["object", "null"],
      "additionalProperties" => %{"type" => "number", "minimum" => 0.0}
    }
  end

  def property("required_capacity_fraction_source_counts", _opts) do
    %{
      "type" => ["object", "null"],
      "additionalProperties" => %{"type" => "integer", "minimum" => 0}
    }
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    %{
      "type" => ["object", "null"],
      "additionalProperties" => stable_id_array(opts)
    }
  end

  def property(field, opts) when field in @nested_stable_id_array_map_fields do
    %{
      "type" => ["object", "null"],
      "additionalProperties" => %{
        "type" => "object",
        "additionalProperties" => stable_id_array(opts)
      }
    }
  end

  def property(
        "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id",
        _opts
      ) do
    %{
      "type" => ["object", "null"],
      "additionalProperties" => %{
        "type" => "object",
        "additionalProperties" => %{"type" => "number", "minimum" => 0.0}
      }
    }
  end

  def property("direction_counts", _opts) do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property("direction_routing", opts) do
    direction_routing(opts)
  end

  def property("ground_station_ids", opts) do
    stable_id_array(opts)
  end

  def property("directions", _opts) do
    %{
      "type" => "array",
      "items" => %{
        "type" => "string",
        "enum" => OrbitalDynamics.Communications.ContactIntent.capabilities().directions
      }
    }
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def direction_routing(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => %{
        "type" => "object",
        "additionalProperties" => true,
        "properties" => %{
          "contact_count" => %{"type" => "integer", "minimum" => 0},
          "contact_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
          "capacity_pack_required_capacity_fraction" => %{"type" => "number", "minimum" => 0.0},
          "capacity_pack_contact_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
          "ground_station_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
          "contact_ids_by_ground_station_id" =>
            CommonJsonSchema.stable_id_array_map(stable_id_pattern),
          "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
            CommonJsonSchema.non_negative_number_map(),
          "capacity_pack_contact_ids_by_ground_station_id" =>
            CommonJsonSchema.stable_id_array_map(stable_id_pattern),
          "contact_ids_by_ground_station" =>
            CommonJsonSchema.stable_id_array_map(stable_id_pattern),
          "capacity_pack_required_capacity_fraction_by_ground_station" =>
            CommonJsonSchema.non_negative_number_map(),
          "capacity_pack_contact_ids_by_ground_station" =>
            CommonJsonSchema.stable_id_array_map(stable_id_pattern)
        }
      }
    }
  end

  defp stable_id_array(opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end
end
