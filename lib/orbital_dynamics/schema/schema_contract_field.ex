defmodule OrbitalDynamics.Schema.SchemaContractField do
  @moduledoc false

  def validate_optional(issues, path, map, expected, callbacks)
      when is_map(map) and is_list(callbacks) do
    if Map.has_key?(map, "schema_contract") do
      expect_equal(callbacks, issues, path, map, "schema_contract", expected)
    else
      issues
    end
  end

  defp expect_equal(callbacks, issues, path, map, field, expected),
    do:
      apply(require_callback(callbacks, :expect_equal), [
        issues,
        path,
        map,
        field,
        expected
      ])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
