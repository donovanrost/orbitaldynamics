defmodule OrbitalDynamics.MissionAnalysis.VerificationBaseline do
  @moduledoc """
  Reviewable baseline combining separately scoped numerical evidence and frozen scenarios.
  No verification group promotes the model to flight readiness or authenticates hardware assumptions.
  """
  alias OrbitalDynamics.MissionAnalysis.{AttitudePathCheck, BaselineCheck, ReferenceMission}
  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference

  def verify do
    with {:ok, orbit} <- BaselineCheck.verify(), {:ok, numerics} <- AttitudePathCheck.verify() do
      # AttitudePathCheck admits every scenario byte before these regressions execute.
      dir = AttitudePathCheck.bundle_path()
      mission = ReferenceMission.load!(Path.join(dir, "mission.json"))
      scenarios = dir |> Path.join("scenarios.json") |> File.read!() |> :json.decode()

      rows =
        Enum.map(scenarios, fn c ->
          study = ReferenceMission.load!(Path.join(dir, c["study"]))
          report = Reference.run!(mission, study)
          actual = report["activities"]

          request_identity =
            Enum.sort(Enum.map(report["requests"], & &1["request_id"])) ==
              Enum.sort(Enum.map(mission["requests"], & &1["id"]))

          identity = request_identity and Enum.map(actual, & &1["request_id"]) == c["request_ids"]

          deltas =
            if identity do
              Enum.zip([c["starts_after_s"], c["ends_after_s"]], ["starts_at_s", "ends_at_s"])
              |> Enum.flat_map(fn {expected, key} ->
                Enum.zip_with(actual, expected, fn a, t ->
                  abs(a[key] - mission["epoch_s"] - t)
                end)
              end)
            else
              []
            end

          maximum = Enum.max(deltas, fn -> 0.0 end)

          unknown_correct =
            if c["id"] == "unknown-optics",
              do:
                request_identity and
                  Enum.all?(
                    report["requests"],
                    &("attitude_feasibility_unknown" in &1["reasons"] and
                        has_rule_status?(report, &1["request_id"], "reflected_beam", "unknown"))
                  ),
              else: true

          rejection_correct =
            if c["id"] == "path-rejected-transition" do
              decision =
                Enum.find(
                  report["selection_decisions"],
                  &(&1["request_id"] == "illumination-primary")
                )

              Enum.any?(decision["attitude_assessment"]["attempts"], fn attempt ->
                case get_in(attempt, ["path_checks", "incoming", "levels"]) do
                  nil ->
                    false

                  levels ->
                    Enum.any?(levels, fn level ->
                      issue = level["first_issue"]

                      is_map(issue) and
                        Enum.any?(
                          issue["rules"],
                          &(&1["rule_id"] == "limb_axis" and &1["status"] == "violated")
                        )
                    end)
                end
              end)
            else
              true
            end

          %{
            "id" => c["id"],
            "status" =>
              if(identity and maximum <= 0.01 and unknown_correct and rejection_correct,
                do: "pass",
                else: "fail"
              ),
            "selected_request_ids" => Enum.map(actual, & &1["request_id"]),
            "request_identity_passed" => request_identity,
            "max_endpoint_delta_s" => maximum,
            "endpoint_tolerance_s" => 0.01,
            "requests" => report["requests"],
            "unknown_optics_preserved" => unknown_correct,
            "expected_path_rejection_present" => rejection_correct,
            "classification" => "internal_end_to_end_regression_not_external_validation"
          }
        end)

      scenario_status = if Enum.all?(rows, &(&1["status"] == "pass")), do: "pass", else: "fail"

      passed =
        orbit["status"] == "pass" and numerics["status"] == "pass" and scenario_status == "pass"

      {:ok,
       %{
         "format" => "mission_verification_baseline.v1",
         "baseline_id" => "reference_mission_numerical_baseline.v1",
         "status" => if(passed, do: "pass", else: "fail"),
         "execution_boundary" => "analysis_only_no_command_execution",
         "orbit_geometry" => orbit,
         "attitude_path_numerics" => numerics,
         "frozen_scenarios" => %{"status" => scenario_status, "cases" => rows},
         "limits" => [
           "independent numerical comparisons and internal regressions are separate evidence groups",
           "no true hardware specifications, achieved attitude, cloud/terrain, mode mechanism or continuous safety validation",
           "no source-data/frame-time accuracy or constellation service coverage promotion",
           "all clearances are relative to the stated ideal model and sampled test cases",
           "bundle identity binds checked-in bytes; it is not authority authentication or a release approval"
         ]
       }}
    end
  end

  defp has_rule_status?(report, request_id, rule, status) do
    report["selection_decisions"]
    |> Enum.filter(&(&1["request_id"] == request_id))
    |> Enum.any?(fn d ->
      Map.get(d["attitude_assessment"], "attempts", [])
      |> Enum.any?(fn attempt ->
        Map.get(attempt, "path_checks", %{})
        |> Map.values()
        |> Enum.any?(fn e ->
          Map.get(e, "levels", [])
          |> Enum.any?(fn level ->
            issue = level["first_issue"]

            is_map(issue) and
              Enum.any?(
                Map.get(issue, "rules", []),
                &(&1["rule_id"] == rule and &1["status"] == status)
              )
          end)
        end)
      end)
    end)
  end

  def markdown(report) do
    numerical = report["attitude_path_numerics"]
    groups = numerical["groups"]

    rows =
      Enum.map(Enum.sort(groups), fn {name, g} ->
        "| #{name} | #{g["case_count"]} | #{g["status"]} |"
      end)

    metrics =
      Enum.flat_map(Enum.sort(groups), fn {name, g} ->
        Enum.map(Enum.sort(g["measurements"]), fn {metric, v} ->
          "| #{name}/#{metric} | #{v["max_error"]} | #{v["tolerance"]} |"
        end)
      end)

    beam = groups["beam_geometry"]

    "# Reference mission numerical baseline\n\nOverall: **#{report["status"]}**. Baseline: `#{report["baseline_id"]}`.\n\n" <>
      "Independent orbit comparison: #{report["orbit_geometry"]["status"]}. Internal frozen scenario regressions: #{report["frozen_scenarios"]["status"]}.\n\n" <>
      Enum.join(["| Numerical group | Cases | Result |", "| --- | --- | --- |"] ++ rows, "\n") <>
      "\n\n" <>
      Enum.join(
        [
          "| Measurement (unit in name) | Maximum difference | Acceptance tolerance |",
          "| --- | --- | --- |"
        ] ++ metrics,
        "\n"
      ) <>
      "\n\nThe ODE group has #{groups["phase_ode"]["sample_count"]} samples, checks requested terminal orientations/rates and complete epoch coverage. " <>
      "Its controls are production-exported inputs; the separate library/Brent calculation checks the declared transition-construction duration.\n\n" <>
      "Direct sampled-overlap false clears: **#{beam["direct_witness_false_clear_count"]}**, across #{beam["reflecting_cases_with_direct_witnesses"]} declared-reflecting cases with direct solar witnesses. " <>
      "Modeled-cone sampled-overlap false clears: #{beam["modeled_cone_false_clear_count"]}. " <>
      "Guard rejections without sampled cone witnesses: #{beam["guard_rejections_without_sampled_witness"]}; these are not proven false positives.\n\n" <>
      Enum.map_join(
        report["frozen_scenarios"]["cases"],
        "\n",
        &("- " <> &1["id"] <> ": " <> &1["status"] <> " (internal regression)")
      ) <>
      "\n\n[report.json](report.json) contains per-case measurements, tolerances, frozen source identities and evidence limits. " <>
      "No-witness results do not establish non-overlap, and finite cases do not establish continuous safety or flight readiness.\n"
  end
end
