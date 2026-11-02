defmodule OrbitalDynamics.MissionAnalysis.Resource.Battery do
  @moduledoc """
  Ideal battery energy with explicit mode/phase loads and exogenous charging.
  Power is watts, stored energy watt-hours, time seconds. Surplus is charged with
  declared efficiency; deficits are supplied with declared discharge efficiency.
  Capacity clips excess generation; unmet demand and curtailed surplus are bus-side watt-hours. Stored energy is battery-side, never negative
  stored energy. No solar-array, eclipse, thermal, voltage or degradation model is
  inferred from the supplied charging power.
  """
  @behaviour OrbitalDynamics.MissionAnalysis.Resource.Model
  alias OrbitalDynamics.MissionAnalysis.{Input, Models.SurfaceSupport}
  alias OrbitalDynamics.MissionAnalysis.Path.Result

  @phases ~w(activity brake hold slew_accelerate slew_cruise slew_decelerate settle ramp_to_tracking)

  def prepare(_asset, _context, c) do
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
    generation!(c["generation"])

    {:ok, c,
     Map.merge(c, %{
       "model" => "ideal_energy_balance_v1",
       "mode_load_field" => "power_load_w",
       "state_units" => %{
         "energy_wh" => "battery-side Wh",
         "unserved_wh" => "bus-side Wh",
         "curtailed_wh" => "bus-side Wh"
       },
       "generation_scope" => "declared battery-bus power, not inferred solar exposure",
       "integration" =>
         "constant midpoint power per interval with exact declared generation breakpoints"
     })}
  end

  def initial(c),
    do: %{"energy_wh" => c["initial_wh"], "unserved_wh" => 0.0, "curtailed_wh" => 0.0}

  def boundaries(c) do
    if c["generation"]["kind"] == "piecewise_constant",
      do: Enum.flat_map(c["generation"]["intervals"], &[&1["starts_at_s"], &1["ends_at_s"]]),
      else: []
  end

  def step(state, input, dt, c) do
    load = get_in(input, [:mode, "parameters", "power_load_w"])
    phase = c["phase_load_w"][input.phase]
    generation = generation_at(c["generation"], input.epoch_s)

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

      load in [nil, :null] or phase in [nil, :null] or generation == :unknown ->
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
            "battery_power_w" => battery_power,
            "reserve_crossing_offset_s" => crossing
          },
          c
        )
    end
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

  defp generation!(%{"kind" => "constant", "power_w" => w} = g) when map_size(g) == 2,
    do: power!(w)

  defp generation!(%{"kind" => "piecewise_constant", "intervals" => intervals} = g)
       when map_size(g) == 2 do
    unless is_list(intervals) and length(intervals) in 1..1000,
      do: raise(ArgumentError, "1..1000 declared charging intervals required")

    Enum.reduce(intervals, nil, fn i, previous ->
      SurfaceSupport.fields!(i, ~w(starts_at_s ends_at_s power_w), "charging interval")
      a = Input.number!(i["starts_at_s"], "charging start", -1.0e12, 1.0e12)
      b = Input.number!(i["ends_at_s"], "charging end", -1.0e12, 1.0e12)

      unless b > a and (previous == nil or a >= previous),
        do: raise(ArgumentError, "charging intervals must be ordered and nonoverlapping")

      power!(i["power_w"])
      b
    end)
  end

  defp generation!(_),
    do: raise(ArgumentError, "explicit constant or piecewise_constant charging required")

  defp generation_at(%{"kind" => "constant", "power_w" => :null}, _), do: :unknown
  defp generation_at(%{"kind" => "constant", "power_w" => w}, _), do: w

  defp generation_at(g, t) do
    case Enum.find(g["intervals"], &(t >= &1["starts_at_s"] and t < &1["ends_at_s"])) do
      nil -> :unknown
      %{"power_w" => :null} -> :unknown
      i -> i["power_w"]
    end
  end
end
