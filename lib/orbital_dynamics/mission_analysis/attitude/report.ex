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
      "\n\n[report.json](report.json) includes exact assumptions, sampled quaternions, angular velocity/acceleration, all tested-start decisions, " <>
      "and ideal transition phases. Missing initial state or pointing evidence stays unknown. Start-grid rejection is not a global infeasibility proof.\n"
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
end
