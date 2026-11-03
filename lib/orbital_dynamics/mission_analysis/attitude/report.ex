defmodule OrbitalDynamics.MissionAnalysis.Attitude.Report do
  @moduledoc false
  def markdown(report) do
    activities = Map.new(report["activities"], &{&1["id"], &1})

    rows =
      Enum.map(report["requests"], fn r ->
        "| #{r["request_id"]} | #{r["opportunity_count"]} | #{r["status"]} | #{Enum.join(r["reasons"], ", ")} |"
      end)

    profile_rows =
      Enum.map(report["activities"], fn a ->
        points = a["attitude_profile"]

        "| #{a["request_id"]} | #{a["starts_at_s"]} | #{a["ends_at_s"]} | #{Enum.max(Enum.map(points, & &1["rate_deg_s"]))} | #{Enum.max(Enum.map(points, & &1["accel_deg_s2"]))} |"
      end)

    transitions =
      Enum.map(report["attitude_planning"]["transitions"], fn t ->
        source =
          if t["from_activity_id"] == :null,
            do: "declared initial attitude",
            else: activities[t["from_activity_id"]]["request_id"]

        destination = activities[t["to_activity_id"]]["request_id"]

        "| #{source} | #{destination} | #{t["required_s"]} | #{t["available_s"]} | #{t["time_margin_s"]} | #{t["slew_angle_deg"]} |"
      end)

    reasons =
      report["selection_decisions"]
      |> Enum.filter(&(&1["reason"] != "request_already_scheduled"))
      |> Enum.map(fn d ->
        a = d["attitude_assessment"]

        counts =
          Map.get(a, "attempts", [])
          |> Enum.reject(&(&1["status"] == "supported"))
          |> Enum.frequencies_by(& &1["reason"])

        "- #{d["request_id"]}: #{d["reason"]}; #{a["status"]}; reason #{Map.get(a, "reason", "—")}; " <>
          "tested starts #{Map.get(a, "tested_start_count", 0)}; rejected attempt counts #{inspect(counts)}"
      end)

    "# Attitude planning analysis\n\n" <>
      "Declared kinematic assumptions only. Rates and accelerations during activities are sampled; " <>
      "transition phases construct an ideal bounded motion. No actuator or achieved-attitude validation. " <>
      if(is_map(get_in(report, ["attitude_planning", "path_constraints"])),
        do:
          "Declared path rules gate all tested cadences; unspecified constraints and continuous feasibility remain unassessed.\n\n",
        else:
          "Intermediate transitions are not screened for Sun/keep-out, unintended ground illumination or communications constraints.\n\n"
      ) <>
      Enum.join(
        [
          "| Request | Physical opportunities | Scheduling | Reasons |",
          "| --- | --- | --- | --- |"
        ] ++ rows,
        "\n"
      ) <>
      opportunity_markdown(report) <>
      "\n\nActivity times are absolute seconds since J2000 in the declared scale.\n\n" <>
      Enum.join(
        [
          "| Request | Start s | End s | Max sampled rate deg/s | Max sampled acceleration deg/s² |",
          "| --- | --- | --- | --- | --- |"
        ] ++ profile_rows,
        "\n"
      ) <>
      "\n\nTransitions include braking, any rest hold, slew, settling dwell and ramp into tracking.\n\n" <>
      Enum.join(
        [
          "| From | To | Required s | Available s | Time headroom s | Rest-slew angle deg |",
          "| --- | --- | --- | --- | --- | --- |"
        ] ++ transitions,
        "\n"
      ) <>
      "\n\n" <>
      Enum.join(reasons, "\n") <>
      path_markdown(report) <>
      horizon_markdown(report) <>
      resource_markdown(report) <>
      solar_markdown(report) <>
      "\n\n[report.json](report.json) includes exact assumptions, sampled quaternions, angular velocity/acceleration, all tested-start decisions, " <>
      "and ideal transition phases. Missing initial state or pointing evidence stays unknown. Start-grid rejection is not a global infeasibility proof.\n"
  end

  defp opportunity_markdown(report) do
    if is_map(report["opportunity_search"]) do
      config = report["opportunity_search"]

      rows =
        for a <- report["analyses"],
            e = a["opportunity_evidence"],
            is_map(e),
            w <- Map.get(e, "windows", []) do
          entry = Enum.join(w["limiting_constraints"]["entry"], ", ")
          exit = Enum.join(w["limiting_constraints"]["exit"], ", ")

          "| #{a["request_id"]} | #{w["starts_at_s"]} | #{w["ends_at_s"]} | #{w["status"]}: #{w["reason"]} | #{entry} | #{exit} |"
        end

      unknowns =
        for a <- report["analyses"], e = a["opportunity_evidence"], is_map(e) do
          "- #{a["request_id"]}: search #{e["status"]}; excluded unknown/open-contact intervals #{length(Map.get(e, "excluded_unknown_intervals", []))}; total charged search/endpoint evaluations #{Map.get(e, "total_evaluation_count", 0)}."
        end

      "\n\n## Conservative opportunities\n\n" <>
        "Constraint windows use inward numerical bracket bounds plus one solver tolerance (#{config["time_tolerance_s"]} s). " <>
        "Declared mission margins apply once after intersection: +#{config["entry_margin_s"]} s at entry and -#{config["exit_margin_s"]} s at exit. " <>
        "These margins are assumptions, not derived spacecraft uncertainty. Unknown spans and strict contacts are excluded; finite scans do not prove continuous feasibility.\n\n" <>
        Enum.join(
          [
            "| Request | Conservative start s | Conservative end s | Window decision | Entry limiter | Exit limiter |",
            "| --- | --- | --- | --- | --- | --- |"
          ] ++ rows,
          "\n"
        ) <>
        "\n\n" <>
        Enum.join(unknowns, "\n") <>
        "\n\nWindow acceptance precedes attitude, transition, terminal and battery checks; their scheduling decisions follow below. Root brackets, removed-window evidence and endpoint checks remain in report.json.\n"
    else
      ""
    end
  end

  defp path_markdown(report) do
    if is_map(get_in(report, ["attitude_planning", "path_constraints"])) do
      transitions =
        Enum.map(
          report["attitude_planning"]["transitions"],
          &{"transition to " <> &1["to_activity_id"], &1["path_evidence"]}
        )

      activities = Enum.map(report["activities"], &{&1["request_id"], &1["path_evidence"]})

      rows =
        Enum.map(transitions ++ activities, fn {name, e} ->
          "| #{name} | #{e["status"]} | #{e["resolution_status"]} |"
        end)

      failures =
        Enum.flat_map(report["selection_decisions"], fn d ->
          first =
            Enum.find_value(Map.get(d["attitude_assessment"], "attempts", []), fn attempt ->
              Enum.find_value(Map.get(attempt, "path_checks", %{}), fn {scope, e} ->
                if e["status"] in ["violated", "unknown"],
                  do: {attempt["start_s"], scope, e},
                  else: nil
              end)
            end)

          case first do
            nil ->
              []

            {start, scope, e} ->
              levels = Map.get(e, "levels", [])

              issues =
                Enum.map_join(levels, "; ", fn l ->
                  issue = Map.get(l, "first_issue")

                  if is_map(issue) do
                    names =
                      Enum.flat_map(Map.get(issue, "rules", []), fn r ->
                        r["checks"]
                        |> Enum.reject(&(&1["status"] == "supported"))
                        |> Enum.map(
                          &(r["rule_id"] <> "/" <> &1["id"] <> " (" <> &1["status"] <> ")")
                        )
                      end)

                    "step #{l["sample_step_s"]} s: #{Enum.join(names, ", ")} at #{issue["epoch_s"]}"
                  else
                    "step #{l["sample_step_s"]} s: #{l["status"]} #{Map.get(l, "reason", "")}"
                  end
                end)

              [
                "- #{d["request_id"]}, candidate #{start}, #{scope}: #{e["status"]}; #{Map.get(e, "reason", "")} #{issues}"
              ]
          end
        end)

      "\n\n## Path evidence\n\n" <>
        Enum.join(["| Path | Status | Cadence comparison |", "| --- | --- | --- |"] ++ rows, "\n") <>
        "\n\nFirst recorded path rejection per opportunity (times are absolute epoch seconds):\n\n" <>
        Enum.join(failures, "\n") <>
        "\n\nPossible cone overlap is a conservative exclusion guard, not a delivered-irradiance prediction. " <>
        "Mode behavior and instantaneous switches are declared assumptions. Full-horizon coverage requires an explicit horizon; see its separate evidence."
    else
      ""
    end
  end

  defp horizon_markdown(report) do
    case get_in(report, ["attitude_planning", "horizon_coverage"]) do
      h when is_map(h) ->
        rows =
          Enum.map(Enum.sort(h["assets"]), fn {id, a} ->
            "| #{id} | #{a["starts_at_s"]} | #{a["ends_at_s"]} | #{a["status"]} | #{length(a["uncovered_intervals"])} |"
          end)

        "\n\n## Full-horizon evidence\n\nStatus: #{h["status"]} at tested epochs. Includes idle assets, terminal braking/slew/settling and the terminal hold.\n\n" <>
          Enum.join(
            [
              "| Asset | Start s | End s | Status | Unsupported intervals |",
              "| --- | --- | --- | --- | --- |"
            ] ++ rows,
            "\n"
          ) <>
          "\n\nExact terminal modes, phases, path failures and uncovered intervals are in report.json. A declared park or off mode does not establish safety."

      _ ->
        ""
    end
  end

  defp resource_markdown(report) do
    case get_in(report, ["attitude_planning", "resource_feasibility"]) do
      resources when is_map(resources) ->
        rows =
          Enum.flat_map(Enum.sort(resources["assets"]), fn {asset, r} ->
            case Map.get(r, "models", []) do
              [] ->
                [
                  "| #{asset} | — | — | #{r["status"]} | — | — | — | #{Map.get(r, "reason", "")} |"
                ]

              models ->
                Enum.flat_map(models, fn m ->
                  Enum.map(m["levels"], fn level ->
                    battery? = get_in(m, ["assumptions", "model"]) == "ideal_energy_balance_v1"

                    minimum =
                      if battery?,
                        do: get_in(level, ["state_extrema", "energy_wh", "min"]) || "—",
                        else: "—"

                    final =
                      if battery? and is_map(level["final_state"]),
                        do: Map.get(level["final_state"], "energy_wh", "—"),
                        else: "—"

                    margin =
                      get_in(level, ["minimum_margins", "battery_reserve", "margin"]) || "—"

                    issue =
                      if is_map(level["first_issue"]),
                        do:
                          "#{level["first_issue"]["starts_at_s"]}–#{level["first_issue"]["ends_at_s"]}",
                        else: Map.get(level, "reason", "—")

                    "| #{asset} | #{m["id"]} | #{level["sample_step_s"]} | #{level["status"]} | #{minimum} | #{final} | #{margin} | #{issue} |"
                  end)
                end)
            end
          end)

        "\n\n## Resource feasibility\n\nStatus: #{resources["status"]}. Combined planning status: #{report["attitude_planning"]["planning_status"]}.\n\n" <>
          Enum.join(
            [
              "| Asset | Resource | Step s | Status | Min battery Wh | Final battery Wh | Min reserve margin Wh | First issue interval s |",
              "| --- | --- | --- | --- | --- | --- | --- | --- |"
            ] ++ rows,
            "\n"
          ) <>
          "\n\nEach cadence replays the complete timeline from the declared initial state, including idle and terminal behavior. Battery columns apply to the ideal battery model; report.json contains all model states, margins and uncovered intervals. Charging and loads are declared assumptions."

      _ ->
        ""
    end
  end

  defp solar_markdown(report) do
    case report["solar_generation_diagnostics"] do
      %{"models" => models} ->
        rows =
          Enum.flat_map(models, fn m ->
            Enum.map(m["levels"], fn l ->
              power =
                if is_map(l["observed_power_range_w"]),
                  do:
                    "#{l["observed_power_range_w"]["min"]}–#{l["observed_power_range_w"]["max"]}",
                  else: "unknown"

              brackets =
                Enum.map_join(l["shadow_transition_brackets"], "; ", fn b ->
                  kind = if b["to_sunlit"], do: "exit", else: "entry"
                  "#{kind}: #{b["earlier_sample_s"]}–#{b["later_sample_s"]}"
                end)

              "| #{m["asset_id"]} | #{m["resource_id"]} | #{l["sample_step_s"]} | #{l["status"]} | #{power} | #{brackets} |"
            end)
          end)

        comparisons =
          Enum.flat_map(
            Enum.sort(report["attitude_planning"]["resource_feasibility"]["assets"]),
            fn {id, a} ->
              for m <- Map.get(a, "models", []),
                  match?(
                    %{"generation_assumptions" => %{"model" => "body_fixed_solar_array_v1"}},
                    m["assumptions"]
                  ) do
                c = m["state_comparison"]
                final = energy_spread(c["final_state_range"])
                minimum = energy_spread(c["minimum_state_range"])

                "- #{id}/#{m["id"]}: cadence comparison #{c["status"]}; final battery spread #{if is_number(final), do: final, else: "unknown"} Wh; minimum battery spread #{if is_number(minimum), do: minimum, else: "unknown"} Wh."
              end
            end
          )

        "\n\n## Solar generation\n\n" <>
          Enum.join(
            [
              "| Asset | Resource | Step s | Status | Observed bus W | Shadow-change brackets s |",
              "| --- | --- | --- | --- | --- | --- |"
            ] ++ rows,
            "\n"
          ) <>
          "\n\n" <>
          Enum.join(comparisons, "\n") <>
          "\n\nShadow brackets use actual midpoint evaluation times. They are not exact roots or evidence that no other crossing occurred. Cadence spreads are numerical comparisons, not physical error bounds. Fixed panels, Sun range and efficiencies are declared assumptions; finite-Sun disk-area fractions multiply the center-ray panel cosine. Self-shadowing and deployment are not modeled. Contact search brackets and state-source provenance are retained in the JSON report; discovery remains bounded by the declared search policy."

      _ ->
        ""
    end
  end

  defp energy_spread(%{"energy_wh" => %{"spread" => value}}), do: value
  defp energy_spread(_), do: nil
end
