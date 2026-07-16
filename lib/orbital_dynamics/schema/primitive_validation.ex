defmodule OrbitalDynamics.Schema.PrimitiveValidation do
  @moduledoc false

  def expect_type(issues, path, map, field, type) do
    if matches_type?(Map.get(map, field), type) do
      issues
    else
      [error("#{path}.#{field}", "must be a #{type}") | issues]
    end
  end

  def expect_optional_type(issues, path, map, field, type) do
    case Map.get(map, field) do
      nil ->
        issues

      :null ->
        issues

      value ->
        if matches_type?(value, type) do
          issues
        else
          [error("#{path}.#{field}", "must be a #{type}") | issues]
        end
    end
  end

  def expect_optional_list(issues, path, map, field) do
    case Map.get(map, field) do
      nil -> issues
      value when is_list(value) -> issues
      _value -> [error("#{path}.#{field}", "must be a list") | issues]
    end
  end

  defp matches_type?(value, :map), do: is_map(value)
  defp matches_type?(value, :list), do: is_list(value)
  defp matches_type?(value, :binary), do: is_binary(value)
  defp matches_type?(value, :boolean), do: is_boolean(value)
  defp matches_type?(value, :integer), do: is_integer(value)

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
