defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.Battery do
  @moduledoc "Independent exact piecewise ideal-bus energy accounting on saved phase boundaries."
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Checker, as: C

  def integrate(c, segments) do
    Enum.reduce(segments, initial(c), fn s, state -> advance(state, c, s.load, s.b - s.a) end)
  end

  def samples(level, c, segments, path) do
    first = hd(segments).a
    stop = List.last(segments).b
    samples = level["samples"] || []

    if samples == [] do
      [C.issue("battery_samples_missing", path, "battery samples required")]
    else
      {_, last, issues} =
        Enum.with_index(samples)
        |> Enum.reduce({initial(c), first, []}, fn {sample, index}, {state, last, issues} ->
          a = sample["starts_at_s"]
          b = sample["ends_at_s"]
          segment = Enum.find(segments, &(&1.a <= a and b <= &1.b and (b > a or &1.a == a)))

          valid =
            is_number(a) and is_number(b) and a == last and b >= a and b <= stop and
              sample["epoch_s"] == b and sample["evaluated_at_s"] == a + (b - a) / 2 and
              (b > a or index == 0) and (index != 0 or (a == first and b == first)) and
              is_map(segment) and
              is_number(level["sample_step_s"]) and level["sample_step_s"] > 0 and
              b - a <= level["sample_step_s"] + 1.0e-7

          if valid do
            next = advance(state, c, segment.load, b - a)

            es =
              C.check(
                sample["phase"] == segment.phase and sample["mode"] == segment.evidence_mode and
                  sample["scope"] == segment.scope,
                "battery_interval_binding",
                path,
                "battery phase or mode differs from saved timeline"
              ) ++
                C.check(
                  Enum.all?(
                    ~w(energy_wh unserved_wh curtailed_wh),
                    &C.near?(sample["state"][&1], next[&1])
                  ),
                  "battery_sample_state",
                  path,
                  "battery sample differs from independent phase-load balance"
                )

            {next, b, es ++ issues}
          else
            {state, last,
             [
               C.issue(
                 "battery_coverage",
                 path,
                 "battery samples must cover exact phase boundaries without gaps or overlaps"
               )
               | issues
             ]}
          end
        end)

      issues ++
        C.check(
          last == stop and level["evaluated_through_s"] == stop and
            level["uncovered_intervals"] == [],
          "battery_coverage",
          path,
          "battery history does not cover the full horizon"
        )
    end
  end

  defp initial(c),
    do: %{
      "energy_wh" => c["initial_wh"],
      "minimum_energy_wh" => c["initial_wh"],
      "unserved_wh" => 0.0,
      "curtailed_wh" => 0.0
    }

  defp advance(s, c, load, dt) do
    bus = (c["generation"]["power_w"] - load) * dt / 3600

    {energy, unmet, curtailed} =
      if bus >= 0 do
        room = max(0, c["capacity_wh"] - s["energy_wh"])

        {min(c["capacity_wh"], s["energy_wh"] + bus * c["charge_efficiency"]), 0,
         max(0, bus - room / c["charge_efficiency"])}
      else
        demand = -bus

        {max(0, s["energy_wh"] - demand / c["discharge_efficiency"]),
         max(0, demand - s["energy_wh"] * c["discharge_efficiency"]), 0}
      end

    %{
      "energy_wh" => energy,
      "minimum_energy_wh" => min(s["minimum_energy_wh"], energy),
      "unserved_wh" => s["unserved_wh"] + unmet,
      "curtailed_wh" => s["curtailed_wh"] + curtailed
    }
  end
end
