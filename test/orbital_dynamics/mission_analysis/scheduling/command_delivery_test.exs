defmodule OrbitalDynamics.MissionAnalysis.Scheduling.CommandDeliveryTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Prediction, Advance}
  alias OrbitalDynamics.MissionAnalysis.Scheduling.CommandDelivery
  alias OrbitalDynamics.MissionAnalysis.Operations.Scenario
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Checker, Operations}
  alias OrbitalDynamics.IndependentPlanFixture, as: F
  @t 820_497_600
  defp config do
    %{
      "time_scale" => "utc",
      "source_id" => "declared_contacts",
      "contacts" => [
        %{
          "id" => "cmd",
          "type" => "command",
          "scenario_id" => "demo-3",
          "ground_station_id" => "station",
          "starts_at_s" => @t + 50,
          "ends_at_s" => @t + 55,
          "source_window_id" => "declared_window",
          "score" => 10
        }
      ],
      "station_calendar" => [],
      "requirements" => [
        %{
          "request_id" => "service",
          "minimum_contact_duration_s" => 5,
          "lead_time_s" => 10,
          "deadline_s" => @t + 65,
          "contact_ids" => ["cmd"]
        }
      ],
      "receipts" => []
    }
  end

  defp inputs(c \\ config()) do
    m = ReferenceMission.load!("studies/automatic_wheel_maintenance.json")
    s = ReferenceMission.load!("studies/automatic_wheel_maintenance_planning.json")
    {m, put_in(s, ["scheduling", "command_delivery"], c)}
  end

  defp step(id, t),
    do: %{
      "id" => id,
      "kind" => "advance",
      "expected_status" => "ready_for_review",
      "as_of_s" => @t + t,
      "not_executed_request_ids" => [],
      "energy_losses_wh" => %{},
      "protect_request_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
    }

  test "existing allocation and command-window contracts provide an eligible prerequisite" do
    a = CommandDelivery.allocation(config())
    assert Enum.map(a.contacts, & &1["id"]) == ["cmd"]
    assert a.report["contact_allocation"]["schema_contract"] == "contact_allocation_report.v1"
    assert a.report["command_windows"]["schema_contract"] == "command_window_report.v1"
    assert a.report["command_windows"]["invalid_activity_input_count"] == 0
    {m, s} = inputs()
    root = Reference.create!(m, s)
    assert Enum.any?(root["payload"]["report"]["activities"], &(&1["request_id"] == "service"))
    assert Checker.snapshot(root)["status"] == "passed"
  end

  test "station outages, too-short contacts and missed command deadlines withhold service" do
    for c <- [
          put_in(config(), ["station_calendar"], [
            %{
              "ground_station_id" => "station",
              "status" => "unavailable",
              "starts_at_s" => @t + 49,
              "ends_at_s" => @t + 56
            }
          ]),
          put_in(config(), ["requirements", Access.at(0), "minimum_contact_duration_s"], 6),
          put_in(config(), ["requirements", Access.at(0), "deadline_s"], @t + 54)
        ] do
      {m, s} = inputs(c)
      root = Reference.create!(m, s)
      refute Enum.any?(root["payload"]["report"]["activities"], &(&1["request_id"] == "service"))
    end
  end

  test "same station and spacecraft contention are delegated to the existing allocator" do
    c = config()
    first = hd(c["contacts"])

    rival =
      Map.merge(first, %{
        "id" => "rival",
        "scenario_id" => "other",
        "score" => 1,
        "source_window_id" => "other_window"
      })

    c = Map.put(c, "contacts", [first, rival])
    assert Enum.map(CommandDelivery.allocation(c).contacts, & &1["id"]) == ["cmd"]
    # Adjacent half-open reservations do not contend.
    c =
      put_in(c, ["contacts", Access.at(1), "starts_at_s"], @t + 55)
      |> put_in(["contacts", Access.at(1), "ends_at_s"], @t + 60)

    assert length(CommandDelivery.allocation(c).contacts) == 2
  end

  test "past planned contact requires an explicit receipt and a running task keeps its command history" do
    {m, s} = inputs()
    root = Reference.create!(m, s)
    u = Prediction.update!(root, @t + 60)
    assert hd(u["command_receipts"])["kind"] == "synthetic_prediction"
    good = Advance.run!(root, u)
    assert good.review["status"] == "ready_for_review"

    without = Advance.run!(root, Map.delete(u, "command_receipts"))
    refute Enum.any?(without.candidate_report["activities"], &(&1["request_id"] == "service"))

    bad = put_in(u, ["command_receipts", Access.at(0), "delivered_at_s"], @t + 56)
    assert_raise ArgumentError, fn -> Advance.run!(root, bad) end
    c = good.revised_snapshot
    running = Advance.run!(c, Prediction.update!(c, @t + 75))
    assert running.review["status"] == "ready_for_review"

    assert running.revised_snapshot["payload"]["inputs"]["study"]["scheduling"][
             "command_delivery"
           ]["receipts"] ==
             c["payload"]["inputs"]["study"]["scheduling"]["command_delivery"]["receipts"]
  end

  test "synthetic contact execution survives replay and independent checks" do
    {m, s} = inputs()

    script = %{
      "scenario_id" => "commands",
      "mission_manifest" => "synthetic.json",
      "planning_study" => "synthetic_planning.json",
      "steps" => [step("received", 60), step("running", 75), step("completed", 90)]
    }

    Process.put(:artifacts, %{})

    r =
      Scenario.run!(m, s, script, fn name, v ->
        Process.put(:artifacts, Map.put(Process.get(:artifacts), name, v))
      end)

    assert r["verification_status"] == "passed"
    assert Operations.validate(r, F.load(Process.get(:artifacts)))["status"] == "passed"
  end

  test "independent checks reject rehashed missed deadlines, absent receipts and continued original-start violations" do
    {m, s} = inputs()
    root = Reference.create!(m, s)

    bad =
      put_in(
        root,
        [
          "payload",
          "inputs",
          "study",
          "scheduling",
          "command_delivery",
          "requirements",
          Access.at(0),
          "deadline_s"
        ],
        @t + 54
      )
      |> F.bind()

    assert Enum.any?(Checker.snapshot(bad)["issues"], &(&1["code"] == "command_prerequisite"))
    child = Advance.run!(root, Prediction.update!(root, @t + 75)).revised_snapshot
    assert Checker.snapshot(child)["status"] == "passed"

    bad =
      put_in(
        child,
        ["payload", "inputs", "study", "scheduling", "command_delivery", "receipts"],
        []
      )
      |> F.bind()

    assert Enum.any?(Checker.snapshot(bad)["issues"], &(&1["code"] == "command_prerequisite"))
    # Ready at 73 is before the tail boundary, but after the immutable original start at 70.
    bad =
      put_in(
        child,
        [
          "payload",
          "inputs",
          "study",
          "scheduling",
          "command_delivery",
          "requirements",
          Access.at(0),
          "lead_time_s"
        ],
        18
      )
      |> F.bind()

    assert Enum.any?(Checker.snapshot(bad)["issues"], &(&1["code"] == "command_prerequisite"))
  end

  test "allocated command contacts reserve spacecraft time against unrelated maintenance" do
    c =
      config()
      |> put_in(["contacts", Access.at(0), "starts_at_s"], @t + 27)
      |> put_in(["contacts", Access.at(0), "ends_at_s"], @t + 32)

    {m, s} = inputs(c)
    root = Reference.create!(m, s)
    unload = Enum.find(root["payload"]["report"]["activities"], &(&1["request_id"] == "unload"))
    assert unload["starts_at_s"] >= @t + 32
    assert Checker.snapshot(root)["status"] == "passed"
  end
end
