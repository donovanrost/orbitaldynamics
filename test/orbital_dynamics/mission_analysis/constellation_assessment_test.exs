defmodule OrbitalDynamics.MissionAnalysis.ConstellationAssessmentTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.{ConstellationAssessment, ReferenceMission}
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Prediction, Advance}
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Checker

  test "portfolio artifacts count original completions rather than continuation segments and resist overwrites" do
    dir =
      Path.join(
        System.tmp_dir!(),
        "constellation-assessment-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(dir) end)

    File.mkdir_p!(dir)
    script = ReferenceMission.load!("studies/thermal_cooldown_operations.json")

    revision = %{
      "id" => "review_running",
      "kind" => "revise",
      "expected_status" => "ready_for_review",
      "change" => %{
        "revision_id" => "review_running",
        "protect_request_ids" => [],
        "add_requests" => [],
        "unavailable_asset_ids" => [],
        "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
      }
    }

    script =
      script
      |> Map.put("mission_manifest", Path.expand("studies/thermal_cooldown_reference.json"))
      |> Map.put("planning_study", Path.expand("studies/thermal_cooldown_planning.json"))
      |> Map.update!("steps", &List.insert_at(&1, 1, revision))

    scenario = Path.join(dir, "scenario.json")
    File.write!(scenario, :json.encode(script))
    output = Path.join(dir, "output")

    config = %{
      "assessment_id" => "thermal_fixture",
      "cases" => [
        %{
          "id" => "thermal",
          "scenario" => scenario,
          "expected_independent_status" => "passed"
        }
      ]
    }

    report =
      ConstellationAssessment.run!(
        config,
        Path.expand("studies/constellation_assessment.json"),
        output
      )

    assert report["status"] == "expectations_met"
    [row] = report["cases"]
    assert row["cycle_count"] == 5
    assert row["simulated_completed_service_count"] == 1
    assert row["completed_service_count"] == 1
    assert row["completed_service_value"] == 10
    assert row["completed_maintenance_count"] == 1
    assert row["completed_maintenance_duration_s"] == 20
    assert row["planning_callback_total"] > 0
    assert row["independent_validation"] == "passed"
    assert File.exists?(Path.join(output, "thermal/step-01-execution_snapshot.json"))
    saved = File.read!(Path.join(output, "assessment.json"))

    assert_raise Mix.Error, fn ->
      ConstellationAssessment.run!(
        config,
        Path.expand("studies/constellation_assessment.json"),
        output
      )
    end

    assert File.read!(Path.join(output, "assessment.json")) == saved
  end

  test "failed revision preserves structured whole-search work and never adopts a partial candidate" do
    m = ReferenceMission.load!("studies/thermal_cooldown_reference.json")
    s = ReferenceMission.load!("studies/thermal_cooldown_planning.json")
    root = Reference.create!(m, s)

    update =
      Prediction.update!(root, 820_497_690)
      |> put_in(["scheduling", "work_budget"], %{"max_evaluations" => 1})

    result = Advance.run!(root, update)
    assert result.review["status"] == "planning_failed"
    assert result.revised_snapshot == :null
    assert result.review["planning_failure_category"] == "evaluation_budget_exhausted"
    assert result.review["planning_work"]["total_evaluations"] == 1
    assert result.review["planning_work"]["budget_exhausted"]
  end

  test "independent thermal accounting accepts differently named idle and terminal modes with identical heat inputs" do
    m = ReferenceMission.load!("studies/thermal_cooldown_reference.json")
    s = ReferenceMission.load!("studies/thermal_cooldown_planning.json")
    idle = s["path_constraints"]["assets"]["demo-3"]["modes"]["idle"]

    s =
      put_in(s, ["path_constraints", "assets", "demo-3", "modes", "terminal_alias"], idle)
      |> put_in(["horizon", "terminals", "demo-3", "mode"], "terminal_alias")

    assert Checker.snapshot(Reference.create!(m, s))["status"] == "passed"
  end
end
