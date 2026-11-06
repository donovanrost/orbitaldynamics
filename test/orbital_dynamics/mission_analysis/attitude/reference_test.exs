defmodule OrbitalDynamics.MissionAnalysis.Attitude.ReferenceTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Vector3}
  alias OrbitalDynamics.MissionAnalysis.{ReferenceMission, SphericalScene}
  alias OrbitalDynamics.MissionAnalysis.Models.{Imaging, Illumination}
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Reference, Quaternion}

  defp inputs do
    mission =
      ReferenceMission.load!("studies/reference_attitude.json") |> Map.put("duration_s", 250)

    study = ReferenceMission.load!("studies/illumination_attitude.json")
    {mission, study}
  end

  test "diagnostic retention option rejects non-boolean values before preparing a mission" do
    for value <- [nil, "false", 0] do
      assert_raise ArgumentError, ~r/include_samples must be boolean/, fn ->
        Reference.run!(%{}, %{}, include_samples: value)
      end
    end
  end

  test "real two-request example reserves acquisition and transitions with reproducible endpoint evidence" do
    {mission, study} = inputs()
    report = Reference.run!(mission, study)
    assert report == Reference.run!(mission, study)
    assert length(report["activities"]) == 2
    [first, second] = report["activities"]
    assert first["starts_at_s"] > mission["epoch_s"] + 1
    assert second["starts_at_s"] > first["ends_at_s"]
    [_, transition] = report["attitude_planning"]["transitions"]
    assert transition["required_s"] <= transition["available_s"]
    assert transition["time_margin_s"] >= 0
    assert transition["terminal_orientation_residual_deg"] < 1.0e-8

    for a <- report["activities"] do
      assert Enum.all?(a["endpoint_samples"], & &1["feasible"])
      assert a["attitude_frame"]["name"] == "eci_j2000"

      assert Enum.all?(
               a["attitude_profile"],
               &(&1["rate_deg_s"] <= 2 and &1["accel_deg_s2"] <= 0.2)
             )
    end

    assert report == report |> :json.encode() |> IO.iodata_to_binary() |> :json.decode()
  end

  test "unknown initial state preserves physical opportunities but does not assume acquisition" do
    {mission, study} = inputs()
    study = put_in(study, ["attitude", "assets", "demo-1", "initial"], :null)
    report = Reference.run!(mission, study)
    assert report["activities"] == []
    assert Enum.all?(report["requests"], &(&1["opportunity_count"] > 0))

    assert Enum.all?(
             report["selection_decisions"],
             &(&1["attitude_assessment"]["reason"] == "initial_attitude_unknown")
           )
  end

  test "illumination and imaging provide required full orientations through the same callback" do
    config = %{
      "body_to_payload_quaternion" => [1, 0, 0, 0],
      "roll_reference_inertial" => [0, 0, 1]
    }

    for {name, model} <- [{"illumination", Illumination}, {"imaging", Imaging}] do
      p = ReferenceMission.prepare!(ReferenceMission.load!("studies/reference_#{name}.json"))
      [asset] = p.assets
      [r] = p.requests
      state = Enum.at(asset.trajectory.states, 1)
      {:ok, session, _} = model.prepare(r, asset.capabilities[model], p.context)
      assert {:ok, pose} = model.pointing(state, session, config)
      {:ok, scene} = SphericalScene.at(p.context, state, r.subject)

      expected =
        if model == Illumination, do: Illumination.normal(scene), else: scene.target_direction

      assert Vector3.norm(
               Vector3.subtract(Quaternion.rotate(pose.quaternion, {0, 0, 1}), expected)
             ) < 1.0e-12
    end
  end
end
