defmodule OrbitalDynamics.SubsystemModel do
  @moduledoc """
  Planning-grade subsystem model capability records.

  These records describe the subsystem assumptions that resource projection can
  cite. They are declarative model contracts, not executable subsystem-state
  propagators.
  """

  @battery_energy_storage_id "subsystem.power.battery.energy_storage.planning_grade"
  @validation_levels ~w(analysis artifact_contract assumption_declared educational validated)

  @doc """
  Returns built-in subsystem model capability records.
  """
  def capabilities do
    [
      battery_energy_storage()
    ]
  end

  @doc """
  Describes the planning-grade battery energy-storage model used by resource flow evidence.
  """
  def battery_energy_storage(opts \\ []) do
    %{
      "id" => @battery_energy_storage_id,
      "schema_contract" => "subsystem_model_capability.v1",
      "subsystem" => "power",
      "model" => "battery_energy_storage_planning_grade",
      "source" => Keyword.get(opts, :source, "resource_projection_activity_energy_hints"),
      "fidelity_tier" => "planning_grade",
      "validation_level" => "assumption_declared",
      "applicability" => %{
        "resource_dimensions" => ["battery"],
        "activity_effect_fields" => [
          "energy_consumed_wh",
          "energy_generated_wh",
          "battery_energy_used_wh",
          "battery_energy_generated_wh"
        ],
        "time_span" => "selected_activity_sequence"
      },
      "state_variables" => [
        "capacity_wh",
        "energy_remaining_wh",
        "state_of_charge_fraction"
      ],
      "activity_effects" => %{
        "consumption" => "subtract declared activity energy from remaining capacity",
        "generation" => "add declared activity energy generation to remaining capacity"
      },
      "parameters" => %{
        "capacity_wh" => Keyword.get(opts, :capacity_wh, 1000.0),
        "min_state_of_charge_fraction" => Keyword.get(opts, :min_state_of_charge_fraction, 0.2),
        "max_state_of_charge_fraction" => Keyword.get(opts, :max_state_of_charge_fraction, 1.0),
        "round_trip_efficiency" => Keyword.get(opts, :round_trip_efficiency, 1.0)
      },
      "known_limits" => known_limits()
    }
  end

  @doc """
  Validates the minimal subsystem model capability shape.
  """
  def validate_capability(%{} = record) do
    required = [
      "id",
      "schema_contract",
      "subsystem",
      "model",
      "source",
      "fidelity_tier",
      "validation_level",
      "applicability",
      "state_variables",
      "activity_effects",
      "parameters",
      "known_limits"
    ]

    missing = Enum.reject(required, &Map.has_key?(record, &1))

    cond do
      missing != [] ->
        {:error, {:missing_keys, missing}}

      record["schema_contract"] != "subsystem_model_capability.v1" ->
        {:error, {:invalid_field, "schema_contract"}}

      not stable_id?(record["id"]) ->
        {:error, {:invalid_field, "id"}}

      not is_binary(record["subsystem"]) ->
        {:error, {:invalid_field, "subsystem"}}

      not is_binary(record["model"]) ->
        {:error, {:invalid_field, "model"}}

      not is_binary(record["source"]) ->
        {:error, {:invalid_field, "source"}}

      not is_binary(record["fidelity_tier"]) ->
        {:error, {:invalid_field, "fidelity_tier"}}

      record["validation_level"] not in @validation_levels ->
        {:error, {:invalid_field, "validation_level"}}

      not is_map(record["applicability"]) ->
        {:error, {:invalid_field, "applicability"}}

      not is_list(record["state_variables"]) ->
        {:error, {:invalid_field, "state_variables"}}

      not string_list?(record["state_variables"]) ->
        {:error, {:invalid_field, "state_variables"}}

      not is_map(record["activity_effects"]) ->
        {:error, {:invalid_field, "activity_effects"}}

      not is_map(record["parameters"]) ->
        {:error, {:invalid_field, "parameters"}}

      not is_list(record["known_limits"]) ->
        {:error, {:invalid_field, "known_limits"}}

      not string_list?(record["known_limits"]) ->
        {:error, {:invalid_field, "known_limits"}}

      known_limits_drift?(record) ->
        {:error, {:invalid_field, "known_limits"}}

      true ->
        :ok
    end
  end

  def validate_capability(_record), do: {:error, :invalid_record}

  defp known_limits do
    [
      "selected_activity_sequence_only",
      "declared_energy_hints_only",
      "no_continuous_power_bus_or_thermal_coupling",
      "no_battery_degradation_or_charge_dynamics"
    ]
  end

  defp known_limits_drift?(%{"id" => @battery_energy_storage_id, "known_limits" => limits}) do
    limits != known_limits()
  end

  defp known_limits_drift?(_record), do: false

  defp stable_id?(value) when is_binary(value) do
    Regex.match?(~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/, value)
  end

  defp stable_id?(_value), do: false

  defp string_list?(values), do: Enum.all?(values, &is_binary/1)
end
