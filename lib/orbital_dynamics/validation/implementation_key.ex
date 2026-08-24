defmodule OrbitalDynamics.Validation.ImplementationKey do
  @moduledoc false

  alias OrbitalDynamics.Schema.StableIdValidation

  def pattern, do: StableIdValidation.pattern()

  def valid?(value), do: StableIdValidation.valid?(value)

  def normalize(module) when is_atom(module) do
    module
    |> Atom.to_string()
    |> String.trim_leading("Elixir.")
    |> normalize()
  end

  def normalize(value) when is_binary(value) do
    if valid?(value), do: {:ok, value}, else: :error
  end

  def normalize(_value), do: :error
end
