defmodule OrbitalDynamics.MissionAnalysis.Opportunity.Windows do
  @moduledoc false

  def compose(report, policy, duration) do
    seed = [
      %{
        "starts_at_s" => report["starts_at_s"],
        "ends_at_s" => report["ends_at_s"],
        "entry" => [%{"constraint_id" => "request_or_coverage", "kind" => "search_clip"}],
        "exit" => [%{"constraint_id" => "request_or_coverage", "kind" => "search_clip"}]
      }
    ]

    constraints =
      for result <- report["results"], result["function"]["condition"] != "none" do
        id = result["function"]["id"]

        rows =
          for w <- result["condition_windows"] do
            entry =
              edge(w["start_boundary"], w["starts_at_s"], :entry, id, policy.time_tolerance_s)

            exit = edge(w["end_boundary"], w["ends_at_s"], :exit, id, policy.time_tolerance_s)

            %{
              "starts_at_s" => entry["inside_at_s"],
              "ends_at_s" => exit["inside_at_s"],
              "entry" => [entry],
              "exit" => [exit],
              "estimated_window" => w,
              "status" =>
                if(
                  Map.get(entry, "resolved", true) and Map.get(exit, "resolved", true) and
                    exit["inside_at_s"] > entry["inside_at_s"],
                  do: "retained",
                  else: "removed_by_numerical_bounds"
                )
            }
          end

        %{
          "constraint_id" => id,
          "search_status" => result["status"],
          "uncovered_intervals" => result["uncovered_intervals"],
          "windows" => rows
        }
      end

    intersections =
      Enum.reduce(constraints, seed, fn c, acc ->
        intersect(acc, Enum.filter(c["windows"], &(&1["status"] == "retained")), [])
      end)

    strict_contacts =
      for r <- report["results"],
          get_in(r, ["function", "assumptions", "strict_condition"]) == true,
          e <- r["events"],
          do: %{
            "starts_at_s" => e["bracket_start_s"],
            "ends_at_s" => e["bracket_end_s"],
            "reason" => "open_constraint_contact",
            "constraints" => [r["function"]["id"]]
          }

    unknown =
      report["results"]
      |> Enum.flat_map(fn r ->
        Enum.map(r["uncovered_intervals"], &Map.put(&1, "constraints", [r["function"]["id"]]))
      end)
      |> Kernel.++(strict_contacts)
      |> merge_unknown()

    intersections = subtract_unknown(intersections, unknown, policy.time_tolerance_s, [])

    windows =
      for w <- intersections do
        first = w["starts_at_s"] + policy.entry_margin_s
        last = w["ends_at_s"] - policy.exit_margin_s

        reason =
          cond do
            (policy.entry_margin_s > 0 and first <= w["starts_at_s"]) or
                (policy.exit_margin_s > 0 and last >= w["ends_at_s"]) ->
              "timing_margin_below_epoch_resolution"

            last <= first ->
              "removed_by_mission_timing_margins"

            last - first < duration ->
              "insufficient_duration_after_bounds_and_margins"

            true ->
              "accepted"
          end

        Map.merge(w, %{
          "before_mission_margins" => %{
            "starts_at_s" => w["starts_at_s"],
            "ends_at_s" => w["ends_at_s"]
          },
          "starts_at_s" => first,
          "ends_at_s" => last,
          "sample_count" => 0,
          "entry_margin_s" => policy.entry_margin_s,
          "exit_margin_s" => policy.exit_margin_s,
          "required_duration_s" => duration,
          "status" => if(reason == "accepted", do: "accepted", else: "rejected"),
          "reason" => reason,
          "limiting_constraints" => %{"entry" => ids(w["entry"]), "exit" => ids(w["exit"])}
        })
      end

    %{
      "windows" => windows,
      "excluded_unknown_intervals" => unknown,
      "constraints" => constraints,
      "boundary_policy" =>
        "latest_opening_bracket_side_and_earliest_closing_bracket_side_plus_one_solver_tolerance_inward",
      "margin_policy" => "mission_entry_exit_margins_applied_once_after_constraint_intersection",
      "limits" =>
        "conservative boundary placement relative to declared numerical functions and search policy; not a proof of continuous feasibility or a physical uncertainty bound"
    }
  end

  defp edge(%{"kind" => "estimated_event"} = b, t, side, id, tolerance) do
    inside =
      if side == :entry,
        do: b["bracket_end_s"] + tolerance,
        else: b["bracket_start_s"] - tolerance

    resolved =
      if side == :entry, do: inside > b["bracket_end_s"], else: inside < b["bracket_start_s"]

    zero_target = b["timing_target"] == "event_function_zero"

    %{
      "resolved" => resolved and zero_target,
      "bounded_function_zero" => zero_target,
      "constraint_id" => id,
      "kind" => "root_bracket_inside_bound",
      "estimated_at_s" => t,
      "inside_at_s" => inside,
      "root_bracket" => b,
      "numerical_guard_s" => tolerance,
      "numerical_trim_s" => abs(inside - t)
    }
  end

  defp edge(b, t, _, id, _) do
    %{
      "constraint_id" => id,
      "kind" => "observed_or_search_clip",
      "inside_at_s" => t,
      "boundary" => b
    }
  end

  defp merge_unknown(rows) do
    rows
    |> Enum.sort_by(& &1["starts_at_s"])
    |> Enum.reduce([], fn row, acc ->
      case acc do
        [last | rest] ->
          if row["starts_at_s"] <= last["ends_at_s"],
            do: [
              %{
                "starts_at_s" => last["starts_at_s"],
                "ends_at_s" => max(last["ends_at_s"], row["ends_at_s"]),
                "constraints" => Enum.uniq(last["constraints"] ++ row["constraints"])
              }
              | rest
            ],
            else: [row | acc]

        _ ->
          [row | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp subtract_unknown([], _, _, acc), do: Enum.reverse(acc)
  defp subtract_unknown(windows, [], _, acc), do: Enum.reverse(acc) ++ windows

  defp subtract_unknown([w | ws] = windows, [g | gs] = gaps, tolerance, acc) do
    cond do
      w["ends_at_s"] < g["starts_at_s"] ->
        subtract_unknown(ws, gaps, tolerance, [w | acc])

      g["ends_at_s"] < w["starts_at_s"] ->
        subtract_unknown(windows, gs, tolerance, acc)

      true ->
        before = g["starts_at_s"] - tolerance
        after_gap = g["ends_at_s"] + tolerance

        entry = %{
          "constraint_id" => "unknown_region",
          "kind" => "known_side_of_unknown_interval",
          "inside_at_s" => after_gap,
          "unknown_interval" => g
        }

        exit = %{entry | "inside_at_s" => before}
        # A nonrepresentable guard cannot establish a known side of the gap.
        if (g["starts_at_s"] > w["starts_at_s"] and before >= g["starts_at_s"]) or
             (g["ends_at_s"] < w["ends_at_s"] and after_gap <= g["ends_at_s"]) do
          subtract_unknown(ws, gaps, tolerance, acc)
        else
          acc =
            if before > w["starts_at_s"],
              do: [Map.merge(w, %{"ends_at_s" => before, "exit" => [exit]}) | acc],
              else: acc

          if after_gap < w["ends_at_s"],
            do:
              subtract_unknown(
                [Map.merge(w, %{"starts_at_s" => after_gap, "entry" => [entry]}) | ws],
                gs,
                tolerance,
                acc
              ),
            else: subtract_unknown(ws, gaps, tolerance, acc)
        end
    end
  end

  defp ids(edges) do
    physical =
      Enum.filter(
        edges,
        &(&1["kind"] in ["root_bracket_inside_bound", "known_side_of_unknown_interval"])
      )

    if physical == [],
      do: ["request_or_coverage_clip"],
      else:
        physical
        |> Enum.flat_map(fn edge ->
          if edge["kind"] == "known_side_of_unknown_interval",
            do: Enum.map(edge["unknown_interval"]["constraints"], &("unknown:" <> &1)),
            else: [edge["constraint_id"]]
        end)
        |> Enum.uniq()
        |> Enum.sort()
  end

  # Both inputs are ordered, disjoint windows: a linear sweep avoids a Cartesian
  # product of per-constraint windows and never joins across a gap.
  defp intersect([], _, acc), do: Enum.reverse(acc)
  defp intersect(_, [], acc), do: Enum.reverse(acc)

  defp intersect([a | as] = left, [b | bs] = right, acc) do
    start = max(a["starts_at_s"], b["starts_at_s"])
    stop = min(a["ends_at_s"], b["ends_at_s"])

    acc =
      if stop > start do
        [
          %{
            "starts_at_s" => start,
            "ends_at_s" => stop,
            "entry" => contributors(a, b, "starts_at_s", "entry", start),
            "exit" => contributors(a, b, "ends_at_s", "exit", stop)
          }
          | acc
        ]
      else
        acc
      end

    cond do
      a["ends_at_s"] < b["ends_at_s"] -> intersect(as, right, acc)
      a["ends_at_s"] > b["ends_at_s"] -> intersect(left, bs, acc)
      true -> intersect(as, bs, acc)
    end
  end

  defp contributors(a, b, key, edge, value),
    do: if(a[key] == value, do: a[edge], else: []) ++ if(b[key] == value, do: b[edge], else: [])
end
