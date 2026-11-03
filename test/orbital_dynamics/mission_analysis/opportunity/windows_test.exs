defmodule OrbitalDynamics.MissionAnalysis.Opportunity.WindowsTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.Opportunity.{Policy, Windows}

  defp policy(opts \\ []),
    do:
      Policy.new!(
        Keyword.merge(
          [
            max_check_step_s: 5,
            time_tolerance_s: 0.01,
            max_iterations: 64,
            max_evaluations: 10000,
            entry_margin_s: 0,
            exit_margin_s: 0
          ],
          opts
        )
      )

  defp edge(t, a, b),
    do: %{
      "kind" => "estimated_event",
      "timing_target" => "event_function_zero",
      "estimate_s" => t,
      "bracket_start_s" => a,
      "bracket_end_s" => b
    }

  defp window(
         a,
         b,
         entry \\ %{"kind" => "scan_or_search_clip"},
         exit \\ %{"kind" => "scan_or_search_clip"}
       ),
       do: %{
         "starts_at_s" => a,
         "ends_at_s" => b,
         "start_boundary" => entry,
         "end_boundary" => exit
       }

  defp result(id, windows, extra \\ %{}),
    do:
      Map.merge(
        %{
          "function" => %{"id" => id, "condition" => "nonnegative", "assumptions" => %{}},
          "condition_windows" => windows,
          "events" => [],
          "uncovered_intervals" => [],
          "status" => "complete_under_search_policy"
        },
        extra
      )

  defp report(rows, start \\ 0, stop \\ 100),
    do: %{"starts_at_s" => start, "ends_at_s" => stop, "results" => rows}

  test "root uncertainty is removed on the inside, then mission margins apply once after intersection" do
    r =
      report([
        result("access", [window(10, 80, edge(10, 9, 11), edge(80, 79, 81))]),
        result("night", [window(15, 85, edge(15, 14, 16), edge(85, 84, 86))])
      ])

    c = Windows.compose(r, policy(entry_margin_s: 2, exit_margin_s: 3), 5)
    assert [w] = c["windows"]
    assert_in_delta w["starts_at_s"], 18.01, 1.0e-12
    assert_in_delta w["ends_at_s"], 75.99, 1.0e-12
    assert w["limiting_constraints"] == %{"entry" => ["night"], "exit" => ["access"]}
    assert w["status"] == "accepted"
  end

  test "unknown spans are independently subtracted even if an upstream window overlaps them" do
    c =
      Windows.compose(
        report([
          result("unknown", [window(0, 100)], %{
            "uncovered_intervals" => [
              %{"starts_at_s" => 40, "ends_at_s" => 60, "reason" => "missing"}
            ]
          })
        ]),
        policy(),
        1
      )

    assert [a, b] = c["windows"]
    assert a["ends_at_s"] < 40
    assert b["starts_at_s"] > 60
    assert c["excluded_unknown_intervals"] != []
  end

  test "strict interior contacts split windows so equality cannot become schedulable" do
    r =
      result("strict", [window(0, 100)], %{
        "function" => %{
          "id" => "strict",
          "condition" => "nonnegative",
          "assumptions" => %{"strict_condition" => true}
        },
        "events" => [%{"bracket_start_s" => 50, "bracket_end_s" => 50}]
      })

    assert [a, b] = Windows.compose(report([r]), policy(), 1)["windows"]
    assert a["ends_at_s"] < 50
    assert b["starts_at_s"] > 50
  end

  test "unresolvable numerical guards and mission margins reject instead of rounding away" do
    unproven =
      Map.put(edge(10, 9, 11), "timing_target", "stationary_point_not_proven_function_zero")

    assert Windows.compose(report([result("unproven", [window(10, 90, unproven)])]), policy(), 1)[
             "windows"
           ] == []

    epoch = 9.0e11

    r =
      report(
        [
          result("root", [
            window(epoch + 10, epoch + 90, edge(epoch + 10, epoch + 10, epoch + 10))
          ])
        ],
        epoch,
        epoch + 100
      )

    c = Windows.compose(r, policy(time_tolerance_s: 1.0e-6), 1)
    assert c["windows"] == []
    [constraint] = c["constraints"]
    assert hd(hd(constraint["windows"])["entry"])["resolved"] == false

    c =
      Windows.compose(
        report([result("clip", [window(epoch, epoch + 100)])], epoch, epoch + 100),
        policy(entry_margin_s: 1.0e-6),
        1
      )

    assert hd(c["windows"])["reason"] == "timing_margin_below_epoch_resolution"
  end

  test "short windows retain their rejection evidence" do
    c =
      Windows.compose(
        report([result("short", [window(20, 25)])]),
        policy(entry_margin_s: 2, exit_margin_s: 2),
        2
      )

    assert hd(c["windows"])["reason"] == "insufficient_duration_after_bounds_and_margins"
  end
end
