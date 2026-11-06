defmodule OrbitalDynamics.MissionAnalysis.Scheduling.Explanation do
  @moduledoc "Evidence summaries of evaluated placements; never an infeasibility or optimality proof."
  @placement ~w(request_id asset_id starts_at_s ends_at_s protected)
  @budgets ~w(planning_work_budget_exhausted attitude_evaluation_budget_exhausted path_evaluation_budget_exhausted resource_evaluation_budget_exhausted path_sample_budget_exhausted profile_sample_limit resource_interval_limit_exceeded)

  def reason_code(reason) when is_atom(reason), do: Atom.to_string(reason)

  def reason_code(reason) when is_tuple(reason) and tuple_size(reason) > 0,
    do: reason |> elem(0) |> reason_code()

  def reason_code(reason) when is_binary(reason), do: reason
  def reason_code(_), do: "unclassified_provider_reason"

  def placement(activity), do: activity |> Map.take(@placement) |> Map.put_new("protected", false)

  # Compact trial summaries are retained even when a trial is rejected. Full
  # per-start evidence belongs to the returned incumbent's selection_decisions.
  def trial({:ok, activities, decisions, _, _}, request_ids) do
    served = MapSet.new(activities, & &1["request_id"])

    for id <- Enum.sort(request_ids) do
      ds = Enum.filter(decisions, &(&1["request_id"] == id))
      attempts = Enum.flat_map(ds, &(get_in(&1, ["attitude_assessment", "attempts"]) || []))

      %{
        "request_id" => id,
        "selected" => MapSet.member?(served, id),
        "decision_count" => length(ds),
        "decision_reasons" => Enum.frequencies_by(ds, & &1["reason"]),
        "tested_start_count" => length(attempts),
        "attempt_reasons" => Enum.frequencies_by(attempts, &code/1),
        "start_search_truncated" =>
          Enum.any?(ds, &(get_in(&1, ["attitude_assessment", "search_truncated"]) == true)),
        "unknown_assessment_count" =>
          Enum.count(ds, &(get_in(&1, ["attitude_assessment", "status"]) == "unknown")),
        "constraint_issues" => attempts |> Enum.flat_map(&issues/1) |> Enum.uniq() |> Enum.sort()
      }
    end
  end

  def from_report!(report, id) do
    request =
      Enum.find(report["requests"], &(&1["request_id"] == id)) ||
        raise ArgumentError, "unknown request #{id}"

    decisions = Enum.filter(report["selection_decisions"] || [], &(&1["request_id"] == id))
    opportunities = Enum.filter(report["opportunities"] || [], &(&1["request_id"] == id))
    analyses = Enum.filter(report["analyses"] || [], &(&1["request_id"] == id))
    search = report["scheduling_search"]

    %{
      "format" => "mission_request_explanation.v1",
      "request_id" => id,
      "status" => request["status"],
      "reasons" => request["reasons"],
      "opportunity_count" => length(opportunities),
      "generation" => Enum.map(analyses, &generation/1),
      "placements" => Enum.map(decisions, &decision/1),
      "summary" => summary(decisions, search, id),
      "search" => search_evidence(search, id),
      "limits" => [
        "rejections describe evaluated starts in their trial timeline, not continuous infeasibility",
        "neighboring activities are context; removing one is not proven sufficient to make a placement feasible",
        "first failing checks are reported; later checks may not have been evaluated",
        "a trial limit or exhausted neighborhood is not a global optimality proof"
      ]
    }
  end

  defp generation(a) do
    e = a["opportunity_evidence"] || %{}

    Map.take(a, ~w(asset_id status failed_check_counts))
    |> Map.merge(%{
      "opportunity_search_status" => e["status"] || "not_enabled",
      "constraint_searches" =>
        Enum.map(
          e["constraints"] || [],
          &Map.take(&1, ~w(constraint_id search_status uncovered_intervals))
        ),
      "excluded_unknown_intervals" => e["excluded_unknown_intervals"] || [],
      "rejected_window_reasons" =>
        (e["windows"] || [])
        |> Enum.filter(&(&1["status"] == "rejected"))
        |> Enum.frequencies_by(& &1["reason"])
    })
  end

  def summary(decisions, search, id) do
    ds = Enum.filter(decisions, &(&1["request_id"] == id)) |> Enum.map(&decision/1)
    attempts = Enum.flat_map(ds, & &1["attempts"])
    trials = if is_map(search), do: search["trials"], else: []

    %{
      "tested_start_count" => length(attempts),
      "attempt_reasons" => Enum.frequencies_by(attempts, & &1["reason_code"]),
      "constraint_issues" =>
        attempts |> Enum.flat_map(& &1["constraint_issues"]) |> Enum.uniq() |> Enum.sort(),
      "start_search_truncated" => Enum.any?(ds, & &1["start_search_truncated"]),
      "unknown_placement_count" => Enum.count(ds, &(&1["assessment_status"] == "unknown")),
      "evaluation_limits" =>
        attempts |> Enum.flat_map(& &1["evaluation_limits"]) |> Enum.uniq() |> Enum.sort(),
      "search_status" => if(is_map(search), do: search["status"], else: "single_greedy_pass"),
      "selected_in_trial_ids" =>
        for(
          t <- trials,
          o <- t["request_outcomes"] || [],
          o["request_id"] == id and o["selected"],
          do: t["trial"]
        ),
      "scope" =>
        "returned_incumbent_tested_starts_and_captured_trials_only_no_infeasibility_proof"
    }
  end

  defp search_evidence(search, id) when is_map(search) do
    trials =
      for t <- search["trials"] do
        outcome = Enum.find(t["request_outcomes"] || [], &(&1["request_id"] == id))

        Map.take(t, ~w(trial accepted reason endpoint_eligibility proposal))
        |> Map.put("request_outcome", outcome || :null)
      end

    result =
      search
      |> Map.take(~w(strategy status trial_count max_trials))
      |> Map.put("trials", trials)
      |> Map.put(
        "request_trial_evidence",
        if(Enum.all?(trials, &(&1["request_outcome"] != :null)),
          do: "captured",
          else: "not_captured_in_saved_report"
        )
      )

    case search["maintenance_search"] do
      nil ->
        result

      maintenance ->
        trials =
          Enum.map(maintenance["trials"], fn trial ->
            outcome = Enum.find(trial["request_outcomes"], &(&1["request_id"] == id))

            trial
            |> Map.delete("request_outcomes")
            |> Map.put("request_outcome", outcome || :null)
          end)

        Map.put(result, "maintenance_search", Map.put(maintenance, "trials", trials))
    end
  end

  defp search_evidence(_search, _id),
    do: %{
      "status" => "single_greedy_pass",
      "request_trial_evidence" => "not_enabled",
      "trials" => []
    }

  defp decision(d) do
    a = d["attitude_assessment"] || %{}
    attempts = Enum.map(a["attempts"] || [], &attempt/1)
    unknown = a["status"] == "unknown" or Enum.any?(attempts, &(&1["status"] == "unknown"))

    %{
      "opportunity_id" => d["opportunity_id"],
      "asset_id" => d["asset_id"],
      "decision" => d["reason"],
      "resource_ids" => d["resource_ids"],
      "assessment_status" => a["status"] || "not_evaluated",
      "assessment_reason" => a["reason"] || :null,
      "start_search_truncated" => a["search_truncated"] || false,
      "tested_start_count" => length(attempts),
      "coverage" =>
        cond do
          d["reason"] in ["selected", "protected_selected", "automatic_maintenance_selected"] ->
            "selected"

          a["search_truncated"] == true ->
            "start_limit_reached"

          unknown ->
            "unknown_feasibility"

          attempts != [] ->
            "configured_grid_exhausted"

          true ->
            "placement_not_tested"
        end,
      "attempt_reasons" => Enum.frequencies_by(attempts, & &1["reason_code"]),
      "constraint_issues" =>
        attempts |> Enum.flat_map(& &1["constraint_issues"]) |> Enum.uniq() |> Enum.sort(),
      "attempts" => attempts
    }
  end

  defp attempt(a) do
    Map.take(a, ~w(start_s status conflicting_activities timeline_neighbors))
    |> Map.merge(%{
      "reason_code" => code(a),
      "constraint_issues" => issues(a),
      "evaluation_limits" =>
        ([code(a)] ++ explicit_reasons(Map.take(a, ~w(path_checks resource_checks))))
        |> Enum.filter(&(&1 in @budgets))
        |> Enum.uniq()
        |> Enum.sort(),
      "incoming" => transition(a["incoming"]),
      "outgoing" => transition(a["outgoing"])
    })
  end

  defp transition(t) when is_map(t),
    do:
      Map.take(
        t,
        ~w(status reason available_s required_s time_margin_s source_epoch_s destination_epoch_s rigid_body_torque)
      )

  defp transition(_), do: :null
  defp code(a), do: a["reason_code"] || legacy_code(a["reason"]) || a["status"]
  defp legacy_code(":" <> reason), do: reason
  defp legacy_code(reason), do: reason

  defp issues(a) do
    paths =
      for {scope, path} <- a["path_checks"] || %{},
          level <- path["levels"] || [],
          issue = level["first_issue"],
          is_map(issue),
          rule <- issue["rules"] || [],
          check <- rule["checks"] || [],
          check_status(check) in ["violated", "unknown"] do
        check_summary(check)
        |> Map.merge(%{
          "kind" => "path",
          "scope" => scope,
          "rule_id" => rule["rule_id"],
          "epoch_s" => issue["epoch_s"]
        })
      end

    resources =
      for model <- get_in(a, ["resource_checks", "models"]) || [],
          level <- model["levels"] || [],
          issue = level["first_issue"],
          is_map(issue),
          check <- issue["checks"] || [],
          check_status(check) in ["violated", "unknown"] do
        check_summary(check)
        |> Map.merge(%{
          "kind" => "resource",
          "model_id" => model["id"],
          "epoch_s" => issue["evaluated_at_s"]
        })
      end

    # Budget/coverage causes can live below a path/resource level rather than in
    # the top-level rejection. Preserve those explicit reasons, never infer a
    # budget failure from a physical tracking/rate limit.
    causes =
      explicit_reasons(Map.take(a, ~w(path_checks resource_checks)))
      |> Enum.filter(&(&1 in @budgets))
      |> Enum.map(&%{"kind" => "evaluation_limit", "reason" => &1})

    torque =
      for {scope, assessment} <- [
            {"incoming", get_in(a, ["incoming", "rigid_body_torque"])},
            {"outgoing", get_in(a, ["outgoing", "rigid_body_torque"])},
            {"tracking", a["tracking_torque"]}
          ],
          is_map(assessment),
          assessment["status"] == "violated",
          axis <- 0..2,
          margins =
            assessment["minimum_margin_body_torque_nm"] || assessment["margin_body_torque_nm"],
          Enum.at(margins, axis) < 0 do
        %{
          "kind" => "rigid_body_torque",
          "scope" => scope,
          "id" => Enum.at(~w(body_x body_y body_z), axis),
          "status" => "violated",
          "margin" => Enum.at(margins, axis),
          "margin_unit" => "Nm",
          "epoch_s" => assessment["epoch_s"] || get_in(assessment, ["first_violation", "epoch_s"])
        }
      end

    Enum.uniq(paths ++ resources ++ causes ++ torque)
  end

  defp check_status(%OrbitalDynamics.MissionAnalysis.Path.CheckResult{status: status}),
    do: Atom.to_string(status)

  defp check_status(check), do: check["status"]

  defp check_summary(%OrbitalDynamics.MissionAnalysis.Path.CheckResult{} = check),
    do:
      check
      |> OrbitalDynamics.MissionAnalysis.Path.CheckResult.report()
      |> Map.take(~w(id status margin margin_unit reason))

  defp check_summary(check), do: Map.take(check, ~w(id status margin margin_unit reason))

  defp explicit_reasons(%OrbitalDynamics.MissionAnalysis.Path.CheckResult{} = check),
    do: check |> OrbitalDynamics.MissionAnalysis.Path.CheckResult.report() |> explicit_reasons()

  defp explicit_reasons(%_{} = value), do: value |> Map.from_struct() |> explicit_reasons()

  defp explicit_reasons(m) when is_map(m),
    do:
      List.wrap(Map.get(m, "reason", Map.get(m, :reason))) ++
        Enum.flat_map(Map.values(Map.drop(m, ["reason", :reason])), &explicit_reasons/1)

  defp explicit_reasons(l) when is_list(l), do: Enum.flat_map(l, &explicit_reasons/1)
  defp explicit_reasons(_), do: []

  def failure_category(reason) when is_tuple(reason),
    do: reason |> Tuple.to_list() |> Enum.map(&failure_category/1) |> failure_categories()

  def failure_category(reason) when is_atom(reason),
    do:
      if(Atom.to_string(reason) in @budgets,
        do: "evaluation_budget_exhausted",
        else: "planner_error"
      )

  def failure_category(_), do: "planner_error"

  defp failure_categories(categories),
    do:
      if("evaluation_budget_exhausted" in categories,
        do: "evaluation_budget_exhausted",
        else: "planner_error"
      )

  def markdown(e) do
    [
      "# Request scheduling evidence\n\nRequest: `#{e["request_id"]}`. Status: **#{e["status"]}**.\n\n",
      "Generated opportunities: #{e["opportunity_count"]}. Search: `#{e["search"]["status"]}`. Reasons: #{Enum.join(e["reasons"], ", ")}.\n\n",
      for(
        g <- e["generation"],
        do:
          "- #{g["asset_id"]}: #{g["status"]}; opportunity search: #{g["opportunity_search_status"]}\n"
      ),
      "\n",
      for(
        p <- e["placements"],
        do: [
          "## #{p["asset_id"]} / #{p["opportunity_id"]}\n\nDecision: `#{p["decision"]}`. Coverage: `#{p["coverage"]}`. Tested starts: #{p["tested_start_count"]}.\n\n",
          for({reason, count} <- Enum.sort(p["attempt_reasons"]), do: "- #{reason}: #{count}\n"),
          "\n",
          for(
            i <- p["constraint_issues"],
            do:
              "- #{i["kind"]}: #{i["rule_id"] || i["model_id"] || i["reason"]} / #{i["id"] || i["reason"]} at #{i["epoch_s"] || "unspecified epoch"} (#{i["status"] || "unknown"})\n"
          ),
          "\n"
        ]
      ),
      "## Search trials\n\n",
      "Per-request trial evidence: `#{e["search"]["request_trial_evidence"]}`.\n\n",
      for(
        t <- e["search"]["trials"],
        do:
          "- Trial #{t["trial"]}: accepted=#{t["accepted"]}; reason=#{t["reason"]}; request selected=#{if(is_map(t["request_outcome"]), do: t["request_outcome"]["selected"], else: "not captured")}\n"
      ),
      if(is_map(e["search"]["maintenance_search"]),
        do: [
          "\n## Maintenance search\n\n",
          "Status: #{e["search"]["maintenance_search"]["status"]}. Candidate grid truncated: #{e["search"]["maintenance_search"]["candidate_generation_truncated"]}.\n\n",
          for(
            t <- e["search"]["maintenance_search"]["trials"],
            do:
              "- Trial #{t["trial"]}: #{t["planning_status"]}; #{t["reason"]}; maintenance=#{Enum.map_join(t["reservations"], ", ", & &1["request_id"])}; service value=#{t["service_value"]}\n"
          )
        ],
        else: []
      ),
      "\n## Scope\n\n",
      for(l <- e["limits"], do: "- #{l}\n"),
      "\nPer-start margins, timeline neighbors and trial outcomes are in explanation.json.\n"
    ]
  end
end
