defmodule OrbitalDynamics.Units do
  @moduledoc """
  Executable unit policy for public structs, manifests, and artifacts.

  OrbitalDynamics intentionally uses explicit field suffixes instead of a full
  unit algebra system. This module centralizes the canonical unit labels so
  callers and contract tests can check that a field name means the same thing
  across structs, manifests, and JSON artifacts.
  """

  @field_units %{
    "altitude_km" => "kilometer",
    "apogee_altitude_km" => "kilometer",
    "apogee_radius_km" => "kilometer",
    "area_m2" => "square_meter",
    "argument_of_latitude_deg" => "degree",
    "argument_of_periapsis_deg" => "degree",
    "capacity_fraction" => "dimensionless_fraction",
    "delta_v_km_s" => "kilometer_per_second",
    "delta_v_magnitude_km_s" => "kilometer_per_second",
    "drag_coefficient" => "dimensionless",
    "dry_mass_kg" => "kilogram",
    "duration_s" => "second",
    "eccentricity" => "dimensionless",
    "ends_at_s" => "second",
    "epoch_s" => "second",
    "equatorial_radius_km" => "kilometer",
    "event_time_tolerance_s" => "second",
    "final_epoch_s" => "second",
    "final_position_km" => "kilometer",
    "final_radius_km" => "kilometer",
    "final_speed_km_s" => "kilometer_per_second",
    "final_velocity_km_s" => "kilometer_per_second",
    "inclination_deg" => "degree",
    "j2" => "dimensionless",
    "latitude_deg" => "degree",
    "longitude_deg" => "degree",
    "longitude_of_periapsis_deg" => "degree",
    "max_elevation_deg" => "degree",
    "max_sample_step_s" => "second",
    "max_step_s" => "second",
    "mu_km3_s2" => "kilometer_cubed_per_second_squared",
    "output_step_s" => "second",
    "perigee_altitude_km" => "kilometer",
    "perigee_radius_km" => "kilometer",
    "position_km" => "kilometer",
    "position_sigma_km" => "kilometer",
    "priority" => "dimensionless",
    "propellant_mass_kg" => "kilogram",
    "raan_deg" => "degree",
    "radius_km" => "kilometer",
    "score" => "dimensionless",
    "seconds_since_j2000" => "second",
    "semi_latus_rectum_km" => "kilometer",
    "semi_major_axis_km" => "kilometer",
    "specific_angular_momentum_km2_s" => "kilometer_squared_per_second",
    "specific_energy_km2_s2" => "kilometer_squared_per_second_squared",
    "starts_at_s" => "second",
    "time_scale" => "time_scale_label",
    "true_anomaly_deg" => "degree",
    "true_longitude_deg" => "degree",
    "velocity_km_s" => "kilometer_per_second",
    "velocity_sigma_km_s" => "kilometer_per_second"
  }

  @doc """
  Returns the canonical unit policy.
  """
  def policy do
    %{
      "schema_contract" => "units_policy.v1",
      "policy" => "explicit_suffix_units_no_implicit_conversion",
      "coordinate_policy" =>
        "vectors are Cartesian tuples or arrays; their frame is carried separately",
      "frame_policy" =>
        "frames are metadata labels and are not transformed unless an API explicitly says so",
      "time_policy" =>
        "epochs are seconds since J2000 in the declared scale; time scales are not converted",
      "canonical_units" => %{
        "distance" => "kilometer",
        "velocity" => "kilometer_per_second",
        "time" => "second",
        "mass" => "kilogram",
        "area" => "square_meter",
        "angle" => "degree",
        "gravitational_parameter" => "kilometer_cubed_per_second_squared"
      },
      "field_units" => @field_units
    }
  end

  @doc """
  Returns the canonical unit for a known field name.
  """
  def unit_for(field) when is_atom(field), do: field |> Atom.to_string() |> unit_for()

  def unit_for(field) when is_binary(field) do
    case Map.fetch(@field_units, field) do
      {:ok, unit} -> {:ok, unit}
      :error -> {:error, {:unknown_unit_field, field}}
    end
  end

  def unit_for(field), do: {:error, {:unknown_unit_field, field}}

  @doc """
  Returns the canonical unit for a known field name, raising otherwise.
  """
  def unit_for!(field) do
    case unit_for(field) do
      {:ok, unit} -> unit
      {:error, reason} -> raise ArgumentError, "unknown unit field: #{inspect(reason)}"
    end
  end

  @doc """
  Checks whether a field is declared with the expected canonical unit label.
  """
  def compatible?(field, expected_unit) do
    case unit_for(field) do
      {:ok, ^expected_unit} -> true
      _other -> false
    end
  end
end
