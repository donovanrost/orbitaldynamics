defmodule OrbitalDynamics.MissionAnalysis.Opportunity.Functions do
  @moduledoc "Shared model-evaluation adapter for named scalar margins and explicit known-value guards."
  alias OrbitalDynamics.EventSearch.{Function, Source}
  alias OrbitalDynamics.MissionAnalysis.Evaluation

  @doc "Build all required constraint functions; overrides supply explicit continuous geometric margins."
  def from_evaluation(model, session, source, lookback, specs, overrides \\ %{}) do
    specs =
      Enum.map(specs, fn
        {id, unit, tol} -> {id, unit, tol, false}
        {_, _, _, _} = s -> s
      end)

    ids = Enum.map(specs, &elem(&1, 0))

    unless length(ids) in 1..32 and length(ids) == length(Enum.uniq(ids)),
      do: raise(ArgumentError, "unique complete opportunity constraint declarations required")

    evaluation = evaluator(model, session, source, lookback, ids)

    for {id, unit, tolerance, strict} <- specs do
      Function.new!(
        id,
        fn state ->
          with {:ok, _, _, sample} <- Function.call(evaluation, state) do
            check = Enum.find(sample["checks"], &(&1["id"] == id))

            unless strict == (check["margin_comparison"] == "strict_min"),
              do: raise(ArgumentError, "strict constraint declaration mismatch for #{id}")

            output =
              case Map.fetch(overrides, id) do
                {:ok, callback} -> callback.(state, sample, check)
                :error -> margin(check, unit)
              end

            case output do
              {:ok, value, rate, metadata} ->
                expected =
                  if check["margin_comparison"] == "strict_min", do: value > 0, else: value >= 0

                unless expected == check["passed"],
                  do: raise(ArgumentError, "constraint margin disagrees with model check #{id}")

                metadata = Map.put(metadata, "check_id", id)

                {:ok, value, rate, metadata}

              other ->
                other
            end
          end
        end,
        units: unit,
        value_tolerance: tolerance,
        condition: :nonnegative,
        assumptions: %{
          "strict_condition" => strict,
          "source" => "complete_named_model_checks",
          "fixed_lookback_s" => lookback,
          "limits" =>
            "guards become unknown when prerequisites are unavailable; scalar margins must be continuous on their declared known domain"
        }
      )
    end
  end

  @doc false
  def evaluator(model, session, source, lookback, ids) do
    Function.new!(
      "mission-evaluation",
      fn state ->
        t = state.epoch.seconds_since_j2000 - lookback

        with {:ok, prior} <-
               if(t < source.start.seconds_since_j2000,
                 do: {:ok, nil},
                 else: Source.at(source, t)
               ),
             {:ok, %Evaluation{} = result} <- model.evaluate(state, prior, session) do
          result = Evaluation.new!(result.checks, result.metrics)

          unless Enum.sort(Enum.map(result.checks, & &1["id"])) == Enum.sort(ids),
            do:
              raise(
                ArgumentError,
                "opportunity declarations must cover every model check exactly"
              )

          {:ok, 1, nil,
           %{
             "checks" => result.checks,
             "metrics" => result.metrics,
             "feasible" => Evaluation.feasible?(result)
           }}
        end
      end,
      units: "1",
      value_tolerance: 0
    )
  end

  defp margin(%{"margin" => :null}, _), do: {:unknown, :constraint_margin_unavailable}

  defp margin(%{"margin" => value, "margin_unit" => unit}, unit) when is_number(value),
    do: {:ok, value, nil, %{}}

  defp margin(%{"margin" => _}, _), do: {:error, :constraint_margin_unit_mismatch}
  defp margin(%{"passed" => true}, "1"), do: {:ok, 1, nil, %{"guard" => "prerequisite_known"}}
  defp margin(_, "1"), do: {:unknown, :constraint_prerequisite_unavailable}
  defp margin(_, _), do: {:error, :constraint_requires_explicit_scalar_margin}
end
