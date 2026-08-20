defmodule OrbitalDynamics.Spacecraft do
  @moduledoc """
  Spacecraft properties attached to a mission scenario.

  The atmospheric-drag evaluator and opt-in scalar two-body-drag and J2-drag
  propagators consume mass and ballistic properties. Other propagators leave
  them as metadata.
  """

  @enforce_keys [:id, :dry_mass_kg]
  defstruct [:id, :dry_mass_kg, propellant_mass_kg: 0.0, area_m2: nil, drag_coefficient: nil]

  @type t :: %__MODULE__{
          id: atom() | String.t(),
          dry_mass_kg: number(),
          propellant_mass_kg: number(),
          area_m2: number() | nil,
          drag_coefficient: number() | nil
        }

  @doc """
  Creates spacecraft metadata with explicit SI mass and area units.
  """
  def new!(id, dry_mass_kg, opts \\ []) do
    propellant_mass_kg = Keyword.get(opts, :propellant_mass_kg, 0.0)
    area_m2 = Keyword.get(opts, :area_m2)
    drag_coefficient = Keyword.get(opts, :drag_coefficient)

    cond do
      id in [nil, ""] ->
        raise ArgumentError, "spacecraft id is required"

      not non_negative_number?(dry_mass_kg) ->
        raise ArgumentError, "dry_mass_kg must be non-negative"

      not non_negative_number?(propellant_mass_kg) ->
        raise ArgumentError, "propellant_mass_kg must be non-negative"

      not nil_or_non_negative?(area_m2) ->
        raise ArgumentError, "area_m2 must be nil or non-negative"

      not nil_or_non_negative?(drag_coefficient) ->
        raise ArgumentError, "drag_coefficient must be nil or non-negative"

      true ->
        %__MODULE__{
          id: id,
          dry_mass_kg: dry_mass_kg,
          propellant_mass_kg: propellant_mass_kg,
          area_m2: area_m2,
          drag_coefficient: drag_coefficient
        }
    end
  end

  defp nil_or_non_negative?(nil), do: true
  defp nil_or_non_negative?(value), do: non_negative_number?(value)

  defp non_negative_number?(value), do: (is_integer(value) or is_float(value)) and value >= 0
end
