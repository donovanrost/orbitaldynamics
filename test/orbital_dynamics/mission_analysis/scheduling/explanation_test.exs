defmodule OrbitalDynamics.MissionAnalysis.Scheduling.ExplanationTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.RepeatedServiceQualityCases, as: Cases
  alias OrbitalDynamics.MissionAnalysis.Scheduling.{Explanation, Policy, Replacement}
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Diff, Snapshot}

  defp config, do: Enum.find(Cases.cases(), &(&1["id"] == "battery_recovery"))

  defp pin,
    do: %{"request_id" => "committed", "asset_id" => "a", "starts_at_s" => 20, "ends_at_s" => 30}

  defp request(id, t, value),
    do: %{
      "id" => id,
      "start_s" => t,
      "duration_s" => 10,
      "value" => value,
      "angle_deg" => 0,
      "allowed_assets" => ["a"]
    }

  test "urgent work replaces tentative work, preserves the exact commitment and matches independent enumeration" do
    base =
      Map.put(config(), "requests", [request("committed", 20, 5), request("tentative", 80, 10)])

    policy = Policy.new!(Replacement, max_trials: 4, protected_activities: [pin()])
    before = Cases.plan!(base, policy)
    revised = Map.update!(base, "requests", &(&1 ++ [request("urgent", 80, 20)]))
    after_plan = Cases.plan!(revised, policy)
    assert Cases.oracle(base)["optimal_value"] == 15
    oracle = Cases.oracle(revised)
    assert oracle["optimal_value"] == 25
    assert Enum.any?(oracle["witness"], &(&1["id"] == "committed" and &1["start_s"] == 20))
    diff = Diff.compare!(before, after_plan, [pin()])
    assert diff["baseline_value"] == 15
    assert diff["revised_value"] == 25
    assert diff["counts"] == %{"added" => 1, "removed" => 1, "moved" => 0, "unchanged" => 1}
    assert Enum.find(diff["activities"], &(&1["request_id"] == "committed"))["protected"]
    e = Explanation.from_report!(after_plan, "tentative")
    assert e["summary"]["attempt_reasons"] == %{"asset_conflict" => 1}
    [placement] = e["placements"]
    assert placement["coverage"] == "configured_grid_exhausted"
    [attempt] = placement["attempts"]
    assert [%{"request_id" => "urgent"}] = attempt["conflicting_activities"]
    assert e["search"]["request_trial_evidence"] == "captured"
    assert Enum.all?(e["search"]["trials"], &is_map(&1["request_outcome"]))
    assert after_plan["attitude_planning"]["planning_status"] == "supported"
    # Saved evidence can be explained without rerunning a provider.
    saved = Snapshot.new!(%{"case" => revised}, after_plan)
    assert Explanation.from_report!(saved["payload"]["report"], "tentative") == e
  end

  test "rejected trials retain request outcomes, so a trial selection is not confused with the returned plan" do
    c = Enum.find(Cases.cases(), &(&1["id"] == "maneuver_gap"))
    r = Cases.plan!(c, Policy.new!(Replacement, max_trials: 4, retention: :all_served))
    assert Enum.map(r["activities"], & &1["request_id"]) == ["middle"]
    e = Explanation.from_report!(r, "early")
    assert e["status"] == "unfulfilled"
    assert e["summary"]["selected_in_trial_ids"] != []

    assert Enum.any?(
             e["search"]["trials"],
             &(&1["request_outcome"]["selected"] and &1["reason"] == "lost_served_request" and
                 not &1["accepted"])
           )

    assert e["summary"]["search_status"] in ["trial_limit_reached", "neighborhood_exhausted"]
  end

  defp report(assessment, search \\ :null) do
    %{
      "requests" => [
        %{
          "request_id" => "x",
          "status" => "unfulfilled",
          "reasons" => ["planning_feasibility_unknown"]
        }
      ],
      "opportunities" => [%{"request_id" => "x"}],
      "analyses" => [],
      "scheduling_search" => search,
      "selection_decisions" => [
        %{
          "request_id" => "x",
          "asset_id" => "a",
          "opportunity_id" => "o",
          "resource_ids" => [],
          "reason" => "planning_feasibility_unknown",
          "attitude_assessment" => assessment
        }
      ]
    }
  end

  test "start truncation, unknown checks, evaluation limits and absent historical trial evidence stay distinct" do
    a = %{
      "status" => "unknown",
      "search_truncated" => true,
      "attempts" => [
        %{
          "status" => "unknown",
          "start_s" => 10,
          "reason_code" => "path_constraint_unknown",
          "path_checks" => %{
            "activity" => %{"levels" => [%{"reason" => "path_sample_budget_exhausted"}]}
          }
        }
      ]
    }

    e =
      Explanation.from_report!(
        report(a, %{
          "status" => "trial_limit_reached",
          "trials" => [%{"trial" => 1, "accepted" => true}]
        }),
        "x"
      )

    assert hd(e["placements"])["coverage"] == "start_limit_reached"
    assert e["summary"]["unknown_placement_count"] == 1
    assert e["summary"]["evaluation_limits"] == ["path_sample_budget_exhausted"]
    assert e["search"]["request_trial_evidence"] == "not_captured_in_saved_report"

    assert Explanation.failure_category(
             {:attitude_analysis_failed, "a", "x", :resource_evaluation_budget_exhausted}
           ) == "evaluation_budget_exhausted"

    assert Explanation.failure_category({:tracking_rate_exceeds_limit, 10, 100}) ==
             "planner_error"

    unknown = Explanation.from_report!(report(%{a | "search_truncated" => false}), "x")
    assert hd(unknown["placements"])["coverage"] == "unknown_feasibility"

    no_opportunities =
      report(%{}) |> Map.put("selection_decisions", []) |> Map.put("opportunities", [])

    assert Explanation.from_report!(no_opportunities, "x")["opportunity_count"] == 0

    assert_raise ArgumentError, ~r/unknown request/, fn ->
      Explanation.from_report!(no_opportunities, "bad")
    end
  end

  test "path rule and battery checks retain their identities, margins and epochs" do
    check = %{"id" => "reserve", "status" => "violated", "margin" => -1, "margin_unit" => "Wh"}
    path_check = %{check | "id" => "minimum_angle", "margin_unit" => "deg"}

    a = %{
      "status" => "infeasible_on_tested_start_grid",
      "attempts" => [
        %{
          "status" => "infeasible",
          "start_s" => 10,
          "reason" => ":path_constraint_violated",
          "path_checks" => %{
            "incoming" => %{
              "levels" => [
                %{
                  "first_issue" => %{
                    "epoch_s" => 9,
                    "rules" => [%{"rule_id" => "limb", "checks" => [path_check]}]
                  }
                }
              ]
            }
          },
          "resource_checks" => %{
            "models" => [
              %{
                "id" => "battery",
                "levels" => [%{"first_issue" => %{"evaluated_at_s" => 15, "checks" => [check]}}]
              }
            ]
          }
        }
      ]
    }

    e = Explanation.from_report!(report(a), "x")

    assert Enum.any?(
             e["summary"]["constraint_issues"],
             &(&1["model_id"] == "battery" and &1["epoch_s"] == 15 and &1["margin"] == -1)
           )

    assert Enum.any?(
             e["summary"]["constraint_issues"],
             &(&1["rule_id"] == "limb" and &1["scope"] == "incoming" and &1["epoch_s"] == 9)
           )

    assert e["summary"]["evaluation_limits"] == []
  end
end
