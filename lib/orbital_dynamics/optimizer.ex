defmodule OrbitalDynamics.Optimizer do
  @moduledoc """
  Artifact-level optimizer contracts for planner outputs.

  These records explain the optimizer model used to select activities. They do
  not introduce an external solver or hide decisions behind opaque weights.
  """

  @greedy_optimizer "per_spacecraft_greedy_non_overlapping"
  @ranking_comparison_model "scenario_ranking_pairwise_delta"
  @pareto_frontier_model "objective_vector_pareto_frontier"
  @ranking_comparison_model_limits [
    "deterministic_rank_comparison_only",
    "input_order_is_rank_source",
    "no_solver_execution",
    "not_calibrated_from_operational_outcomes"
  ]
  @pareto_frontier_model_limits [
    "deterministic_pareto_summary_only",
    "not_an_optimizer_or_solver",
    "missing_objectives_do_not_dominate",
    "not_calibrated_from_operational_outcomes"
  ]
  @preserved_lineage_fields [
    "id",
    "scenario_id",
    "source_window_id",
    "source_window",
    "score_terms"
  ]

  @doc """
  Declares supported optimizer contract models and known limits.
  """
  def capabilities do
    %{
      artifact_contract: "optimizer_contract.v1",
      models: [@greedy_optimizer],
      comparison_models: [@ranking_comparison_model, @pareto_frontier_model],
      validation_level: :artifact_contract,
      deterministic_ordering: [
        :score_descending,
        :start_time_ascending,
        :id_ascending,
        :scenario_score_descending,
        :scenario_id_ascending
      ],
      preserved_lineage_fields: @preserved_lineage_fields,
      known_limits: [
        :greedy_per_scenario_selection,
        :no_cross_scenario_resource_allocation,
        :no_milp_or_cp_sat_solver,
        :pareto_frontier_summary_not_solver_search,
        :ranking_comparison_not_solver_search,
        :explainable_score_terms_only
      ]
    }
  end

  @doc """
  Returns the declared model limits for ranking comparison reports.
  """
  def ranking_comparison_model_limits, do: @ranking_comparison_model_limits

  @doc """
  Returns the declared model limits for Pareto frontier reports.
  """
  def pareto_frontier_model_limits, do: @pareto_frontier_model_limits

  @doc """
  Builds the V1 optimizer contract for ranked campaign timelines.
  """
  def greedy_timeline_contract(candidates, ranked_timelines, opts \\ [])
      when is_list(candidates) and is_list(ranked_timelines) do
    selected_activities =
      ranked_timelines
      |> List.first(%{})
      |> Map.get("activities", [])

    %{
      "schema_contract" => "optimizer_contract.v1",
      "id" => Keyword.get(opts, :id, optimizer_contract_id(Keyword.get(opts, :plan_id))),
      "optimizer" => @greedy_optimizer,
      "objective" => "maximize weighted observation value and contact value",
      "selection_policy" => "highest_scored_non_overlapping_timeline",
      "candidate_count" => length(candidates),
      "ranked_timeline_count" => length(ranked_timelines),
      "selected_activity_count" => length(selected_activities),
      "selected_activity_ids" => activity_ids(selected_activities),
      "candidate_activity_ids" => activity_ids(candidates),
      "ranked_scenario_ids" => ranked_scenario_ids(ranked_timelines),
      "score_term_keys" => score_term_keys(ranked_timelines),
      "deterministic_ordering" => [
        "candidate score descending",
        "candidate starts_at_s ascending",
        "candidate id ascending",
        "timeline score descending",
        "scenario_id ascending"
      ],
      "preserved_lineage_fields" => @preserved_lineage_fields,
      "constraints" => Keyword.get(opts, :constraints, %{}),
      "scoring_policy" => Keyword.get(opts, :scoring_policy, %{}),
      "known_limits" => Enum.map(capabilities().known_limits, &Atom.to_string/1),
      "assumptions" => %{
        "optimizer_family" => "deterministic_greedy_selector",
        "overlap_policy" =>
          "reject candidate when it overlaps a selected activity in the same scenario",
        "selection_scope" => "per_scenario_then_ranked_plan",
        "external_solver" => false
      }
    }
  end

  @doc """
  Compares two ranked scenario lists using deterministic rank and value deltas.

  Rows may use atom or string keys and must contain a scenario id under
  `:scenario_id` or `"scenario_id"`. The input order is treated as the ranking
  order so the function can compare persisted `scenario_rankings` rows or
  in-memory rows from `OrbitalDynamics.ResultSet.Report.rank/3`.
  """
  def compare_rankings(left_rows, right_rows, opts \\ [])
      when is_list(left_rows) and is_list(right_rows) do
    left = normalize_ranking(left_rows)
    right = normalize_ranking(right_rows)
    left_by_id = Map.new(left, &{&1["scenario_id"], &1})
    right_by_id = Map.new(right, &{&1["scenario_id"], &1})

    scenario_ids =
      (Map.keys(left_by_id) ++ Map.keys(right_by_id))
      |> Enum.uniq()
      |> Enum.sort()

    rows =
      scenario_ids
      |> Enum.map(&comparison_row(&1, left_by_id, right_by_id))
      |> Enum.sort_by(&comparison_sort_key/1)

    %{
      "model" => @ranking_comparison_model,
      "objective" => Keyword.get(opts, :objective, inferred_objective(left, right)),
      "objective_direction" => Keyword.get(opts, :objective_direction),
      "left_label" => Keyword.get(opts, :left_label, "left"),
      "right_label" => Keyword.get(opts, :right_label, "right"),
      "left_count" => length(left),
      "right_count" => length(right),
      "matched_count" => Enum.count(rows, &(&1["status"] == "matched")),
      "left_only_count" => Enum.count(rows, &(&1["status"] == "left_only")),
      "right_only_count" => Enum.count(rows, &(&1["status"] == "right_only")),
      "winner" => winner_summary(List.first(left), List.first(right)),
      "rows" => rows,
      "assumptions" => %{
        "comparison_scope" => "ranked_scenario_rows",
        "rank_source" => "input_order",
        "external_solver" => false
      }
    }
  end

  @doc """
  Builds a schema-versioned ranking comparison report.
  """
  def ranking_comparison_report(left_rows, right_rows, opts \\ [])
      when is_list(left_rows) and is_list(right_rows) do
    comparison = compare_rankings(left_rows, right_rows, opts)

    comparison
    |> Map.put("schema_contract", "ranking_comparison_report.v1")
    |> Map.put("source", Keyword.get(opts, :source, "optimizer.compare_rankings"))
    |> Map.put("model_limits", @ranking_comparison_model_limits)
    |> Map.update!("objective", &(&1 || "unspecified"))
    |> Map.put("row_count", length(comparison["rows"]))
  end

  @doc """
  Builds a deterministic Pareto-frontier summary from scored objective vectors.

  This is an explainability artifact, not a solver. Each row must have an id
  under `:id`, `"id"`, `:scenario_id`, or `"scenario_id"` and objective values
  under `:objectives`, `"objectives"`, `:score_terms`, or `"score_terms"`.
  Directions are supplied as a map of objective key to `"maximize"` or
  `"minimize"`; unspecified objective directions default to `"maximize"`.
  """
  def pareto_frontier_report(rows, opts \\ []) when is_list(rows) do
    alternatives = normalize_objective_vectors(rows)
    directions = objective_directions(alternatives, Keyword.get(opts, :objective_directions, %{}))

    report_rows =
      alternatives
      |> Enum.map(fn alternative ->
        dominated_by_ids =
          alternatives
          |> Enum.reject(&(&1["id"] == alternative["id"]))
          |> Enum.filter(&dominates?(&1, alternative, directions))
          |> Enum.map(& &1["id"])
          |> Enum.sort()

        dominates_ids =
          alternatives
          |> Enum.reject(&(&1["id"] == alternative["id"]))
          |> Enum.filter(&dominates?(alternative, &1, directions))
          |> Enum.map(& &1["id"])
          |> Enum.sort()

        alternative
        |> Map.put("frontier", dominated_by_ids == [])
        |> Map.put("dominated_by_ids", dominated_by_ids)
        |> Map.put("dominates_ids", dominates_ids)
      end)
      |> Enum.sort_by(&pareto_row_sort_key/1)

    frontier_ids =
      report_rows
      |> Enum.filter(& &1["frontier"])
      |> Enum.map(& &1["id"])

    dominated_ids =
      report_rows
      |> Enum.reject(& &1["frontier"])
      |> Enum.map(& &1["id"])

    %{
      "schema_contract" => "pareto_frontier_report.v1",
      "model" => @pareto_frontier_model,
      "source" => Keyword.get(opts, :source, "optimizer.pareto_frontier"),
      "alternative_count" => length(report_rows),
      "objective_count" => map_size(directions),
      "frontier_count" => length(frontier_ids),
      "dominated_count" => length(dominated_ids),
      "frontier_ids" => frontier_ids,
      "dominated_ids" => dominated_ids,
      "objective_directions" => directions,
      "model_limits" => @pareto_frontier_model_limits,
      "rows" => report_rows,
      "assumptions" => %{
        "comparison_scope" => "objective_vectors",
        "dominance_rule" => "no_worse_on_all_objectives_and_better_on_at_least_one",
        "missing_objective_policy" => "alternative_with_missing_objective_cannot_dominate",
        "external_solver" => false,
        "search_performed" => false
      }
    }
  end

  defp optimizer_contract_id(nil), do: "optimizer_contract:v1"
  defp optimizer_contract_id(plan_id), do: "optimizer_contract:#{plan_id}"

  defp activity_ids(activities) do
    activities
    |> Enum.map(&Map.get(&1, "id"))
    |> Enum.reject(&is_nil/1)
  end

  defp ranked_scenario_ids(timelines) do
    timelines
    |> Enum.map(&Map.get(&1, "scenario_id"))
    |> Enum.reject(&is_nil/1)
  end

  defp score_term_keys(timelines) do
    timelines
    |> Enum.flat_map(fn timeline ->
      timeline
      |> Map.get("score_terms", %{})
      |> Map.keys()
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalize_ranking(rows) do
    rows
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {row, rank} ->
      case scenario_id(row) do
        nil ->
          []

        scenario_id ->
          [
            %{
              "scenario_id" => scenario_id,
              "rank" => rank,
              "value" => value(row),
              "objective" => field(row, :objective)
            }
          ]
      end
    end)
  end

  defp comparison_row(scenario_id, left_by_id, right_by_id) do
    left = Map.get(left_by_id, scenario_id)
    right = Map.get(right_by_id, scenario_id)

    %{
      "scenario_id" => scenario_id,
      "status" => comparison_status(left, right),
      "left_rank" => rank(left),
      "right_rank" => rank(right),
      "rank_delta" => rank_delta(left, right),
      "left_value" => value_from_normalized(left),
      "right_value" => value_from_normalized(right),
      "value_delta" => value_delta(left, right)
    }
  end

  defp comparison_sort_key(%{"right_rank" => nil, "left_rank" => nil, "scenario_id" => id}),
    do: {1_000_000, 1_000_000, id}

  defp comparison_sort_key(%{"right_rank" => nil, "left_rank" => left_rank, "scenario_id" => id}),
    do: {1_000_000, left_rank, id}

  defp comparison_sort_key(%{
         "right_rank" => right_rank,
         "left_rank" => left_rank,
         "scenario_id" => id
       }),
       do: {right_rank, left_rank || 1_000_000, id}

  defp winner_summary(nil, nil) do
    %{
      "left_scenario_id" => nil,
      "right_scenario_id" => nil,
      "changed" => false
    }
  end

  defp winner_summary(left, right) do
    left_scenario_id = scenario_id(left)
    right_scenario_id = scenario_id(right)

    %{
      "left_scenario_id" => left_scenario_id,
      "right_scenario_id" => right_scenario_id,
      "changed" => left_scenario_id != right_scenario_id
    }
  end

  defp comparison_status(nil, _right), do: "right_only"
  defp comparison_status(_left, nil), do: "left_only"
  defp comparison_status(_left, _right), do: "matched"

  defp rank(nil), do: nil
  defp rank(row), do: row["rank"]

  defp rank_delta(nil, _right), do: nil
  defp rank_delta(_left, nil), do: nil
  defp rank_delta(left, right), do: left["rank"] - right["rank"]

  defp value_from_normalized(nil), do: nil
  defp value_from_normalized(row), do: row["value"]

  defp value_delta(nil, _right), do: nil
  defp value_delta(_left, nil), do: nil

  defp value_delta(left, right) do
    left_value = left["value"]
    right_value = right["value"]

    if is_number(left_value) and is_number(right_value) do
      right_value - left_value
    end
  end

  defp inferred_objective(left, right) do
    (left ++ right)
    |> Enum.map(& &1["objective"])
    |> Enum.reject(&is_nil/1)
    |> List.first()
  end

  defp normalize_objective_vectors(rows) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn row ->
      id = Map.get(row, "id") || Map.get(row, "scenario_id")
      objectives = Map.get(row, "objectives") || Map.get(row, "score_terms") || %{}

      cond do
        is_nil(id) ->
          []

        not is_map(objectives) ->
          []

        true ->
          objective_values =
            objectives
            |> stringify_keys()
            |> Enum.flat_map(fn
              {key, value} ->
                case numeric_value(value) do
                  number when is_number(number) -> [{key, number}]
                  nil -> []
                end
            end)
            |> Map.new()

          [
            %{
              "id" => id,
              "scenario_id" => Map.get(row, "scenario_id", id),
              "objective_values" => objective_values,
              "objective_keys" => objective_values |> Map.keys() |> Enum.sort()
            }
          ]
      end
    end)
  end

  defp objective_directions(alternatives, supplied_directions) do
    supplied_directions = stringify_keys(supplied_directions || %{})

    alternatives
    |> Enum.flat_map(& &1["objective_keys"])
    |> Enum.uniq()
    |> Enum.sort()
    |> Map.new(fn key ->
      direction =
        case Map.get(supplied_directions, key, "maximize") do
          direction when direction in [:minimize, "minimize"] -> "minimize"
          _direction -> "maximize"
        end

      {key, direction}
    end)
  end

  defp dominates?(left, right, directions) do
    objective_keys = Map.keys(directions)

    objective_keys != [] and
      Enum.all?(objective_keys, &no_worse?(left, right, &1, Map.fetch!(directions, &1))) and
      Enum.any?(objective_keys, &better?(left, right, &1, Map.fetch!(directions, &1)))
  end

  defp no_worse?(left, right, key, direction) do
    left_value = get_in(left, ["objective_values", key])
    right_value = get_in(right, ["objective_values", key])

    cond do
      not is_number(left_value) or not is_number(right_value) -> false
      direction == "minimize" -> left_value <= right_value
      true -> left_value >= right_value
    end
  end

  defp better?(left, right, key, direction) do
    left_value = get_in(left, ["objective_values", key])
    right_value = get_in(right, ["objective_values", key])

    cond do
      not is_number(left_value) or not is_number(right_value) -> false
      direction == "minimize" -> left_value < right_value
      true -> left_value > right_value
    end
  end

  defp pareto_row_sort_key(row), do: {if(row["frontier"], do: 0, else: 1), row["id"]}

  defp scenario_id(row), do: field(row, :scenario_id)
  defp value(row), do: numeric_value(field(row, :value))

  defp numeric_value(value) when is_number(value), do: value

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp field(nil, _key), do: nil

  defp field(%{} = row, key) do
    Map.get(row, key) || Map.get(row, Atom.to_string(key))
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp stringify_keys(_value), do: %{}
end
