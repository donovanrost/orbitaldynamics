defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.Checker do
  @moduledoc "Independent structural and ideal constant-power accounting checks over JSON artifacts. No planning helpers or physical evaluators are called."
  @tol 1.0e-8
  @placement ~w(request_id asset_id starts_at_s ends_at_s)

  def snapshot(s, label \\ "snapshot") do
    try do
      ensure(is_map(s) and is_map(s["payload"]), label, "snapshot envelope required")

      ensure(
        Enum.sort(Map.keys(s)) == ~w(content_sha256 payload snapshot_id) and
          Enum.sort(Map.keys(s["payload"])) ==
            ~w(canonicalization format inputs parent_snapshot_id report),
        label,
        "unknown snapshot envelope/payload fields"
      )

      p = s["payload"]

      ensure(
        p["format"] == "mission_analysis_plan_snapshot.v1" and
          p["canonicalization"] == "sorted_json_keys.v1",
        label,
        "unsupported snapshot format"
      )

      ensure(json?(s), label, "exact JSON values required")
      i = p["inputs"]
      ensure(is_map(i), label, "snapshot inputs required")
      m = i["mission"]
      study = i["study"]
      r = p["report"]

      ensure(
        is_map(m) and is_map(study) and is_map(r),
        label,
        "reference mission, study and report required"
      )

      assets = list(m["assets"], 20, label)
      requests = list(m["requests"], 100, label)
      acts = list(r["activities"], 100, label)
      rs = list(r["requests"], 100, label)
      h = study["horizon"]
      ensure(is_map(h), label, "explicit horizon required")
      first = number(h["starts_at_s"], label)
      last = number(h["ends_at_s"], label)
      ensure(last > first, label, "ordered horizon required")
      Enum.each(assets, &asset_schema(&1, label))
      Enum.each(requests, &request_schema(&1, label))
      Enum.each(acts, &activity_schema(&1, label))

      Enum.each(rs, fn q ->
        id(q["request_id"], label)
        number(q["value"], label)
      end)

      am = Map.new(assets, &{&1["id"], &1})
      rm = Map.new(requests, &{&1["id"], &1})
      availability = list(i["service_unavailable_asset_ids"], 20, label)

      issues =
        OrbitalDynamics.MissionAnalysis.PlanValidation.MotionHistory.check(i, r, label) ++
          OrbitalDynamics.MissionAnalysis.PlanValidation.Commands.snapshot(i, r, label) ++
          OrbitalDynamics.MissionAnalysis.PlanValidation.Coverage.snapshot(i, r, label) ++
          identity(s, label) ++
          check(
            r["format"] == "mission_analysis.v1" and
              r["time_system"] == %{"epoch_origin" => "J2000", "scale" => h["time_scale"]} and
              h["time_scale"] == "utc",
            "time_system",
            label,
            "reference checks require explicit J2000 UTC"
          ) ++
          check(
            r["baseline_configuration"] === m and r["attitude_study_configuration"] === study,
            "input_report_binding",
            label,
            "report configuration differs from declared inputs"
          ) ++
          unique(assets, "id", label) ++
          unique(requests, "id", label) ++
          unique(rs, "request_id", label) ++
          unique(acts, "request_id", label) ++
          unique(acts, "id", label) ++
          check(
            Enum.sort(Enum.map(rs, & &1["request_id"])) == Enum.sort(Map.keys(rm)),
            "request_report_identity",
            label,
            "report requests differ from active demand"
          ) ++
          check(
            length(Enum.uniq(availability)) == length(availability) and
              Enum.all?(availability, &Map.has_key?(am, &1)),
            "availability_identity",
            label,
            "invalid unavailable spacecraft set"
          ) ++
          check(
            Enum.sort(get_in(r, ["service_unavailability", "asset_ids"]) || []) ==
              Enum.sort(availability),
            "availability_report_binding",
            label,
            "availability metadata differs from inputs"
          )

      issues =
        issues ++
          Enum.flat_map(acts, fn a ->
            q = rm[a["request_id"]]
            here = label <> "/activity:" <> a["request_id"]

            check(
              q != nil and Map.has_key?(am, a["asset_id"]),
              "activity_identity",
              here,
              "activity references unknown demand or spacecraft"
            ) ++
              check(
                a["asset_id"] not in availability,
                "unavailable_asset_scheduled",
                here,
                "service scheduled on an unavailable spacecraft"
              ) ++
              check(
                a["starts_at_s"] >= first and a["ends_at_s"] <= last and
                  a["ends_at_s"] > a["starts_at_s"],
                "activity_horizon",
                here,
                "activity outside the remaining horizon"
              ) ++
              if(q,
                do:
                  check(
                    a["starts_at_s"] >= q["starts_at_s"] and a["ends_at_s"] <= q["ends_at_s"],
                    "request_window",
                    here,
                    "activity outside its allowed request window"
                  ) ++
                    check(
                      a["ends_at_s"] == a["starts_at_s"] + q["duration_s"],
                      "activity_duration",
                      here,
                      "activity duration differs from requested duration"
                    ) ++
                    check(
                      a["value"] == q["value"] and a["resource_costs"] == q["resource_costs"] and
                        a["type"] == q["activity_type"],
                      "activity_request_binding",
                      here,
                      "activity value, type or costs differ from request"
                    ),
                else: []
              )
          end)

      separation = number(m["asset_separation_s"], label)
      ensure(separation >= 0, label, "nonnegative separation required")

      issues =
        issues ++
          Enum.flat_map(Enum.group_by(acts, & &1["asset_id"]), fn {asset, xs} ->
            xs
            |> Enum.sort_by(& &1["starts_at_s"])
            |> Enum.chunk_every(2, 1, :discard)
            |> Enum.flat_map(fn [a, b] ->
              check(
                a["ends_at_s"] + separation <= b["starts_at_s"],
                "asset_overlap",
                label <> "/" <> asset,
                "overlap/separation conflict between #{a["request_id"]} and #{b["request_id"]}"
              )
            end)
          end)

      issues =
        issues ++
          Enum.flat_map(rs, fn q ->
            scheduled = Enum.any?(acts, &(&1["request_id"] == q["request_id"]))
            source = rm[q["request_id"]]

            check(
              q["status"] == if(scheduled, do: "scheduled", else: "unfulfilled"),
              "request_status",
              label <> "/" <> q["request_id"],
              "status contradicts selected activities"
            ) ++
              check(
                source != nil and q["value"] == source["value"],
                "request_value",
                label,
                "request report value differs from input"
              )
          end)

      protected = get_in(study, ["scheduling", "protected_activities"]) || []
      list(protected, 100, label)

      issues =
        issues ++
          unique(protected, "request_id", label) ++
          Enum.flat_map(protected, fn pin ->
            check(
              exact?(acts, pin),
              "protected_placement",
              label,
              "missing or changed commitment #{pin["request_id"]}"
            )
          end)

      issues =
        issues ++
          ledger(i, acts, label) ++
          static(assets, requests, acts, r["remaining_resource_budgets"], label) ++
          availability(i, acts, label) ++
          OrbitalDynamics.MissionAnalysis.PlanValidation.StateQuality.check(i, label) ++
          OrbitalDynamics.MissionAnalysis.PlanValidation.Continuations.check(i, r, label)

      {battery_issues, expected} =
        resource_check(fn -> batteries(i, r, label) end, "battery_timeline", label)

      {wheel_issues, wheels} =
        resource_check(
          fn -> OrbitalDynamics.MissionAnalysis.PlanValidation.Wheels.check(i, r, label) end,
          "wheel_timeline",
          label
        )

      {thermal_issues, thermal} =
        OrbitalDynamics.MissionAnalysis.PlanValidation.Thermal.check(i, r, label)

      result = finish(issues ++ battery_issues ++ wheel_issues ++ thermal_issues, expected, label)

      result =
        if thermal == %{},
          do: result,
          else:
            Map.put(result, "expected_thermal", thermal)
            |> Map.update!(
              "scope",
              &(&1 ++ ["analytic single-node thermal accounting with equal declared phase heat"])
            )

      if wheels == %{},
        do: result,
        else:
          result
          |> Map.put("expected_wheels", wheels)
          |> Map.update!(
            "scope",
            &(&1 ++
                [
                  "analytic stationary or sampled moving-wheel angular-momentum and motor accounting on declared kinematics"
                ])
          )
    rescue
      e in [
        KeyError,
        BadMapError,
        FunctionClauseError,
        Protocol.UndefinedError,
        ArithmeticError,
        ArgumentError
      ] ->
        finish([issue("invalid_schema", label, Exception.message(e))], %{}, label)
    catch
      {:schema, path, message} -> finish([issue("invalid_schema", path, message)], %{}, label)
    end
  end

  defp identity(s, path) do
    hash = digest(s["payload"])

    check(
      s["content_sha256"] == hash and s["snapshot_id"] == "mission_plan_snapshot:" <> hash,
      "snapshot_content_identity",
      path,
      "snapshot digest does not match its payload"
    ) ++
      check(
        s["payload"]["parent_snapshot_id"] == :null or
          (is_binary(s["payload"]["parent_snapshot_id"]) and
             Regex.match?(
               ~r/\Amission_plan_snapshot:[0-9a-f]{64}\z/,
               s["payload"]["parent_snapshot_id"]
             )),
        "snapshot_parent_identity",
        path,
        "parent identity must be a string or null"
      )
  end

  defp ledger(i, acts, path) do
    case i["execution"] do
      nil ->
        []

      e when is_map(e) ->
        closed = list(e["closed_requests"], 100, path)
        h = i["study"]["horizon"]

        issues =
          check(
            e["format"] == "mission_execution_state.v1" and e["time_scale"] == "utc" and
              e["as_of_s"] == h["starts_at_s"],
            "execution_boundary",
            path,
            "ledger boundary differs from plan"
          ) ++
            check(
              is_map(e["last_update"]) and e["state_update_sha256"] == digest(e["last_update"]),
              "execution_update_identity",
              path,
              "raw state update digest differs from ledger"
            )

        closed_ids =
          Enum.map(closed, fn c ->
            request_schema(c["request"], path)
            c["request"]["id"]
          end)

        issues =
          issues ++
            check(
              length(Enum.uniq(closed_ids)) == length(closed_ids),
              "duplicate_closed_request",
              path,
              "duplicate closed identity"
            ) ++
            check(
              Enum.all?(i["mission"]["requests"], &(&1["id"] not in closed_ids)) and
                Enum.all?(acts, &(&1["request_id"] not in closed_ids)),
              "closed_request_reintroduced",
              path,
              "completed or expired demand is active/scheduled again"
            )

        issues ++
          ledger_state(i, e, path) ++
          Enum.flat_map(closed, fn c ->
            q = c["request"]
            t = number(c["reported_at_s"], path)

            base =
              check(
                t <= e["as_of_s"] and c["status"] in ~w(completed expired),
                "closed_request_status",
                path,
                "invalid closure time or status"
              )

            case c["status"] do
              "completed" ->
                a = c["baseline_activity"]
                ensure(is_map(a), path, "completed baseline placement required")
                Enum.each(~w(starts_at_s ends_at_s), &number(a[&1], path))

                base ++
                  check(
                    a["request_id"] == q["id"] and a["ends_at_s"] <= t and
                      a["ends_at_s"] == a["starts_at_s"] + q["duration_s"] and
                      a["starts_at_s"] >= q["starts_at_s"] and a["ends_at_s"] <= q["ends_at_s"],
                    "completion_placement",
                    path,
                    "closure contradicts declared request/placement"
                  )

              "expired" ->
                base ++
                  check(
                    q["ends_at_s"] - q["duration_s"] < t,
                    "premature_expiration",
                    path,
                    "expired request still had time remaining"
                  )

              _ ->
                base
            end
          end)

      _ ->
        [issue("invalid_execution_ledger", path, "execution ledger must be an object")]
    end
  end

  defp ledger_state(i, e, path) do
    u = e["last_update"]
    ensure(is_map(u) and is_map(u["assets"]), path, "raw state asset map required")

    completed =
      Enum.filter(e["closed_requests"], &(&1["status"] == "completed"))
      |> Enum.map(& &1["request"]["id"])

    check(
      u["as_of_s"] == e["as_of_s"] and u["source_id"] == e["source_id"] and
        u["time_scale"] == "utc" and u["frame"] == "eci_j2000",
      "ledger_update_boundary",
      path,
      "raw update boundary/frame/source differs from ledger"
    ) ++
      check(
        is_list(u["completed_request_ids"]) and
          Enum.all?(u["completed_request_ids"], &(&1 in completed)),
        "ledger_missing_completion",
        path,
        "raw update completion is missing from closed history"
      ) ++
      Enum.flat_map(i["mission"]["assets"], fn asset ->
        a = u["assets"][asset["id"]]
        ensure(is_map(a), path, "raw state spacecraft required")
        initial = get_in(i, ["study", "attitude", "assets", asset["id"], "initial"])

        expected = %{
          "epoch_s" => e["as_of_s"],
          "time_scale" => "utc",
          "frame" => "eci_j2000",
          "quaternion_wxyz" => a["quaternion_wxyz"],
          "angular_velocity_inertial_deg_s" => a["angular_velocity_inertial_deg_s"]
        }

        check(
          initial == expected and asset["resource_budgets"] == a["resource_budgets"],
          "ledger_state_binding",
          path <> "/" <> asset["id"],
          "raw state attitude or budgets differ from planning initial conditions"
        ) ++
          Enum.flat_map(get_in(i, ["study", "resources", "assets", asset["id"]]) || [], fn m ->
            case m["model"] do
              "battery" ->
                check(
                  m["configuration"]["initial_wh"] == a["battery_energy_wh"][m["id"]],
                  "ledger_energy_binding",
                  path,
                  "raw battery update differs from configured initial energy"
                )

              "thermal" ->
                check(
                  m["configuration"]["initial_temperature_k"] ==
                    a["thermal_temperature_k"][m["id"]],
                  "ledger_thermal_binding",
                  path,
                  "raw temperature differs from configured initial state"
                )

              "reaction_wheels" ->
                check(
                  m["configuration"]["initial_momentum_nms"] == a["wheel_momentum_nms"][m["id"]],
                  "ledger_wheel_binding",
                  path,
                  "raw wheel state differs from configured initial momentum"
                )

              _ ->
                [
                  issue(
                    "resource_state_unsupported",
                    path,
                    "unknown resource state binding",
                    "unsupported"
                  )
                ]
            end
          end)
      end)
  end

  defp static(assets, requests, acts, balances, path) do
    ensure(is_map(balances), path, "remaining resource balances required")
    rm = Map.new(requests, &{&1["id"], &1})

    check(
      Enum.sort(Map.keys(balances)) == Enum.sort(Enum.map(assets, & &1["id"])),
      "static_asset_identity",
      path,
      "balance spacecraft set differs from inputs"
    ) ++
      Enum.flat_map(assets, fn asset ->
        expected =
          Enum.reduce(
            Enum.filter(
              acts,
              &(&1["asset_id"] == asset["id"] and Map.has_key?(rm, &1["request_id"]))
            ),
            asset["resource_budgets"],
            fn a, budgets ->
              Enum.reduce(rm[a["request_id"]]["resource_costs"], budgets, fn {k, v}, b ->
                Map.update(b, k, -v, &(&1 - v))
              end)
            end
          )

        actual = balances[asset["id"]]

        check(
          Enum.all?(expected, fn {_, v} -> v >= -@tol end),
          "static_budget_overspend",
          path <> "/" <> asset["id"],
          "selected services exceed declared static budgets"
        ) ++
          check(
            is_map(actual) and equal_balances?(expected, actual),
            "static_balance",
            path <> "/" <> asset["id"],
            "reported remaining balance differs from independent accounting"
          )
      end)
  end

  defp availability(i, acts, label) do
    config = get_in(i, ["study", "scheduling", "availability"])

    if config == nil do
      []
    else
      ensure(
        is_map(config) and Enum.sort(Map.keys(config)) == ~w(outages time_scale) and
          config["time_scale"] == get_in(i, ["study", "horizon", "time_scale"]) and
          is_list(config["outages"]) and length(config["outages"]) <= 128,
        label,
        "invalid availability calendar"
      )

      assets = Enum.map(i["mission"]["assets"], & &1["id"])
      requests = Map.new(i["mission"]["requests"], &{&1["id"], &1})

      unique(config["outages"], "id", label) ++
        Enum.flat_map(config["outages"], fn outage ->
          ensure(
            is_map(outage) and
              Enum.sort(Map.keys(outage)) == ~w(asset_id ends_at_s id scope starts_at_s),
            label,
            "invalid outage fields"
          )

          id(outage["id"], label)
          ensure(outage["asset_id"] in assets, label, "unknown outage asset")
          a = number(outage["starts_at_s"], label)
          b = number(outage["ends_at_s"], label)
          ensure(b > a, label, "nonpositive outage duration")
          scope = outage["scope"]
          ensure(is_map(scope), label, "outage scope required")

          ensure(
            scope["kind"] in ~w(all_activities activity_types modes),
            label,
            "unsupported outage scope"
          )

          if scope["kind"] == "all_activities" do
            ensure(Map.keys(scope) == ["kind"], label, "invalid all-activity outage")
          else
            ensure(
              Enum.sort(Map.keys(scope)) == ~w(ids kind) and is_list(scope["ids"]) and
                length(scope["ids"]) in 1..32 and
                length(Enum.uniq(scope["ids"])) == length(scope["ids"]),
              label,
              "invalid outage scope IDs"
            )

            Enum.each(scope["ids"], &id(&1, label))

            if scope["kind"] == "modes" do
              modes =
                get_in(i, ["study", "path_constraints", "assets", outage["asset_id"], "modes"]) ||
                  %{}

              ensure(
                Enum.all?(scope["ids"], &Map.has_key?(modes, &1)),
                label,
                "unknown outage mode"
              )
            end
          end

          Enum.flat_map(acts, fn act ->
            mode =
              get_in(i, [
                "study",
                "path_constraints",
                "assets",
                act["asset_id"],
                "activity_modes",
                act["request_id"]
              ])

            matches =
              act["asset_id"] == outage["asset_id"] and
                case scope["kind"] do
                  "all_activities" -> true
                  "activity_types" -> requests[act["request_id"]]["activity_type"] in scope["ids"]
                  "modes" -> mode in scope["ids"]
                end

            check(
              not (matches and act["starts_at_s"] < b and act["ends_at_s"] > a),
              "availability_conflict",
              label <> "/" <> act["request_id"],
              "activity intersects declared outage " <> outage["id"]
            )
          end)
        end)
    end
  end

  defp batteries(i, r, path) do
    configs = get_in(i, ["study", "resources", "assets"]) || %{}
    resource = get_in(r, ["attitude_planning", "resource_feasibility"])

    Enum.reduce(configs, {[], %{}}, fn {asset, models}, {issues, expected} ->
      Enum.reduce(
        Enum.reject(models, &(&1["model"] in ["reaction_wheels", "thermal"])),
        {issues, expected},
        fn model, {issues, expected} ->
          c = model["configuration"]
          name = path <> "/" <> asset <> "/" <> model["id"]

          config_issues =
            if is_map(c) do
              check(
                not Enum.any?(
                  ~w(initial_wh capacity_wh reserve_wh),
                  &(is_number(c[&1]) and c[&1] < 0)
                ) and
                  not (is_number(c["initial_wh"]) and is_number(c["capacity_wh"]) and
                         c["initial_wh"] > c["capacity_wh"]) and
                  not (is_number(c["reserve_wh"]) and is_number(c["capacity_wh"]) and
                         c["reserve_wh"] > c["capacity_wh"]),
                "battery_configuration",
                name,
                "known energy or reserve is outside capacity bounds"
              )
            else
              []
            end

          issues = issues ++ config_issues

          case power_model(i, asset, model, r) do
            {:unsupported, why} ->
              {issues ++
                 [
                   issue(
                     if(model["model"] == "battery",
                       do: "battery_model_unsupported",
                       else: "resource_model_unsupported"
                     ),
                     name,
                     why,
                     "unsupported"
                   )
                 ], expected}

            {:ok, segments} ->
              predicted =
                OrbitalDynamics.MissionAnalysis.PlanValidation.Battery.integrate(c, segments)

              evidence =
                if is_map(resource),
                  do: get_in(resource, ["assets", asset, "models"]) || [],
                  else: []

              found = Enum.filter(evidence, &(&1["id"] == model["id"]))

              es =
                check(
                  predicted["minimum_energy_wh"] + @tol >= c["reserve_wh"],
                  "battery_reserve",
                  name,
                  "independent energy balance crosses reserve"
                ) ++
                  check(
                    predicted["unserved_wh"] <= @tol,
                    "battery_supply",
                    name,
                    "independent energy balance has unmet demand"
                  ) ++
                  check(
                    length(found) == 1,
                    "battery_evidence_identity",
                    name,
                    "one resource evidence model is required"
                  )

              es =
                if length(found) == 1 do
                  levels = list(hd(found)["levels"], 10, name)

                  es ++
                    check(
                      Enum.sort(Enum.map(levels, & &1["sample_step_s"])) ==
                        Enum.sort(i["study"]["resources"]["sample_steps_s"]),
                      "battery_coverage",
                      name,
                      "every configured battery cadence is required"
                    ) ++
                    check(
                      levels != [],
                      "battery_evidence_missing",
                      name,
                      "resource levels are missing"
                    ) ++
                    Enum.flat_map(levels, fn level ->
                      state = level["final_state"] || %{}

                      OrbitalDynamics.MissionAnalysis.PlanValidation.Battery.samples(
                        level,
                        c,
                        segments,
                        name
                      ) ++
                        check(
                          near?(get_in(level, ["initial_state", "energy_wh"]), c["initial_wh"]) and
                            near?(get_in(level, ["initial_state", "unserved_wh"]), 0) and
                            near?(get_in(level, ["initial_state", "curtailed_wh"]), 0),
                          "battery_initial_state",
                          name,
                          "resource runner initial state differs from input"
                        ) ++
                        check(
                          Enum.all?(
                            ~w(energy_wh unserved_wh curtailed_wh),
                            &near?(state[&1], predicted[&1])
                          ),
                          "battery_final_state",
                          name,
                          "reported final state differs from analytic piecewise energy balance"
                        ) ++
                        check(
                          near?(
                            get_in(level, ["state_extrema", "energy_wh", "min"]),
                            predicted["minimum_energy_wh"]
                          ),
                          "battery_minimum_energy",
                          name,
                          "reported minimum stored energy differs from analytic balance"
                        )
                    end)
                else
                  es
                end

              {issues ++ es, put_in_nested(expected, asset, model["id"], predicted)}
          end
        end
      )
    end)
  end

  defp power_model(i, asset, model, report) do
    c = model["configuration"]
    path = get_in(i, ["study", "path_constraints", "assets", asset])

    cond do
      model["model"] != "battery" or not is_map(c) ->
        {:unsupported, "only the declared ideal battery is checked"}

      not is_map(c["generation"]) or c["generation"]["kind"] != "constant" or
          not nonnegative?(c["generation"]["power_w"]) ->
        {:unsupported, "constant known bus generation required; source geometry is outside scope"}

      not Enum.all?(~w(initial_wh capacity_wh reserve_wh), &nonnegative?(c[&1])) or
        c["capacity_wh"] <= 0 or c["initial_wh"] > c["capacity_wh"] ->
        {:unsupported, "finite known initial energy, capacity and reserve required"}

      not Enum.all?(
        ~w(charge_efficiency discharge_efficiency),
        &(is_number(c[&1]) and c[&1] > 0 and c[&1] <= 1)
      ) ->
        {:unsupported, "known efficiencies in (0,1] required"}

      not is_map(c["phase_load_w"]) or
        Enum.sort(Map.keys(c["phase_load_w"])) !=
          Enum.sort(
            ~w(activity brake hold slew_accelerate slew_cruise slew_decelerate settle ramp_to_tracking)
          ) or not Enum.all?(c["phase_load_w"], fn {_, v} -> nonnegative?(v) end) ->
        {:unsupported, "complete nonnegative phase loads required"}

      not is_map(path) ->
        {:unsupported, "declared activity and idle modes required"}

      true ->
        segments =
          OrbitalDynamics.MissionAnalysis.PlanValidation.ResourceTimeline.segments(
            i,
            report,
            asset
          )

        segments =
          Enum.map(segments, fn segment ->
            mode = path["modes"][segment.mode]
            load = mode["power_load_w"]
            ensure(nonnegative?(load), "battery", "nonnegative mode power required")

            Map.merge(segment, %{
              load: load + c["phase_load_w"][segment.phase],
              evidence_mode: %{"name" => segment.mode, "parameters" => mode}
            })
          end)

        {:ok, segments}
    end
  end

  defp resource_check(fun, code, label) do
    try do
      fun.()
    rescue
      e in [
        ArgumentError,
        KeyError,
        BadMapError,
        FunctionClauseError,
        Protocol.UndefinedError,
        ArithmeticError
      ] ->
        {[issue(code, label, Exception.message(e))], %{}}
    catch
      {:schema, path, message} -> {[issue(code, path, message)], %{}}
    end
  end

  defp finish(issues, expected, label),
    do: %{
      "format" => "independent_plan_validation.v1",
      "source" => label,
      "status" =>
        cond do
          Enum.any?(issues, &(&1["severity"] == "error")) -> "failed"
          issues != [] -> "partial"
          true -> "passed"
        end,
      "issues" => issues,
      "expected_battery" => expected,
      "scope" => [
        "JSON content identity, reference input bindings, activity windows/durations/overlaps, commitments, lifecycle exclusion and static balances",
        "analytic ideal battery accounting across saved modes and maneuver phase loads where explicitly supported",
        "no orbital, pointing, path feasibility, opportunity discovery or optimality validation"
      ]
    }

  def check(true, _, _, _), do: []
  def check(false, code, path, message), do: [issue(code, path, message)]

  def issue(code, path, message, severity \\ "error"),
    do: %{"code" => code, "location" => path, "message" => message, "severity" => severity}

  def near?(a, b), do: is_number(a) and is_number(b) and abs(a - b) <= @tol

  def exact?(acts, p),
    do:
      Enum.count(acts, &(&1["request_id"] == p["request_id"])) == 1 and
        Enum.any?(acts, fn a -> Enum.all?(@placement, &(a[&1] == p[&1])) end)

  def placement(a), do: Map.take(a, @placement)

  def digest(v),
    do: v |> canonical() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)

  defp canonical(m) when is_map(m),
    do: [
      ?{,
      m
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {k, v} -> [:json.encode(k), ?:, canonical(v)] end)
      |> Enum.intersperse(?,),
      ?}
    ]

  defp canonical(xs) when is_list(xs),
    do: [?[, Enum.map(xs, &canonical/1) |> Enum.intersperse(?,), ?]]

  defp canonical(v), do: :json.encode(v)
  defp json?(v) when is_map(v), do: Enum.all?(v, fn {k, x} -> is_binary(k) and json?(x) end)
  defp json?(v) when is_list(v), do: Enum.all?(v, &json?/1)
  defp json?(v), do: is_binary(v) or is_number(v) or v in [true, false, :null]
  defp put_in_nested(m, a, b, v), do: Map.update(m, a, %{b => v}, &Map.put(&1, b, v))

  defp equal_balances?(a, b),
    do:
      Enum.all?(a, fn {k, v} -> near?(b[k], v) end) and
        Enum.all?(b, fn {k, v} -> Map.has_key?(a, k) or near?(v, 0) end)

  defp unique(xs, key, path),
    do:
      check(
        length(Enum.uniq_by(xs, & &1[key])) == length(xs),
        "duplicate_#{key}",
        path,
        "duplicate #{key} identity"
      )

  defp ensure(true, _, _), do: :ok
  defp ensure(false, path, message), do: throw({:schema, path, message})

  defp list(x, max, path) do
    ensure(is_list(x) and length(x) <= max, path, "bounded list required")
    x
  end

  defp id(x, path),
    do: ensure(is_binary(x) and byte_size(x) in 1..256, path, "identity string required")

  defp number(x, path) do
    ensure(is_number(x) and x >= -1.0e15 and x <= 1.0e15, path, "finite bounded number required")
    x
  end

  defp nonnegative?(x), do: is_number(x) and x >= 0 and x <= 1.0e15

  defp costs(x, path) do
    ensure(
      is_map(x) and Enum.all?(x, fn {k, v} -> is_binary(k) and nonnegative?(v) end),
      path,
      "nonnegative resource map required"
    )
  end

  defp asset_schema(a, path) do
    ensure(is_map(a), path, "asset object required")
    id(a["id"], path)
    costs(a["resource_budgets"], path)
  end

  defp request_schema(q, path) do
    ensure(is_map(q), path, "request object required")
    id(q["id"], path)
    Enum.each(~w(starts_at_s ends_at_s duration_s value), &number(q[&1], path))

    ensure(
      q["duration_s"] > 0 and q["value"] >= 0 and
        q["ends_at_s"] >= q["starts_at_s"] + q["duration_s"],
      path,
      "invalid request interval/value"
    )

    costs(q["resource_costs"], path)
  end

  defp activity_schema(a, path) do
    ensure(is_map(a), path, "activity object required")
    id(a["id"], path)
    id(a["request_id"], path)
    id(a["asset_id"], path)
    Enum.each(~w(starts_at_s ends_at_s value), &number(a[&1], path))
    costs(a["resource_costs"], path)
  end
end
