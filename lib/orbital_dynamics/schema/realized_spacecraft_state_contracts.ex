defmodule OrbitalDynamics.Schema.RealizedSpacecraftStateContracts do
  @moduledoc false

  def validate(issues, path, state, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, state, ["scenario_id"])
    |> validate_stable_ids(callbacks, path, state, ["spacecraft_id", "scenario_id"])
    |> expect_optional_type(callbacks, path, state, "mode", :binary)
    |> expect_optional_type(callbacks, path, state, "status", :binary)
    |> expect_optional_type(callbacks, path, state, "payload_status", :binary)
    |> expect_optional_type(callbacks, path, state, "degraded", :boolean)
    |> expect_optional_type(callbacks, path, state, "payload_available", :boolean)
    |> expect_optional_type(callbacks, path, state, "antenna_available", :boolean)
    |> expect_optional_type(callbacks, path, state, "metadata", :map)
    |> expect_optional_list(callbacks, path, state, "incompatible_activity_types")
    |> validate_string_list_items(callbacks, path, state, "incompatible_activity_types")
    |> validate_source(callbacks, path, state)
  end

  defp validate_source(issues, callbacks, path, state) do
    case Map.get(state, "source") do
      nil ->
        issues

      :null ->
        issues

      source when is_binary(source) or is_map(source) ->
        issues

      _source ->
        [error(callbacks, path <> ".source", "must be a string or map") | issues]
    end
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_list(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_list), [issues, path, map, field])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])
end
