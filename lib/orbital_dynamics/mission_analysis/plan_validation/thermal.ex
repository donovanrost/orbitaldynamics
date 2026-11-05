defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.Thermal do
  @moduledoc "Independent analytic temperature accounting when phase heat is constant across all motion kinds. No resource or motion helpers."
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Checker, as: C

  @phases ~w(activity brake hold continuation slew_accelerate slew_cruise slew_decelerate settle ramp_to_tracking)

  def check(inputs, report, label) do
    Enum.reduce(get_in(inputs, ["study", "resources", "assets"]) || %{}, {[], %{}}, fn {asset,
                                                                                        models},
                                                                                       acc ->
      Enum.reduce(Enum.filter(models, &(&1["model"] == "thermal")), acc, fn model,
                                                                            {issues, expected} ->
        {more, prediction} =
          model(inputs, report, asset, model, label <> "/" <> asset <> "/" <> model["id"])

        expected =
          if prediction,
            do:
              Map.update(
                expected,
                asset,
                %{model["id"] => prediction},
                &Map.put(&1, model["id"], prediction)
              ),
            else: expected

        {issues ++ more, expected}
      end)
    end)
  end

  defp model(i, r, asset, m, path) do
    try do
      c = m["configuration"]

      numeric =
        Enum.all?(
          ~w(initial_temperature_k heat_capacity_j_k sink_temperature_k conductance_w_k minimum_temperature_k maximum_temperature_k),
          &is_number(c[&1])
        )

      unless numeric, do: throw({:unsupported, "thermal parameters are not completely declared"})

      unless c["heat_capacity_j_k"] > 0 and c["conductance_w_k"] >= 0 and
               c["minimum_temperature_k"] > 0 and
               c["maximum_temperature_k"] >= c["minimum_temperature_k"] and
               c["sink_temperature_k"] > 0 and c["initial_temperature_k"] > 0,
             do: raise(ArgumentError, "invalid thermal configuration")

      phase = Enum.map(@phases, &c["phase_heat_w"][&1]) |> Enum.uniq()

      unless length(phase) == 1 and is_number(hd(phase)) and hd(phase) >= 0,
        do:
          throw(
            {:unsupported, "independent thermal accounting requires complete equal phase heat"}
          )

      heat = hd(phase)
      h = i["study"]["horizon"]
      policy = get_in(i, ["study", "path_constraints", "assets", asset])
      acts = Enum.filter(r["activities"], &(&1["asset_id"] == asset))
      terminal = h["terminals"][asset]

      terminal_heat =
        Map.take(
          policy["modes"][terminal["mode"]] || %{},
          ~w(thermal_heat_w thermal_rejection_w_k)
        )

      idle_heat =
        Map.take(
          policy["modes"][policy["transition_mode"]] || %{},
          ~w(thermal_heat_w thermal_rejection_w_k)
        )

      unless (map_size(terminal_heat) == 2 and terminal_heat == idle_heat) or
               (terminal["strategy"] == "activity_boundary" and
                  Enum.any?(
                    acts,
                    &(&1["ends_at_s"] == h["ends_at_s"] and
                        policy["activity_modes"][&1["request_id"]] == terminal["mode"])
                  )),
             do: throw({:unsupported, "thermal terminal mode differs from idle"})

      times =
        ([h["starts_at_s"], h["ends_at_s"]] ++
           Enum.flat_map(acts, &[&1["starts_at_s"], &1["ends_at_s"]]))
        |> Enum.map(&(&1 * 1.0))
        |> Enum.uniq()
        |> Enum.sort()

      {segments, last} =
        Enum.map_reduce(Enum.chunk_every(times, 2, 1, :discard), c["initial_temperature_k"], fn [
                                                                                                  a,
                                                                                                  b
                                                                                                ],
                                                                                                t ->
          act = Enum.find(acts, &(&1["starts_at_s"] <= a and &1["ends_at_s"] >= b))

          mode =
            if act,
              do: policy["activity_modes"][act["request_id"]],
              else: policy["transition_mode"]

          params = policy["modes"][mode]
          q = params["thermal_heat_w"]
          extra = params["thermal_rejection_w_k"]

          unless is_number(q) and q >= 0 and is_number(extra) and extra >= 0,
            do: throw({:unsupported, "thermal mode inputs missing"})

          segment = %{a: a, b: b, t: t, q: q + heat, k: c["conductance_w_k"] + extra}
          {segment, evolve(segment, b - a, c)}
        end)

      at = fn t ->
        s = Enum.find(segments, &(&1.a <= t and t < &1.b)) || List.last(segments)
        evolve(s, t - s.a, c)
      end

      values = Enum.map(times, at)
      low = Enum.min(values)
      high = Enum.max(values)

      issues =
        C.check(
          low >= c["minimum_temperature_k"] - 1.0e-9,
          "thermal_cold_limit",
          path,
          "analytic history crosses cold limit"
        ) ++
          C.check(
            high <= c["maximum_temperature_k"] + 1.0e-9,
            "thermal_hot_limit",
            path,
            "analytic history crosses hot limit"
          )

      found =
        Enum.filter(
          get_in(r, ["attitude_planning", "resource_feasibility", "assets", asset, "models"]) ||
            [],
          &(&1["id"] == m["id"])
        )

      unless length(found) == 1, do: raise(ArgumentError, "one thermal evidence model required")
      levels = hd(found)["levels"]

      unless is_list(levels) and length(levels) in 1..6,
        do: raise(ArgumentError, "thermal levels missing")

      issues =
        issues ++
          Enum.flat_map(levels, fn level ->
            samples = level["samples"]
            epochs = Enum.map(samples, & &1["epoch_s"])

            C.check(
              hd(epochs) == hd(times) and List.last(epochs) == List.last(times) and
                level["evaluated_through_s"] == List.last(times) and
                Enum.all?(times, fn t -> Enum.any?(epochs, &(&1 == t)) end) and
                is_number(level["sample_step_s"]) and
                level["sample_step_s"] > 0 and
                Enum.all?(Enum.chunk_every(epochs, 2, 1, :discard), fn [a, b] ->
                  b > a and b - a <= level["sample_step_s"] + 1.0e-7
                end),
              "thermal_coverage",
              path,
              "temperature samples do not cover horizon and mode boundaries"
            ) ++
              C.check(
                C.near?(level["initial_state"]["temperature_k"], c["initial_temperature_k"]) and
                  C.near?(level["final_state"]["temperature_k"], last),
                "thermal_boundary_state",
                path,
                "saved thermal endpoint differs from analytic history"
              ) ++
              C.check(
                C.near?(get_in(level, ["state_extrema", "temperature_k", "min"]), low) and
                  C.near?(get_in(level, ["state_extrema", "temperature_k", "max"]), high),
                "thermal_extrema",
                path,
                "saved thermal extrema differ"
              ) ++
              C.check(
                C.near?(
                  get_in(level, ["minimum_margins", "thermal_hot_limit", "margin"]),
                  c["maximum_temperature_k"] - high
                ) and
                  C.near?(
                    get_in(level, ["minimum_margins", "thermal_cold_limit", "margin"]),
                    low - c["minimum_temperature_k"]
                  ),
                "thermal_margins",
                path,
                "saved thermal margins differ"
              ) ++
              Enum.flat_map(samples, fn sample ->
                t = sample["epoch_s"]

                unless is_number(t) and t >= hd(times) and t <= List.last(times),
                  do: raise(ArgumentError, "thermal sample outside horizon")

                C.check(
                  C.near?(sample["state"]["temperature_k"], at.(t)),
                  "thermal_sample_state",
                  path,
                  "saved temperature differs from independent analytic history"
                )
              end)
          end)

      {issues,
       %{"temperature_k" => last, "minimum_temperature_k" => low, "maximum_temperature_k" => high}}
    rescue
      e in [
        ArgumentError,
        KeyError,
        BadMapError,
        FunctionClauseError,
        ArithmeticError,
        Protocol.UndefinedError
      ] ->
        {[C.issue("thermal_schema", path, Exception.message(e))], nil}
    catch
      {:unsupported, message} ->
        {[C.issue("thermal_model_unsupported", path, message, "unsupported")], nil}
    end
  end

  # Independent Duhamel-form solution. A convergent series retains tiny heat inputs.
  defp evolve(s, dt, c) do
    x = s.k * dt / c["heat_capacity_j_k"]
    decay = :math.exp(-x)

    phi =
      if x < 0.01 do
        Enum.reduce(1..12, {1.0, 1.0}, fn n, {term, sum} ->
          term = term * -x / (n + 1)
          {term, sum + term}
        end)
        |> elem(1)
      else
        (1 - decay) / x
      end

    s.t * decay + c["sink_temperature_k"] * (1 - decay) + s.q * dt / c["heat_capacity_j_k"] * phi
  end
end
