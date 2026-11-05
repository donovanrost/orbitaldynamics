defmodule OrbitalDynamics.MissionAnalysis.Resource.Thermal do
  @moduledoc "One isothermal node with declared heat input and linear effective rejection to a fixed sink. Analytic interval evolution; no radiation/view-factor solver."
  @behaviour OrbitalDynamics.MissionAnalysis.Resource.Model
  alias OrbitalDynamics.MissionAnalysis.{Input, Models.SurfaceSupport}
  alias OrbitalDynamics.MissionAnalysis.Path.Result

  @phases ~w(activity brake hold continuation slew_accelerate slew_cruise slew_decelerate settle ramp_to_tracking)

  def prepare(_asset, _context, c) do
    SurfaceSupport.fields!(
      c,
      ~w(initial_temperature_k heat_capacity_j_k sink_temperature_k conductance_w_k minimum_temperature_k maximum_temperature_k phase_heat_w),
      "thermal node"
    )

    for key <-
          ~w(initial_temperature_k heat_capacity_j_k sink_temperature_k minimum_temperature_k maximum_temperature_k) do
      unless c[key] == :null, do: Input.number!(c[key], key, 0.000001, 1.0e12)
    end

    unless c["conductance_w_k"] == :null,
      do: Input.number!(c["conductance_w_k"], "thermal conductance", 0, 1.0e12)

    if is_number(c["minimum_temperature_k"]) and is_number(c["maximum_temperature_k"]) and
         c["minimum_temperature_k"] > c["maximum_temperature_k"],
       do: raise(ArgumentError, "thermal limits must be ordered")

    unless is_map(c["phase_heat_w"]) and Enum.all?(Map.keys(c["phase_heat_w"]), &(&1 in @phases)),
      do: raise(ArgumentError, "invalid thermal phase heat")

    for {_, q} <- c["phase_heat_w"], q != :null, do: Input.number!(q, "phase heat", 0, 1.0e12)

    {:ok, c,
     Map.merge(c, %{
       "model" => "linear_lumped_thermal_v1",
       "integration" => "analytic_piecewise_constant_inputs",
       "state_unit" => "K",
       "mode_fields" => ~w(thermal_heat_w thermal_rejection_w_k),
       "limits" => [
         "one isothermal node; fixed effective sink",
         "linear effective rejection is not a full radiative thermal model",
         "heat is declared independently of electrical power; no automatic conversion"
       ]
     })}
  end

  def initial(c), do: %{"temperature_k" => c["initial_temperature_k"]}
  def boundaries(_), do: []

  def step(state, input, dt, c) do
    t = state["temperature_k"]
    q = get_in(input, [:mode, "parameters", "thermal_heat_w"])
    extra = get_in(input, [:mode, "parameters", "thermal_rejection_w_k"])
    phase = c["phase_heat_w"][input.phase]

    cond do
      Enum.any?(
        ~w(initial_temperature_k heat_capacity_j_k sink_temperature_k conductance_w_k minimum_temperature_k maximum_temperature_k),
        &(c[&1] == :null)
      ) or not is_number(t) ->
        unknown(state, "thermal_parameter_unknown")

      dt == 0 ->
        result(state, t, t, %{}, c)

      q in [nil, :null] or extra in [nil, :null] or phase in [nil, :null] ->
        unknown(state, "thermal_mode_or_phase_unknown")

      true ->
        Input.number!(dt, "thermal interval", 0, 1.0e12)

        q =
          Input.number!(q, "mode heat", 0, 1.0e12) + Input.number!(phase, "phase heat", 0, 1.0e12)

        k = c["conductance_w_k"] + Input.number!(extra, "mode rejection", 0, 1.0e12)
        capacity = c["heat_capacity_j_k"]
        sink = c["sink_temperature_k"]
        x = k * dt / capacity

        next =
          cond do
            k == 0 ->
              t + q * dt / capacity

            x < 1.0e-4 ->
              phi = 1 - x / 2 + x * x / 6 - x * x * x / 24 + x * x * x * x / 120
              t + (q - k * (t - sink)) * dt / capacity * phi

            true ->
              decay = :math.exp(-x)
              t * decay + (sink + q / k) * (1 - decay)
          end

        delta = next - t

        metrics = %{
          "heat_input_w" => q,
          "conductance_w_k" => k,
          "minimum_temperature_k" => min(t, next),
          "maximum_temperature_k" => max(t, next),
          "stored_heat_change_j" => capacity * delta,
          "integrated_heat_input_j" => q * dt,
          "integrated_rejected_heat_j" => q * dt - capacity * delta
        }

        result(%{"temperature_k" => next}, min(t, next), max(t, next), metrics, c)
    end
  end

  defp result(next, low, high, metrics, c) do
    checks =
      for {id, margin} <- [
            {"thermal_cold_limit", low - c["minimum_temperature_k"]},
            {"thermal_hot_limit", c["maximum_temperature_k"] - high}
          ],
          do: %{
            "id" => id,
            "status" => if(margin >= 0, do: "supported", else: "violated"),
            "margin" => margin,
            "margin_unit" => "K"
          }

    {:ok, next, Result.new!(checks, metrics)}
  end

  defp unknown(state, reason),
    do:
      {:ok, state,
       Result.new!([%{"id" => "thermal_inputs", "status" => "unknown", "reason" => reason}], %{})}
end
