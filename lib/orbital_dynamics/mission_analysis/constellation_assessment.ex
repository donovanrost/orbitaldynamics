defmodule OrbitalDynamics.MissionAnalysis.ConstellationAssessment do
  @moduledoc "Bounded reference-mission operations portfolio and evidence summary. Does not promote unsupported validation or establish operational readiness."
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission, as: M
  alias OrbitalDynamics.MissionAnalysis.Operations.{Scenario, Report}
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Operations, as: Independent
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Report, as: ValidationReport
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Files
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: S
  alias OrbitalDynamics.MissionAnalysis.Input

  def run!(config, path, directory) do
    S.fields!(config, ~w(assessment_id cases), "constellation assessment")
    Input.id!(config["assessment_id"])

    unless is_list(config["cases"]) and length(config["cases"]) in 1..8 and
             length(Enum.uniq_by(config["cases"], & &1["id"])) == length(config["cases"]),
           do: raise(ArgumentError, "assessment requires 1..8 unique cases")

    specs =
      Enum.map(config["cases"], fn c ->
        S.fields!(c, ~w(id scenario expected_independent_status), "assessment case")
        Input.id!(c["id"])

        unless c["expected_independent_status"] in ~w(passed partial) and is_binary(c["scenario"]),
          do: raise(ArgumentError, "explicit independent scope expectation and scenario required")

        scenario = Path.expand(c["scenario"], Path.dirname(path))
        script = M.load!(scenario) |> Scenario.validate!()
        mission_path = Path.expand(script["mission_manifest"], Path.dirname(scenario))
        study_path = Path.expand(script["planning_study"], Path.dirname(scenario))

        %{
          spec: c,
          script: script,
          mission: M.load!(mission_path),
          study: M.load!(study_path),
          paths: [scenario, mission_path, study_path]
        }
      end)

    names =
      ["assessment.json", "README.md"] ++
        Enum.flat_map(specs, fn c ->
          Enum.map(
            Scenario.artifact_names(c.script) ++ ["validation.json", "validation.md"],
            &Path.join(c.spec["id"], &1)
          )
        end)

    directory = Files.directory!(directory, names, [path | Enum.flat_map(specs, & &1.paths)])
    File.mkdir_p!(directory)

    rows =
      Enum.map(specs, fn c ->
        sub = Path.join(directory, c.spec["id"])
        File.mkdir_p!(sub)
        key = {__MODULE__, make_ref()}
        Process.put(key, %{})

        try do
          emit = fn name, value ->
            File.write!(Path.join(sub, name), [:json.encode(value), "\n"], [:exclusive])
            Process.put(key, Map.put(Process.get(key), name, value))
          end

          started = System.monotonic_time()
          operations = Scenario.run!(c.mission, c.study, c.script, emit)
          artifacts = Process.get(key)

          validation =
            Independent.validate(operations, fn name ->
              case Map.fetch(artifacts, name) do
                {:ok, x} -> {:ok, x}
                :error -> {:error, "missing assessment artifact"}
              end
            end)

          emit.("operations.json", operations)
          File.write!(Path.join(sub, "README.md"), Report.markdown(operations), [:exclusive])
          emit.("validation.json", validation)

          File.write!(
            Path.join(sub, "validation.md"),
            ValidationReport.markdown(Map.put(validation, "source", c.spec["id"])),
            [:exclusive]
          )

          summary(operations, artifacts)
          |> Map.merge(%{
            "id" => c.spec["id"],
            "scenario" => c.spec["scenario"],
            "native_verification" => operations["verification_status"],
            "independent_validation" => validation["status"],
            "expected_independent_status" => c.spec["expected_independent_status"],
            "independent_issue_counts" => Enum.frequencies_by(validation["issues"], & &1["code"]),
            "expectation_met" =>
              operations["verification_status"] == "passed" and
                validation["status"] == c.spec["expected_independent_status"],
            "observed_elapsed_ms" =>
              System.convert_time_unit(System.monotonic_time() - started, :native, :microsecond) /
                1000
          })
        after
          Process.delete(key)
        end
      end)

    report = %{
      "format" => "reference_constellation_assessment.v1",
      "assessment_id" => config["assessment_id"],
      "status" =>
        if(Enum.all?(rows, & &1["expectation_met"]), do: "expectations_met", else: "failed"),
      "cases" => rows,
      "scope" =>
        "synthetic reference missions; expected partial independent validation is retained as partial, never promoted to passed",
      "limitations" => [
        "invented spacecraft/communications/thermal parameters; no company design validation",
        "finite sampled feasibility and bounded search; no optimality guarantee",
        "no command execution, authentic telemetry or flight readiness claim",
        "work counts exclude trajectory preparation, opportunity discovery and independent checking; elapsed times are observations"
      ]
    }

    File.write!(Path.join(directory, "assessment.json"), [:json.encode(report), "\n"], [
      :exclusive
    ])

    File.write!(Path.join(directory, "README.md"), markdown(report), [:exclusive])
    report
  end

  def summary(operations, artifacts) do
    baseline = artifacts["baseline_snapshot.json"]

    accepted = [
      baseline
      | Enum.flat_map(operations["steps"], fn row ->
          if row["adopted"], do: [artifacts[artifact(row["index"], "revised_snapshot")]], else: []
        end)
    ]

    final = List.last(accepted)
    history = operations["final_accepted_execution_history"]
    closed = if is_map(history), do: history["closed_requests"], else: []
    checkpoint = artifacts[operations["latest_execution_checkpoint_artifact"]]

    state_inputs =
      if is_map(checkpoint), do: checkpoint["payload"]["inputs"], else: final["payload"]["inputs"]

    completed = Enum.filter(closed, &(&1["status"] == "completed"))
    maintenance = Enum.filter(completed, &(&1["request"]["value"] == 0))
    service = Enum.filter(completed, &(&1["request"]["value"] > 0))

    contacts =
      get_in(baseline, [
        "payload",
        "report",
        "scheduling_search",
        "command_delivery",
        "contact_allocation",
        "rows"
      ]) || []

    allocated = Enum.filter(contacts, &(&1["effective_allocation_status"] == "allocated"))

    margins =
      Enum.reduce(accepted, %{}, fn snapshot, acc ->
        resources =
          get_in(snapshot, [
            "payload",
            "report",
            "attitude_planning",
            "resource_feasibility",
            "assets"
          ]) || %{}

        Enum.reduce(resources, acc, fn {asset, evidence}, acc ->
          Enum.reduce(evidence["models"] || [], acc, fn model, acc ->
            Enum.reduce(model["levels"] || [], acc, fn level, acc ->
              Enum.reduce(level["minimum_margins"] || %{}, acc, fn {id, m}, acc ->
                if is_number(m["margin"]),
                  do:
                    Map.update(acc, asset <> "/" <> model["id"] <> "/" <> id, m, fn old ->
                      if m["margin"] < old["margin"], do: m, else: old
                    end),
                  else: acc
              end)
            end)
          end)
        end)
      end)

    plans =
      Enum.map(accepted, fn snapshot ->
        r = snapshot["payload"]["report"]

        %{
          "snapshot_id" => snapshot["snapshot_id"],
          "horizon" =>
            snapshot["payload"]["inputs"]["study"]["horizon"]
            |> Map.take(~w(starts_at_s ends_at_s)),
          "scheduled_value" => Enum.sum(Enum.map(r["activities"], & &1["value"])),
          "scheduled_request_ids" => Enum.map(r["activities"], & &1["request_id"]),
          "unfulfilled" =>
            Enum.filter(r["requests"], &(&1["status"] != "scheduled"))
            |> Enum.map(&Map.take(&1, ~w(request_id reasons scheduling_summary))),
          "work" => get_in(r, ["scheduling_search", "work_accounting"]) || :null
        }
      end)

    failures =
      Enum.filter(operations["steps"], &(not &1["adopted"]))
      |> Enum.map(fn row ->
        %{
          "id" => row["id"],
          "status" => row["status"],
          "planning_failure_category" =>
            get_in(row, ["review", "planning_failure_category"]) || :null,
          "work" => get_in(row, ["review", "planning_work"]) || :null
        }
      end)

    receipts =
      Enum.flat_map(
        operations["steps"],
        fn row ->
          if is_map(row["state_update"]),
            do: row["state_update"]["command_receipts"] || [],
            else: []
        end
      )
      |> Enum.uniq_by(& &1["request_id"])

    simulated =
      Enum.flat_map(operations["steps"], & &1["executed_services"])
      |> Enum.uniq_by(& &1["request_id"])
      |> Enum.filter(&(&1["value"] > 0))

    %{
      "simulated_completed_service_count" => length(simulated),
      "simulated_completed_service_value" => Enum.sum(Enum.map(simulated, & &1["value"])),
      "asset_count" => length(baseline["payload"]["inputs"]["mission"]["assets"]),
      "cycle_count" => length(operations["steps"]),
      "run_status" => operations["run_status"],
      "plan_readiness" => operations["plan_readiness"],
      "completed_service_count" => length(service),
      "completed_service_value" => Enum.sum(Enum.map(service, & &1["request"]["value"])),
      "completed_maintenance_count" => length(maintenance),
      "completed_maintenance_duration_s" =>
        Enum.sum(Enum.map(maintenance, & &1["request"]["duration_s"])),
      "expired_request_count" => Enum.count(closed, &(&1["status"] == "expired")),
      "allocated_contact_count" => length(allocated),
      "allocated_contact_duration_s" =>
        Enum.sum(Enum.map(allocated, &(&1["ends_at_s"] - &1["starts_at_s"]))),
      "simulated_receipt_count" => length(receipts),
      "minimum_forecast_margins_across_accepted_plans" => margins,
      "plans" => plans,
      "rejected_steps" => failures,
      "planning_callback_total" =>
        Enum.sum(
          Enum.map(plans, fn p ->
            if is_map(p["work"]), do: p["work"]["total_evaluations"], else: 0
          end)
        ) +
          Enum.sum(
            Enum.map(failures, fn f ->
              if is_map(f["work"]), do: f["work"]["total_evaluations"], else: 0
            end)
          ),
      "remaining_static_budgets" =>
        Map.new(
          state_inputs["mission"]["assets"],
          &{&1["id"], &1["resource_budgets"]}
        )
    }
  end

  defp artifact(n, suffix),
    do: "step-#{n |> Integer.to_string() |> String.pad_leading(2, "0")}-#{suffix}.json"

  def markdown(r) do
    [
      "# Reference constellation assessment\n\nStatus: **#{r["status"]}**. Synthetic assumptions; no operational readiness claim.\n\n",
      "| Case | Assets | Steps | Accepted service count / value | Maintenance / seconds | Contact seconds | Callbacks | Independent |\n| --- | ---: | ---: | --- | --- | ---: | ---: | --- |\n",
      Enum.map(r["cases"], fn c ->
        "| [#{c["id"]}](#{c["id"]}/README.md) | #{c["asset_count"]} | #{c["cycle_count"]} | #{c["completed_service_count"]} / #{c["completed_service_value"]} | #{c["completed_maintenance_count"]} / #{c["completed_maintenance_duration_s"]} | #{c["allocated_contact_duration_s"]} | #{c["planning_callback_total"]} | [#{c["independent_validation"]}](#{c["id"]}/validation.md) |\n"
      end),
      "\nContacts are allocated reservations, not delivered service. Accepted counts/value come from original closed requests, so continuation tails do not create duplicate completions. Accepted execution checkpoints retain completed work when replanning fails; plan readiness and simulated totals are reported separately. Margins are minimum forecasts over accepted plans, not measured hardware margins. Callback totals include accepted search attempts and captured failed-search work, not preparation, opportunity generation or physical execution. Full per-plan rejections, resource margins and observed timings are in assessment.json.\n\n",
      Enum.map(r["limitations"], &("- " <> &1 <> "\n"))
    ]
  end
end
