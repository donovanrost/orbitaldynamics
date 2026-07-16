defmodule OrbitalDynamics.CampaignPlanner.ScoreReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ScalarValues, ValueEncoding}

  def objective_tradeoff_report(timelines, policy, model_limits) do
    best_score =
      timelines
      |> List.first()
      |> case do
        %{"score" => score} when is_number(score) -> score
        _timeline -> 0.0
      end

    tradeoffs =
      timelines
      |> Enum.with_index(1)
      |> Enum.map(fn {timeline, rank} ->
        objective_tradeoff_row(timeline, rank, best_score)
      end)

    %{
      "schema_contract" => "objective_tradeoff_report.v1",
      "model" => "ranked_timeline_score_term_tradeoffs",
      "objective" => "maximize weighted observation value and contact value",
      "ranking_count" => length(timelines),
      "score_term_keys" => objective_score_term_keys(timelines),
      "policy" => policy,
      "model_limits" => model_limits,
      "tradeoffs" => tradeoffs,
      "assumptions" => %{
        "source" => "campaign_plan.ranked_timelines",
        "selection" => "best_ranked_timeline_is_selected",
        "score_delta_from_selected" => "row_score_minus_selected_score"
      }
    }
  end

  def repair_objective_tradeoff_report(timeline, policy, model_limits) do
    %{
      "schema_contract" => "objective_tradeoff_report.v1",
      "model" => "repair_score_term_tradeoffs",
      "objective" =>
        "maximize repaired activity value while minimizing churn, schedule movement, resource-projection pressure, contact pressure, resource-filter pressure, refresh-budget pressure, candidate-rejection pressure, operational-readiness pressure, and quality-gate pressure",
      "ranking_count" => 1,
      "score_term_keys" => objective_score_term_keys([timeline]),
      "policy" => policy,
      "model_limits" => model_limits,
      "tradeoffs" => [objective_tradeoff_row(timeline, 1, candidate_score(timeline))],
      "assumptions" => %{
        "source" => "campaign_repair.score_terms",
        "selection" => "single_repaired_timeline",
        "score_delta_from_selected" => "row_score_minus_repaired_score"
      }
    }
  end

  def score_term_report(timelines, policy, model_limits) do
    rows =
      timelines
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {timeline, rank} -> score_term_rows(timeline, rank) end)
      |> Enum.sort_by(&{&1["rank"], &1["scenario_id"], &1["term_key"]})

    %{
      "schema_contract" => "score_term_report.v1",
      "model" => "ranked_timeline_score_terms",
      "source" => "campaign_plan.ranked_timelines",
      "row_count" => length(rows),
      "score_term_keys" => objective_score_term_keys(timelines),
      "model_limits" => model_limits,
      "rows" => rows,
      "assumptions" => %{
        "score_term_source" => "ranked_timeline.score_terms",
        "policy" => policy
      }
    }
  end

  def repair_score_term_report(timeline, policy, model_limits) do
    rows =
      timeline
      |> score_term_rows(1)
      |> Enum.sort_by(&{&1["rank"], &1["scenario_id"], &1["term_key"]})

    %{
      "schema_contract" => "score_term_report.v1",
      "model" => "repair_score_terms",
      "source" => "campaign_repair.score_terms",
      "row_count" => length(rows),
      "score_term_keys" => objective_score_term_keys([timeline]),
      "model_limits" => model_limits,
      "rows" => rows,
      "assumptions" => %{
        "score_term_source" => "campaign_repair.score_terms",
        "policy" => policy
      }
    }
  end

  defp candidate_score(candidate),
    do: ScalarValues.numeric_or_nil(Map.get(candidate, "score")) || 0.0

  defp objective_tradeoff_row(timeline, rank, best_score) do
    score = candidate_score(timeline)
    score_terms = Map.get(timeline, "score_terms", %{})
    activities = Map.get(timeline, "activities", [])

    %{
      "rank" => rank,
      "scenario_id" => Map.get(timeline, "scenario_id"),
      "score" => score,
      "score_delta_from_selected" => score - best_score,
      "activity_count" => Map.get(timeline, "activity_count", length(activities)),
      "selected_observation_count" => Map.get(score_terms, "selected_observation_count", 0),
      "selected_contact_count" => Map.get(score_terms, "selected_contact_count", 0),
      "score_terms" => score_terms,
      "activity_ids" => Enum.map(activities, & &1["id"])
    }
  end

  defp objective_score_term_keys(timelines) do
    timelines
    |> Enum.flat_map(fn timeline ->
      timeline
      |> Map.get("score_terms", %{})
      |> Map.keys()
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp score_term_rows(timeline, rank) do
    scenario_id = Map.get(timeline, "scenario_id")
    timeline_score = candidate_score(timeline)

    timeline
    |> Map.get("score_terms", %{})
    |> Enum.map(fn {term_key, value} ->
      %{
        "id" => score_term_row_id(scenario_id, rank, term_key),
        "rank" => rank,
        "scenario_id" => scenario_id,
        "term_key" => term_key,
        "value" => value,
        "timeline_score" => timeline_score,
        "selected" => rank == 1
      }
    end)
  end

  defp score_term_row_id(scenario_id, rank, term_key) do
    ["score_term", scenario_id, rank, term_key]
    |> Enum.map(&ValueEncoding.encode_value/1)
    |> Enum.join(":")
  end
end
