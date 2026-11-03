defmodule OrbitalDynamics.MissionAnalysis.Resource.Battery do
  @moduledoc """
  Ideal battery energy with explicit mode/phase loads and a replaceable generation provider.
  Power is watts, stored energy watt-hours, time seconds. Surplus is charged with
  declared efficiency; deficits are supplied with declared discharge efficiency.
  Capacity clips excess generation; unmet demand and curtailed surplus are bus-side watt-hours. Stored energy is battery-side, never negative
  storage. Source geometry is owned by the configured generation provider;
  battery thermal, voltage and degradation dynamics are not modeled.
  """
  @behaviour OrbitalDynamics.MissionAnalysis.Resource.Model
  alias OrbitalDynamics.MissionAnalysis.{Input, Models.SurfaceSupport}
  alias OrbitalDynamics.MissionAnalysis.Path.Result

  @phases ~w(activity brake hold slew_accelerate slew_cruise slew_decelerate settle ramp_to_tracking)

  defmodule Session do
    @moduledoc false
    @enforce_keys [:configuration, :generation_module, :generation_session]
    defstruct @enforce_keys
  end

  def prepare(asset, context, c) do
    unless is_map(c["generation"]),
      do: raise(ArgumentError, "explicit generation configuration required")

    provider =
      case c["generation"]["kind"] do
        kind when kind in ["constant", "piecewise_constant"] ->
          OrbitalDynamics.MissionAnalysis.Resource.Generation.Declared

        "solar_array" ->
          OrbitalDynamics.MissionAnalysis.Resource.Generation.SolarArray

        _ ->
          raise ArgumentError, "unsupported battery generation kind"
      end

    prepare_with_generation(asset, context, c, {provider, c["generation"]})
  end

  @doc "Prepare a battery with an explicitly trusted Generation provider; no module is loaded from JSON."
  def prepare_with_generation(asset, context, c, {provider, provider_config}) do
    SurfaceSupport.fields!(
      c,
      ~w(initial_wh capacity_wh reserve_wh charge_efficiency discharge_efficiency phase_load_w generation),
      "battery"
    )

    capacity =
      if c["capacity_wh"] == :null,
        do: 1.0e15,
        else: Input.positive!(c["capacity_wh"], "battery capacity")

    unless c["initial_wh"] == :null,
      do: Input.number!(c["initial_wh"], "initial battery energy", 0, capacity)

    unless c["reserve_wh"] == :null,
      do: Input.number!(c["reserve_wh"], "battery reserve", 0, capacity)

    for key <- ~w(charge_efficiency discharge_efficiency) do
      unless c[key] == :null, do: Input.number!(c[key], key, 1.0e-12, 1)
    end

    unless is_map(c["phase_load_w"]) and Enum.all?(Map.keys(c["phase_load_w"]), &(&1 in @phases)),
      do: raise(ArgumentError, "invalid battery motion phase loads")

    Enum.each(c["phase_load_w"], fn {_, w} -> power!(w) end)

    unless Code.ensure_loaded?(provider) and
             Enum.all?([prepare: 3, boundaries: 1, evaluate: 2], fn {f, a} ->
               function_exported?(provider, f, a)
             end),
           do: raise(ArgumentError, "generation provider must implement Resource.Generation")

    with {:ok, generation_session, assumptions} when is_map(assumptions) <-
           provider.prepare(asset, context, provider_config) do
      assumptions =
        OrbitalDynamics.Schema.JsonSafety.normalize_input!(assumptions, "generation assumptions")

      {:ok,
       %Session{
         configuration: c,
         generation_module: provider,
         generation_session: generation_session
       },
       Map.merge(c, %{
         "model" => "ideal_energy_balance_v1",
         "mode_load_field" => "power_load_w",
         "state_units" => %{
           "energy_wh" => "battery-side Wh",
           "unserved_wh" => "bus-side Wh",
           "curtailed_wh" => "bus-side Wh"
         },
         "generation_provider" => Atom.to_string(provider),
         "generation_assumptions" => assumptions,
         "generation_scope" => "bus-side source power from the captured generation provider",
         "integration" =>
           "frozen midpoint source power per interval, with declared source boundaries; geometric crossings may remain between samples"
       })}
    else
      {:error, reason} ->
        {:error, reason}

      _ ->
        raise ArgumentError,
              "invalid generation preparation result; JSON-safe assumptions map required"
    end
  end

  def initial(%Session{configuration: c}),
    do: %{"energy_wh" => c["initial_wh"], "unserved_wh" => 0.0, "curtailed_wh" => 0.0}

  def search_boundaries(%Session{} = s, source) do
    if function_exported?(s.generation_module, :search_boundaries, 2),
      do: s.generation_module.search_boundaries(s.generation_session, source),
      else: {:ok, [], :null}
  end

  def boundaries(%Session{} = s), do: s.generation_module.boundaries(s.generation_session)

  def step(state, input, dt, %Session{} = session) do
    c = session.configuration
    load = get_in(input, [:mode, "parameters", "power_load_w"])
    phase = c["phase_load_w"][input.phase]

    cond do
      Enum.any?(
        ~w(capacity_wh initial_wh reserve_wh charge_efficiency discharge_efficiency),
        &(c[&1] == :null)
      ) ->
        {:ok, state,
         Result.new!(
           [
             %{
               "id" => "battery_parameters",
               "status" => "unknown",
               "reason" => "battery_parameter_unknown"
             }
           ],
           %{}
         )}

      dt == 0 ->
        result(state, state["energy_wh"], state["energy_wh"], %{}, c)

      load in [nil, :null] or phase in [nil, :null] ->
        {:ok, state,
         Result.new!(
           [
             %{
               "id" => "battery_inputs",
               "status" => "unknown",
               "reason" => "mode_phase_or_generation_power_unknown"
             }
           ],
           %{}
         )}

      true ->
        power!(load)

        case session.generation_module.evaluate(input, session.generation_session) do
          {:ok, generation, metrics} when is_map(metrics) ->
            Input.number!(generation, "generation bus power", 0, 1.0e12)
            balance(state, load, phase, generation, metrics, dt, c)

          {:unknown, reason} ->
            {:ok, state,
             Result.new!(
               [
                 %{
                   "id" => "generation_inputs",
                   "status" => "unknown",
                   "reason" => inspect(reason)
                 }
               ],
               %{}
             )}

          {:error, reason} ->
            {:error, reason}

          _ ->
            raise ArgumentError, "invalid generation provider result"
        end
    end
  end

  defp balance(state, load, phase, generation, generation_metrics, dt, c) do
    net = generation - load - phase

    battery_power =
      if net >= 0, do: net * c["charge_efficiency"], else: net / c["discharge_efficiency"]

    raw = state["energy_wh"] + battery_power * dt / 3600
    energy = max(0.0, min(c["capacity_wh"], raw))

    next = %{
      "energy_wh" => energy,
      "unserved_wh" => state["unserved_wh"] + max(0.0, -raw) * c["discharge_efficiency"],
      "curtailed_wh" =>
        state["curtailed_wh"] + max(0.0, raw - c["capacity_wh"]) / c["charge_efficiency"]
    }

    crossing =
      cond do
        state["energy_wh"] < c["reserve_wh"] ->
          0.0

        raw < c["reserve_wh"] ->
          (state["energy_wh"] - c["reserve_wh"]) * 3600 / -battery_power

        true ->
          :null
      end

    result(
      next,
      min(state["energy_wh"], energy),
      min(state["energy_wh"], raw),
      %{
        "load_w" => load + phase,
        "generation_w" => generation,
        "generation_evidence" => generation_metrics,
        "battery_power_w" => battery_power,
        "reserve_crossing_offset_s" => crossing
      },
      c
    )
  end

  defp result(next, lowest, supply, metrics, c) do
    checks =
      for {id, margin} <- [
            {"battery_reserve", lowest - c["reserve_wh"]},
            {"battery_energy_supply", supply}
          ] do
        %{
          "id" => id,
          "status" => if(margin >= 0, do: "supported", else: "violated"),
          "margin" => margin,
          "margin_unit" => "Wh"
        }
      end

    {:ok, next, Result.new!(checks, metrics)}
  end

  defp power!(:null), do: :null
  defp power!(w), do: Input.number!(w, "battery bus power", 0, 1.0e12)
end
