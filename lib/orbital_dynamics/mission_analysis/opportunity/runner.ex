defmodule OrbitalDynamics.MissionAnalysis.Opportunity.Runner do
  @moduledoc false
  alias OrbitalDynamics.{Epoch, EventSearch}
  alias OrbitalDynamics.EventSearch.Source
  alias OrbitalDynamics.MissionAnalysis.Opportunity.{Windows, Functions, Endpoints}

  def run(asset, request, session, refinement, policy) do
    states = asset.trajectory.states
    first = hd(states)
    last = List.last(states)

    source =
      Source.new!(
        fn t -> refinement.state_at.(asset, t) end,
        first.epoch,
        last.epoch,
        first.frame,
        %{
          "evaluation" => "planning_runtime_state_sampler",
          "asset_id" => asset.id,
          "trajectory_assumptions" => asset.trajectory.assumptions
        }
      )

    start = max(request.starts_at_s, first.epoch.seconds_since_j2000)
    stop = min(request.ends_at_s, last.epoch.seconds_since_j2000)

    cond do
      start >= stop ->
        {:ok, [], [], %{"status" => "no_state_coverage", "windows" => []}}

      not function_exported?(request.model, :opportunity_functions, 3) ->
        {:ok, [], [], %{"status" => "model_opportunity_constraints_unavailable", "windows" => []}}

      true ->
        search(asset, request, session, refinement, policy, source, start, stop)
    end
  end

  defp search(_asset, request, session, refinement, policy, source, start, stop) do
    with {:ok, functions} <-
           request.model.opportunity_functions(session, source, refinement.tracking_lookback_s),
         :ok <- validate_functions(functions),
         evaluation =
           Functions.evaluator(
             request.model,
             session,
             source,
             refinement.tracking_lookback_s,
             Enum.map(functions, & &1.id)
           ),
         {:ok, report} <-
           EventSearch.run(
             source,
             [evaluation | Enum.map(functions, &checked_function(&1, evaluation))],
             starts_at: Epoch.new!(start, request.time_scale),
             ends_at: Epoch.new!(stop, request.time_scale),
             max_check_step_s: policy.max_check_step_s,
             time_tolerance_s: policy.time_tolerance_s,
             max_iterations: policy.max_iterations,
             max_evaluations: policy.max_evaluations,
             include_samples: true,
             record_function_observations: [evaluation.id]
           ) do
      composition = Windows.compose(report, policy, request.duration_s)

      samples =
        for row <- report["function_observations"] do
          Map.merge(
            %{"epoch_s" => row["epoch_s"]},
            row["metadata"] ||
              %{
                "feasible" => false,
                "checks" => [%{"id" => "event_evaluation_unknown", "passed" => false}],
                "metrics" => %{}
              }
          )
        end

      spent = report["source_query_count"] + report["function_evaluation_count"]

      with {:ok, checked, endpoints, counts} <-
             Endpoints.check(
               composition["windows"],
               evaluation,
               source,
               policy.max_evaluations - spent
             ) do
        samples =
          (samples ++ endpoints) |> Enum.sort_by(& &1["epoch_s"])

        # Audit every cached complete-model evaluation, including nested root
        # refinement and midpoint queries, before emitting schedulable windows.
        checked =
          for w <- checked do
            contradicted =
              Enum.any?(
                samples,
                &(&1["epoch_s"] >= w["starts_at_s"] and &1["epoch_s"] <= w["ends_at_s"] and
                    not &1["feasible"])
              )

            if w["status"] == "accepted" and contradicted,
              do:
                Map.merge(w, %{
                  "status" => "rejected",
                  "reason" => "observed_model_contradiction",
                  "first_contradiction" =>
                    Enum.find(
                      samples,
                      &(&1["epoch_s"] >= w["starts_at_s"] and &1["epoch_s"] <= w["ends_at_s"] and
                          not &1["feasible"])
                    )
                }),
              else: w
          end

        composition = Map.put(composition, "windows", checked)

        windows =
          for w <- checked, w["status"] == "accepted" do
            count =
              Enum.count(
                samples,
                &(&1["feasible"] and &1["epoch_s"] >= w["starts_at_s"] and
                    &1["epoch_s"] <= w["ends_at_s"])
              )

            Map.put(w, "sample_count", count)
          end

        report =
          Map.update!(report, "results", fn rows ->
            Enum.map(rows, fn row ->
              Map.update!(row, "scan_samples", fn scans ->
                Enum.map(scans, fn scan ->
                  Map.update(scan, "metadata", %{}, &Map.delete(&1, "evaluation"))
                end)
              end)
            end)
          end)

        {:ok, windows, samples,
         Map.merge(composition, %{
           "status" =>
             if(report["status"] == "unknown" and windows != [],
               do: "partial_under_search_policy",
               else: report["status"]
             ),
           "event_search" => report,
           "requested_window" => %{
             "starts_at_s" => request.starts_at_s,
             "ends_at_s" => request.ends_at_s
           },
           "searched_window" => %{"starts_at_s" => start, "ends_at_s" => stop},
           "endpoint_budget_counts" => %{
             "source_queries" => counts.source_queries,
             "function_evaluations" => counts.function_evaluations
           },
           "total_evaluation_count" => spent + counts.source_queries + counts.function_evaluations
         })}
      end
    end
  end

  defp checked_function(function, evaluation) do
    %{
      function
      | evaluate: fn state ->
          with {:ok, _, _, sample} <- OrbitalDynamics.EventSearch.Function.call(evaluation, state),
               {:ok, value, rate, metadata} <-
                 OrbitalDynamics.EventSearch.Function.call(function, state) do
            check = Enum.find(sample["checks"], &(&1["id"] == function.id))
            strict = function.assumptions["strict_condition"] == true

            unless strict == (check["margin_comparison"] == "strict_min"),
              do:
                raise(
                  ArgumentError,
                  "opportunity strict declaration disagrees with complete model check #{function.id}"
                )

            eligible =
              case {function.condition, strict} do
                {:nonnegative, true} -> value > 0
                {:nonnegative, false} -> value >= 0
                {:nonpositive, true} -> value < 0
                {:nonpositive, false} -> value <= 0
              end

            unless check["passed"] == eligible,
              do:
                raise(
                  ArgumentError,
                  "opportunity scalar disagrees with complete model check #{function.id}"
                )

            {:ok, value, rate, metadata}
          end
        end
    }
  end

  defp validate_functions(fs) do
    if is_list(fs) and length(fs) in 1..31 and
         Enum.all?(
           fs,
           &match?(
             %OrbitalDynamics.EventSearch.Function{condition: c, direction: :any}
             when c in [:nonnegative, :nonpositive],
             &1
           )
         ), do: :ok, else: {:error, :opportunity_functions_must_declare_conditions}
  end
end
