defmodule OrbitalDynamics.MissionAnalysis.MaintenanceWorkBenchmark do
  @moduledoc "One/two-spacecraft synthetic joint-maintenance work study. Counts are deterministic; timings are observations."
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference

  def inputs(n) when n in 1..2 do
    m = ReferenceMission.load!("studies/automatic_wheel_maintenance.json")
    s = ReferenceMission.load!("studies/automatic_wheel_maintenance_planning.json")
    [asset] = m["assets"]

    requests =
      for index <- 1..n, q <- m["requests"] do
        q = Map.put(q, "id", q["id"] <> "-#{index}")

        if q["activity_type"] == "momentum_unload",
          do: Map.put(q, "ends_at_s", q["starts_at_s"] + q["duration_s"]),
          else: q
      end

    assets = for index <- 1..n, do: Map.put(asset, "id", "wheel-#{index}")

    study =
      Enum.reduce(
        [
          ["attitude", "assets"],
          ["resources", "assets"],
          ["path_constraints", "assets"],
          ["horizon", "terminals"]
        ],
        s,
        fn path, acc ->
          template = get_in(s, path)["demo-3"]
          put_in(acc, path, Map.new(assets, &{&1["id"], template}))
        end
      )

    study =
      update_in(study, ["path_constraints", "assets"], fn configs ->
        Map.new(configs, fn {id, c} ->
          {id,
           Map.put(
             c,
             "activity_modes",
             Map.new(requests, fn q ->
               {q["id"],
                if(q["activity_type"] == "momentum_unload", do: "desaturate", else: "work")}
             end)
           )}
        end)
      end)

    study =
      put_in(study, ["scheduling", "maintenance"], %{
        "request_ids" => for(q <- requests, q["activity_type"] == "momentum_unload", do: q["id"]),
        "candidate_step_s" => 5,
        "max_candidates" => 64,
        "max_trials" => 64,
        "max_insertions" => n
      })

    {m
     |> Map.put("mission_id", "wheel_work_#{n}")
     |> Map.put("assets", assets)
     |> Map.put("requests", requests), study}
  end

  def run!(emit \\ fn _, _ -> :ok end) do
    rows =
      for n <- 1..2, cap <- [nil, 1000] do
        {m, s} = inputs(n)

        s =
          if cap,
            do: put_in(s, ["scheduling", "work_budget"], %{"max_evaluations" => cap}),
            else: s

        filename = "fleet_#{n}#{if cap, do: "_limited", else: ""}.json"
        start = System.monotonic_time(:microsecond)

        {status, work, value, outer} =
          case Reference.run_profiled(m, s) do
            {:ok, r, _timings} ->
              emit.(filename, r)

              {r["attitude_planning"]["planning_status"],
               r["scheduling_search"]["work_accounting"],
               Enum.sum(Enum.map(r["activities"], & &1["value"])),
               r["scheduling_search"]["maintenance_search"]["trial_count"]}

            {:error, {:planning_work_budget_exhausted, work}} ->
              emit.(filename, %{"status" => "no_verified_plan", "work_accounting" => work})
              {"no_verified_plan", work, 0, 0}

            error ->
              raise "unexpected benchmark failure: #{inspect(error)}"
          end

        good =
          if cap,
            do:
              work["budget_exhausted"] and work["total_evaluations"] == cap and
                status == "no_verified_plan",
            else: status == "supported" and value == 10 * n

        %{
          "asset_count" => n,
          "cap" => cap || :null,
          "planning_status" => status,
          "service_value" => value,
          "maintenance_trials" => outer,
          "work_accounting" => work,
          "elapsed_ms_observation" => (System.monotonic_time(:microsecond) - start) / 1000,
          "passed" => good,
          "artifact" => filename
        }
      end

    %{
      "format" => "maintenance_work_benchmark.v1",
      "status" => if(Enum.all?(rows, & &1["passed"]), do: "passed", else: "failed"),
      "rows" => rows,
      "limits" =>
        "synthetic one/two-spacecraft fixed-attitude missions; no general scaling law, flight validation or wall-clock guarantee"
    }
  end
end
