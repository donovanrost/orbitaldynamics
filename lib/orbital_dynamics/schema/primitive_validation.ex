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

  def expect_number(issues, path, map, field) do
    if is_number(Map.get(map, field)) do
      issues
    else
      [error("#{path}.#{field}", "must be a number") | issues]
    end
  end

  def expect_optional_number(issues, path, map, field) do
    case Map.get(map, field) do
      nil -> issues
      :null -> issues
      value when is_number(value) -> issues
      _value -> [error("#{path}.#{field}", "must be a number") | issues]
    end
  end

  def expect_optional_number_or_string(issues, path, map, field) do
    case Map.get(map, field) do
      nil -> issues
      :null -> issues
      value when is_number(value) or is_binary(value) -> issues
      _value -> [error("#{path}.#{field}", "must be a number or string") | issues]
    end
  end

  def expect_optional_non_negative_number(issues, path, map, field) do
    case Map.get(map, field) do
      nil ->
        issues

      :null ->
        issues

      value when is_number(value) and value >= 0.0 ->
        issues

      value when is_number(value) ->
        [error("#{path}.#{field}", "must be non-negative") | issues]

      _value ->
        [error("#{path}.#{field}", "must be a number") | issues]
    end
  end

  def expect_optional_integer(issues, path, map, field) do
    case Map.get(map, field) do
      nil -> issues
      :null -> issues
      value when is_integer(value) -> issues
      _value -> [error("#{path}.#{field}", "must be an integer") | issues]
    end
  end

  def expect_probability_range(issues, path, map, field) do
    case Map.get(map, field) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 ->
        issues

      value when is_number(value) ->
        [error("#{path}.#{field}", "must be between 0.0 and 1.0") | issues]

      _value ->
        issues
    end
  end

  def expect_optional_probability(issues, path, map, field) do
    case Map.get(map, field) do
      nil ->
        issues

      :null ->
        issues

      value when is_number(value) and value >= 0.0 and value <= 1.0 ->
        issues

      value when is_number(value) ->
        [error("#{path}.#{field}", "must be between 0.0 and 1.0") | issues]

      _value ->
        [error("#{path}.#{field}", "must be a number") | issues]
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
