defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.ReferenceTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Snapshot}
  alias OrbitalDynamics.MissionAnalysis.Scheduling.Commitments

  setup_all do
    mission =
      ReferenceMission.load!("studies/repeated_service.json")
      |> Map.put("duration_s", 250)
      |> Map.update!("assets", &Enum.take(&1, 1))
      |> Map.update!("requests", &Enum.take(&1, 1))

    study = ReferenceMission.load!("studies/repeated_service_planning.json")

    study =
      Enum.reduce(
        [
          ["attitude", "assets"],
          ["path_constraints", "assets"],
          ["resources", "assets"],
          ["horizon", "terminals"]
        ],
        study,
        fn path, c -> update_in(c, path, &Map.take(&1, ["demo-1"])) end
      )

    study = put_in(study, ["horizon", "ends_at_s"], mission["epoch_s"] + 250)

    study =
      put_in(study, ["path_constraints", "assets", "demo-1", "activity_modes"], %{
        "early-1" => "reflecting"
      })

    snapshot = Reference.create!(mission, study)
    {:ok, snapshot: snapshot, mission: mission, study: study}
  end

  defp change,
    do: %{
      "revision_id" => "test_revision",
      "protect_request_ids" => [],
      "add_requests" => [],
      "unavailable_asset_ids" => [],
      "scheduling" => %{"strategy" => "bounded_replacement", "max_trials" => 2}
    }

  test "same-horizon no-op creates a source-linked child and leaves baseline immutable", %{
    snapshot: s
  } do
    before = :json.encode(s) |> IO.iodata_to_binary()
    result = Reference.revise!(s, %{change() | "protect_request_ids" => ["early-1"]})
    assert result.review["status"] == "ready_for_review"
    assert result.review["diff"]["counts"]["unchanged"] == 1
    assert result.revised_snapshot["payload"]["parent_snapshot_id"] == s["snapshot_id"]
    assert :json.encode(s) |> IO.iodata_to_binary() == before

    assert result.revised_snapshot["payload"]["inputs"]["mission"] ==
             s["payload"]["inputs"]["mission"]

    assert result.revised_snapshot["payload"]["inputs"]["study"]["horizon"] ==
             s["payload"]["inputs"]["study"]["horizon"]

    assert Commitments.intact?(
             result.candidate_report["activities"],
             result.review["protected_activities"]
           )

    assert Snapshot.verify!(result.revised_snapshot) == result.revised_snapshot
    # Inherited commitments cannot be released by omitting them from the next change.
    conflict =
      Reference.revise!(
        result.revised_snapshot,
        %{change() | "unavailable_asset_ids" => ["demo-1"]},
        fn _, _, _ -> flunk("conflict must be detected before planning") end
      )

    assert conflict.review["status"] == "commitment_conflict"
  end

  test "whole-horizon service outage leaves spacecraft physics modeled and records removed work",
       %{snapshot: s} do
    result = Reference.revise!(s, %{change() | "unavailable_asset_ids" => ["demo-1"]})
    assert result.review["status"] == "ready_for_review"
    assert result.candidate_report["activities"] == []
    assert result.review["diff"]["counts"]["removed"] == 1
    assert result.review["diff"]["unfulfilled_requests"] != []

    assert result.candidate_report["attitude_planning"]["resource_feasibility"]["assets"][
             "demo-1"
           ]["status"] == "supported"

    assert result.candidate_report["service_unavailability"]["asset_ids"] == ["demo-1"]
    restored = Reference.revise!(result.revised_snapshot, change())
    assert restored.review["status"] == "ready_for_review"
    assert restored.review["service_availability_changes"]["restored"] == ["demo-1"]
    assert restored.review["diff"]["counts"]["added"] == 1
  end

  test "unavailable committed work is an explicit conflict with no new snapshot or planner call",
       %{snapshot: s} do
    c = %{change() | "protect_request_ids" => ["early-1"], "unavailable_asset_ids" => ["demo-1"]}

    result =
      Reference.revise!(s, c, fn _, _, _ -> flunk("must not plan a known commitment conflict") end)

    assert result.review["status"] == "commitment_conflict"

    assert [%{"kind" => "protected_service_unavailable"}] =
             Enum.map(result.review["conflicts"], &Map.take(&1, ["kind"]))

    assert result.revised_snapshot == :null and result.candidate_report == :null
    assert result.review["diff"] == :null
  end

  test "new urgent request has explicit modes and may replace tentative work", %{
    snapshot: s,
    mission: m
  } do
    urgent = hd(m["requests"]) |> Map.put("id", "urgent") |> Map.put("value", 100)

    c = %{
      change()
      | "add_requests" => [
          %{"request" => urgent, "activity_modes" => %{"demo-1" => "reflecting"}}
        ]
    }

    result = Reference.revise!(s, c)
    assert result.review["status"] == "ready_for_review"
    assert result.review["diff"]["new_request_ids"] == ["urgent"]
    assert result.review["diff"]["value_delta"] > 0
    assert Enum.any?(result.candidate_report["activities"], &(&1["request_id"] == "urgent"))
    assert length(result.revised_snapshot["payload"]["inputs"]["mission"]["requests"]) == 2
  end

  test "malformed or incompatible changes are rejected before planning", %{
    snapshot: s,
    mission: m
  } do
    bads = [
      Map.put(change(), "horizon", %{}),
      Map.put(change(), "expected_baseline_id", "wrong"),
      %{change() | "protect_request_ids" => ["not_selected"]},
      %{change() | "unavailable_asset_ids" => ["unknown"]},
      %{
        change()
        | "add_requests" => [
            %{"request" => hd(m["requests"]), "activity_modes" => %{"demo-1" => "reflecting"}}
          ]
      },
      %{
        change()
        | "add_requests" => [
            %{
              "request" => Map.put(hd(m["requests"]), "id", "new"),
              "activity_modes" => %{"demo-1" => "undeclared"}
            }
          ]
      }
    ]

    for bad <- bads do
      assert_raise ArgumentError, fn ->
        Reference.revise!(s, bad, fn _, _, _ -> flunk("invalid change reached planner") end)
      end
    end
  end

  test "unknown/violated candidate evidence and provider errors never create a usable child", %{
    snapshot: s
  } do
    for status <- ["unknown", "violated"] do
      planner = fn m, study, _ ->
        report =
          s["payload"]["report"]
          |> Map.put("baseline_configuration", m)
          |> Map.put("attitude_study_configuration", study)
          |> put_in(["attitude_planning", "planning_status"], status)

        {:ok, report, %{}}
      end

      r = Reference.revise!(s, change(), planner)
      assert r.review["status"] == "unsupported_revision" and r.revised_snapshot == :null
      assert r.candidate_report["attitude_planning"]["planning_status"] == status
    end

    r = Reference.revise!(s, change(), fn _, _, _ -> {:error, :provider_down} end)
    assert r.review["status"] == "planning_failed" and r.revised_snapshot == :null
    assert r.review["planning_error"] =~ "provider_down"
    assert r.review["planning_failure_category"] == "planner_error"

    for budget <- [
          :attitude_evaluation_budget_exhausted,
          :path_evaluation_budget_exhausted,
          :resource_evaluation_budget_exhausted
        ] do
      r =
        Reference.revise!(s, change(), fn _, _, _ ->
          {:error, {:attitude_analysis_failed, "demo-1", "early-1", budget}}
        end)

      assert r.review["status"] == "planning_failed"
      assert r.review["planning_failure_category"] == "evaluation_budget_exhausted"
      assert r.revised_snapshot == :null
    end
  end

  test "revision's independent commitment guard rejects a falsely supported moved candidate", %{
    snapshot: s
  } do
    planner = fn m, study, _ ->
      report =
        s["payload"]["report"]
        |> Map.put("baseline_configuration", m)
        |> Map.put("attitude_study_configuration", study)

      report =
        update_in(report, ["activities", Access.at(0), "starts_at_s"], &(&1 + 1))
        |> update_in(["activities", Access.at(0), "ends_at_s"], &(&1 + 1))

      {:ok, report, %{}}
    end

    r = Reference.revise!(s, %{change() | "protect_request_ids" => ["early-1"]}, planner)
    assert r.review["status"] == "commitment_conflict" and r.revised_snapshot == :null
  end
end
