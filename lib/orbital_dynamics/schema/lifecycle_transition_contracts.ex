defmodule OrbitalDynamics.Schema.LifecycleTransitionContracts do
  @moduledoc false

  @transition_types ["added", "removed", "changed"]

  def validate_optional(issues, path, map, field, callbacks)
      when is_map(map) and is_list(callbacks) do
    case Map.get(map, field) do
      %{} = transition -> validate(issues, "#{path}.#{field}", transition, callbacks)
      _value -> issues
    end
  end

  def validate(issues, path, transition, callbacks) when is_list(callbacks) do
    issues
    |> expect_optional_type(callbacks, path, transition, "field", :binary)
    |> expect_optional_one_of(callbacks, path, transition, "transition_type", @transition_types)
    |> expect_optional_type(callbacks, path, transition, "from", :binary)
    |> expect_optional_type(callbacks, path, transition, "to", :binary)
    |> expect_optional_type(callbacks, path, transition, "from_category", :binary)
    |> expect_optional_type(callbacks, path, transition, "to_category", :binary)
    |> expect_optional_type(callbacks, path, transition, "transition_category", :binary)
    |> expect_optional_type(callbacks, path, transition, "requires_operator_review", :boolean)
    |> expect_optional_type(callbacks, path, transition, "operator_action_reason", :binary)
  end

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [
        issues,
        path,
        map,
        field,
        type
      ])

  defp expect_optional_one_of(issues, callbacks, path, map, field, allowed),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
