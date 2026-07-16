defmodule OrbitalDynamics.Schema.RealizedSpacecraftStateContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_optional_list: 4,
      expect_optional_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate(issues, path, state) do
    issues
    |> require_fields(path, state, ["scenario_id"])
    |> validate_stable_ids(path, state, ["spacecraft_id", "scenario_id"])
    |> expect_optional_type(path, state, "mode", :binary)
    |> expect_optional_type(path, state, "status", :binary)
    |> expect_optional_type(path, state, "payload_status", :binary)
    |> expect_optional_type(path, state, "degraded", :boolean)
    |> expect_optional_type(path, state, "payload_available", :boolean)
    |> expect_optional_type(path, state, "antenna_available", :boolean)
    |> expect_optional_type(path, state, "metadata", :map)
    |> expect_optional_list(path, state, "incompatible_activity_types")
    |> validate_string_list_items(path, state, "incompatible_activity_types")
    |> validate_source(path, state)
  end

  defp validate_source(issues, path, state) do
    case Map.get(state, "source") do
      nil ->
        issues

      :null ->
        issues

      source when is_binary(source) or is_map(source) ->
        issues

      _source ->
        [error(path <> ".source", "must be a string or map") | issues]
    end
  end
end
