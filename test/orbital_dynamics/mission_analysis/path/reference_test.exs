defmodule OrbitalDynamics.MissionAnalysis.Path.ReferenceTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference

  test "reference example rejects a kinematically eligible request with path evidence and rechecks final transitions" do
    study =
      ReferenceMission.load!("studies/illumination_path.json")
      |> put_in(["path_constraints", "sample_steps_s"], [5, 1])

    mission =
      ReferenceMission.load!("studies/reference_attitude.json") |> Map.put("duration_s", 250)

    report = Reference.run!(mission, study)
    assert length(report["activities"]) == 1
    [a] = report["activities"]
    assert a["path_evidence"]["status"] == "supported"

    assert Enum.all?(
             report["attitude_planning"]["transitions"],
             &(&1["path_evidence"]["status"] == "supported")
           )

    rejected = Enum.find(report["requests"], &(&1["request_id"] == "illumination-primary"))
    assert rejected["opportunity_count"] > 0
    assert rejected["status"] == "unfulfilled"

    decision =
      Enum.find(report["selection_decisions"], &(&1["request_id"] == "illumination-primary"))

    assert Enum.any?(decision["attitude_assessment"]["attempts"], fn a ->
             a["path_checks"] |> Map.values() |> Enum.any?(&(&1["status"] == "violated"))
           end)

    assert report == report |> :json.encode() |> IO.iodata_to_binary() |> :json.decode()
    captured = report["attitude_planning"]["path_constraints"]["captured_rules"]
    assert Enum.any?(captured, &(&1["rule_id"] == "reflected_beam"))
  end
end
