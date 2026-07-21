defmodule OrbitalDynamics.Benchmark.ScenarioFixture do
  @moduledoc """
  Deterministic scenario generation for benchmark studies.

  The initial fixture family is intentionally narrow: circular LEO states around
  Earth with stable identifiers. This gives scalar, concurrent, and future
  tensor backends the same workload shape.
  """

  alias OrbitalDynamics.{CentralBody, Epoch, Frame, Scenario, Spacecraft, StateVector}

  @default_count 100
  @default_radius_km 7_000.0
  @default_duration_s 3_600.0
  @default_output_step_s 60.0
  @default_mass_kg 250.0
  @default_propellant_mass_kg 0.0

  @doc """
  Builds deterministic circular LEO scenarios.
  """
  def circular_leo(opts \\ []) do
    count = Keyword.get(opts, :count, @default_count)
    radius_km = Keyword.get(opts, :radius_km, @default_radius_km)
    duration_s = Keyword.get(opts, :duration_s, @default_duration_s)
    output_step_s = Keyword.get(opts, :output_step_s, @default_output_step_s)
    dry_mass_kg = Keyword.get(opts, :dry_mass_kg, @default_mass_kg)
    propellant_mass_kg = Keyword.get(opts, :propellant_mass_kg, @default_propellant_mass_kg)
    area_m2 = Keyword.get(opts, :area_m2)
    drag_coefficient = Keyword.get(opts, :drag_coefficient)
    id_prefix = Keyword.get(opts, :id_prefix, "bench_leo")
    epoch = Keyword.get(opts, :epoch, Epoch.new!(0.0, :tdb))
    frame = Keyword.get(opts, :frame, Frame.earth_inertial_j2000())
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())

    validate!(
      count,
      radius_km,
      duration_s,
      output_step_s,
      dry_mass_kg,
      propellant_mass_kg,
      area_m2,
      drag_coefficient,
      id_prefix
    )

    velocity_km_s = :math.sqrt(central_body.mu_km3_s2 / radius_km)

    for index <- 1..count do
      phase_rad = 2.0 * :math.pi() * (index - 1) / count

      position_km = {
        radius_km * :math.cos(phase_rad),
        radius_km * :math.sin(phase_rad),
        0.0
      }

      velocity_km_s_tuple = {
        -velocity_km_s * :math.sin(phase_rad),
        velocity_km_s * :math.cos(phase_rad),
        0.0
      }

      scenario_id = :"#{id_prefix}_#{index}"

      spacecraft =
        Spacecraft.new!(:"#{id_prefix}_sat_#{index}", dry_mass_kg,
          propellant_mass_kg: propellant_mass_kg,
          area_m2: area_m2,
          drag_coefficient: drag_coefficient
        )

      state = StateVector.new!(position_km, velocity_km_s_tuple, epoch, frame)

      Scenario.new!(scenario_id, spacecraft, state,
        duration_s: duration_s,
        output_step_s: output_step_s,
        central_body: central_body
      )
    end
  end

  defp validate!(
         count,
         radius_km,
         duration_s,
         output_step_s,
         dry_mass_kg,
         propellant_mass_kg,
         area_m2,
         drag_coefficient,
         id_prefix
       ) do
    cond do
      not is_integer(count) or count <= 0 ->
        raise ArgumentError, "count must be a positive integer"

      not positive_number?(radius_km) ->
        raise ArgumentError, "radius_km must be positive"

      not non_negative_number?(duration_s) ->
        raise ArgumentError, "duration_s must be non-negative"

      not positive_number?(output_step_s) ->
        raise ArgumentError, "output_step_s must be positive"

      not non_negative_number?(dry_mass_kg) ->
        raise ArgumentError, "dry_mass_kg must be non-negative"

      not non_negative_number?(propellant_mass_kg) ->
        raise ArgumentError, "propellant_mass_kg must be non-negative"

      not nil_or_non_negative?(area_m2) ->
        raise ArgumentError, "area_m2 must be nil or non-negative"

      not nil_or_non_negative?(drag_coefficient) ->
        raise ArgumentError, "drag_coefficient must be nil or non-negative"

      not is_binary(id_prefix) or id_prefix == "" ->
        raise ArgumentError, "id_prefix must be a non-empty string"

      true ->
        :ok
    end
  end

  defp positive_number?(value), do: (is_integer(value) or is_float(value)) and value > 0
  defp non_negative_number?(value), do: (is_integer(value) or is_float(value)) and value >= 0
  defp nil_or_non_negative?(nil), do: true
  defp nil_or_non_negative?(value), do: non_negative_number?(value)
end
