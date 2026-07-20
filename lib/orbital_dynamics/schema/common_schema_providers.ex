defmodule OrbitalDynamics.Schema.CommonSchemaProviders do
  @moduledoc false

  def build(stable_id_pattern, sha256_pattern)
      when is_binary(stable_id_pattern) and is_binary(sha256_pattern) do
    %{
      {:sha256_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.CommonJsonSchema.sha256(sha256_pattern)
      end,
      {:stable_id_array_schema, 0} => fn ->
        OrbitalDynamics.Schema.CommonJsonSchema.stable_id_array(stable_id_pattern)
      end,
      {:stable_id_array_map_schema, 0} => fn ->
        OrbitalDynamics.Schema.CommonJsonSchema.stable_id_array_map(stable_id_pattern)
      end,
      {:nested_stable_id_array_map_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.CommonJsonSchema.nested_stable_id_array_map(stable_id_pattern)
      end
    }
  end
end
