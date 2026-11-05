defmodule OrbitalDynamics.MissionAnalysis.ReactionWheelQualityCases do
  @moduledoc "Declared three-wheel reference cases with scalar independently checkable expected momentum."
  alias OrbitalDynamics.MissionAnalysis.{ReferenceMission}
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Reference, Quaternion}
  alias OrbitalDynamics.MissionAnalysis.Resource.ReactionWheels

  def inputs(id) do
    m = ReferenceMission.load!("studies/wheel_momentum_reference.json")
    s = ReferenceMission.load!("studies/wheel_momentum_planning.json")
    epoch = m["epoch_s"]

    case id do
      "unloaded" ->
        {m, s}

      "saturated" ->
        m = Map.update!(m, "requests", &Enum.reject(&1, fn r -> r["id"] == "unload" end))

        s =
          s
          |> put_in(["scheduling", "protected_activities"], [])
          |> put_in(["path_constraints", "assets", "demo-3", "activity_modes"], %{
            "service" => "work"
          })

        {m, s}

      "feasible_slew" ->
        r =
          m["requests"]
          |> Enum.find(&(&1["id"] == "service"))
          |> Map.put("starts_at_s", epoch + 100)
          |> Map.put("ends_at_s", epoch + 110)
          |> put_in(
            ["parameters", "quaternion_wxyz"],
            Tuple.to_list(Quaternion.increment({0, 0, 60}))
          )

        m = m |> Map.put("duration_s", 200) |> Map.put("requests", [r])

        s =
          s
          |> put_in(["horizon", "ends_at_s"], epoch + 200)
          |> put_in(["scheduling", "protected_activities"], [])
          |> put_in(["path_constraints", "assets", "demo-3", "activity_modes"], %{
            "service" => "work"
          })
          |> update_in(["resources", "assets", "demo-3"], fn models ->
            Enum.map(models, fn model ->
              if model["model"] == "reaction_wheels",
                do:
                  model
                  |> put_in(["configuration", "disturbance_torque_body_nm"], [0, 0, 0])
                  |> put_in(["configuration", "momentum_capacity_nms"], [2, 2, 2]),
                else: model
            end)
          end)

        {m, s}
    end
  end

  def run!(emit \\ fn _, _ -> :ok end) do
    cases =
      for id <- ~w(feasible_slew saturated unloaded) do
        {m, s} = inputs(id)
        r = Reference.run!(m, s)
        emit.("#{id}.json", r)

        [w] =
          Enum.filter(
            r["attitude_planning"]["resource_feasibility"]["assets"]["demo-3"]["models"],
            &(&1["id"] == "wheels")
          )

        expected =
          case id do
            "feasible_slew" -> 0
            "saturated" -> 2
            "unloaded" -> 0.9
          end

        status = if id == "saturated", do: "violated", else: "supported"

        expected_requests =
          case id do
            "feasible_slew" -> ["service"]
            "saturated" -> []
            "unloaded" -> ["unload", "service"]
          end

        requests = Enum.map(r["activities"], & &1["request_id"])

        slew_peak_correct =
          id != "feasible_slew" or
            Enum.all?(w["levels"], fn level ->
              extrema = level["state_extrema"]["wheel_3_momentum_nms"]
              expected_peak = 50 * 2 * :math.pi() / 180

              abs(extrema["max"] - expected_peak) < 1.0e-8 and
                abs(extrema["min"] + expected_peak) < 1.0e-8
            end)

        good =
          r["attitude_planning"]["planning_status"] == status and
            requests == expected_requests and slew_peak_correct and
            Enum.all?(
              w["levels"],
              &(abs(elem(ReactionWheels.vector(&1["final_state"]), 2) - expected) < 1.0e-8)
            )

        %{
          "id" => id,
          "passed" => good,
          "planning_status" => r["attitude_planning"]["planning_status"],
          "expected_final_wheel_3_nms" => expected,
          "scheduled_request_ids" => requests,
          "wheel_levels" => Enum.map(w["levels"], &Map.drop(&1, ["samples"])),
          "report_file" => "#{id}.json"
        }
      end

    %{
      "format" => "reaction_wheel_quality_cases.v1",
      "status" => if(Enum.all?(cases, & &1["passed"]), do: "passed", else: "failed"),
      "cases" => cases,
      "limits" =>
        "scalar expectations are exact only for these prescribed principal-axis/zero-rate motions and constant declared external torques; no spacecraft validation"
    }
  end
end
