defmodule OrbitalDynamics.Schema.LifecycleTransitionContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  @transition_types ["added", "removed", "changed"]

  def validate_optional(issues, path, map, field) when is_map(map) do
    case Map.get(map, field) do
      %{} = transition -> validate(issues, "#{path}.#{field}", transition)
      _value -> issues
    end
  end

  def validate(issues, path, transition) do
    issues
    |> PrimitiveValidation.expect_optional_type(path, transition, "field", :binary)
    |> PrimitiveValidation.expect_optional_one_of(
      path,
      transition,
      "transition_type",
      @transition_types
    )
    |> PrimitiveValidation.expect_optional_type(path, transition, "from", :binary)
    |> PrimitiveValidation.expect_optional_type(path, transition, "to", :binary)
    |> PrimitiveValidation.expect_optional_type(path, transition, "from_category", :binary)
    |> PrimitiveValidation.expect_optional_type(path, transition, "to_category", :binary)
    |> PrimitiveValidation.expect_optional_type(
      path,
      transition,
      "transition_category",
      :binary
    )
    |> PrimitiveValidation.expect_optional_type(
      path,
      transition,
      "requires_operator_review",
      :boolean
    )
    |> PrimitiveValidation.expect_optional_type(
      path,
      transition,
      "operator_action_reason",
      :binary
    )
  end
end
