defmodule OrbitalDynamics.CandidateRefresh.CandidateBudget do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ModelLimits

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  def apply(candidates, refresh) do
    policy = candidate_limit_policy(refresh)
    max_candidates = Map.get(policy, "max_candidate_activities")
    indexed_candidates = Enum.with_index(candidates)

    selected_indexed_candidates =
      case max_candidates do
        value when is_integer(value) and value > 0 ->
          indexed_candidates
          |> Enum.sort_by(fn {candidate, _index} -> candidate_budget_sort_key(candidate) end)
          |> Enum.take(value)
          |> Enum.sort_by(fn {candidate, _index} -> candidate_artifact_sort_key(candidate) end)

        _value ->
          indexed_candidates
      end

    selected_indexes =
      selected_indexed_candidates
      |> Enum.map(fn {_candidate, index} -> index end)
      |> MapSet.new()

    dropped_indexed_candidates =
      indexed_candidates
      |> Enum.reject(fn {_candidate, index} -> MapSet.member?(selected_indexes, index) end)
      |> Enum.sort_by(fn {candidate, _index} -> candidate_artifact_sort_key(candidate) end)

    selected_candidates =
      Enum.map(selected_indexed_candidates, fn {candidate, _index} -> candidate end)

    dropped_candidates =
      Enum.map(dropped_indexed_candidates, fn {candidate, _index} -> candidate end)

    {
      selected_candidates,
      dropped_candidates,
      report(
        candidates,
        selected_indexed_candidates,
        dropped_indexed_candidates,
        policy
      )
    }
  end

  defp candidate_limit_policy(refresh) do
    policy = raw_candidate_limit_policy(refresh)
    max_candidate_activities = if is_map(policy), do: Map.get(policy, "max_candidate_activities")

    normalized_max_candidate_activities =
      candidate_limit_count(max_candidate_activities)

    %{
      "max_candidate_activities" => normalized_max_candidate_activities,
      "invalid_candidate_limit_policy" => invalid_candidate_limit_policy?(policy),
      "invalid_candidate_limit_policy_reason" =>
        invalid_candidate_limit_policy_reason(policy, max_candidate_activities),
      "source_candidate_limit_policy" =>
        if(invalid_candidate_limit_policy?(policy),
          do: source_candidate_limit_policy(policy)
        ),
      "selection_order" => "score_descending_then_start_then_id"
    }
    |> Common.compact_map()
  end

  defp raw_candidate_limit_policy(%{"candidate_limit_policy" => policy}), do: policy
  defp raw_candidate_limit_policy(_refresh), do: %{}

  defp invalid_candidate_limit_policy?(policy) when not is_map(policy), do: true

  defp invalid_candidate_limit_policy?(%{"max_candidate_activities" => value}) do
    not is_integer(candidate_limit_count(value))
  end

  defp invalid_candidate_limit_policy?(_policy), do: false

  defp invalid_candidate_limit_policy_reason(policy, _value)
       when not is_map(policy),
       do: "candidate_limit_policy_must_be_object"

  defp invalid_candidate_limit_policy_reason(
         %{"max_candidate_activities" => value},
         value
       )
       when is_integer(value) and value <= 0,
       do: "max_candidate_activities_must_be_positive"

  defp invalid_candidate_limit_policy_reason(
         %{"max_candidate_activities" => value},
         value
       ) do
    case {candidate_limit_count(value), NumericValue.value(value)} do
      {count, _number} when is_integer(count) ->
        nil

      {_count, number} when is_number(number) and number <= 0.0 ->
        "max_candidate_activities_must_be_positive"

      {_count, number} when is_number(number) ->
        "max_candidate_activities_must_be_integer"

      _value ->
        "max_candidate_activities_must_be_integer"
    end
  end

  defp invalid_candidate_limit_policy_reason(_policy, _value), do: nil

  defp candidate_limit_count(value) do
    case NumericValue.value(value) do
      number when is_number(number) and number > 0.0 and number == trunc(number) * 1.0 ->
        trunc(number)

      _value ->
        nil
    end
  end

  defp source_candidate_limit_policy(policy) when is_map(policy), do: policy

  defp source_candidate_limit_policy(policy) do
    %{"invalid_policy_shape" => EncodedValue.value_with_keyword_maps(policy)}
  end

  defp report(
         candidates,
         selected_indexed_candidates,
         dropped_indexed_candidates,
         policy
       ) do
    budget_id_by_index = candidate_budget_id_by_index(candidates)

    %{
      "schema_contract" => "refresh_budget_report.v1",
      "model" => "deterministic_candidate_limit_after_filters",
      "model_limits" => ModelLimits.strings(),
      "input_candidate_count" => length(candidates),
      "kept_candidate_count" => length(selected_indexed_candidates),
      "dropped_candidate_count" => length(dropped_indexed_candidates),
      "max_candidate_activities" =>
        Map.get(policy, "max_candidate_activities") || length(candidates),
      "invalid_candidate_limit_policy" => Map.get(policy, "invalid_candidate_limit_policy"),
      "invalid_candidate_limit_policy_reason" =>
        Map.get(policy, "invalid_candidate_limit_policy_reason"),
      "source_candidate_limit_policy" => Map.get(policy, "source_candidate_limit_policy"),
      "selection_order" => Map.fetch!(policy, "selection_order"),
      "kept_candidate_ids" =>
        candidate_budget_ids(selected_indexed_candidates, budget_id_by_index),
      "dropped_candidate_ids" =>
        candidate_budget_ids(dropped_indexed_candidates, budget_id_by_index),
      "assumptions" => %{
        "budget_stage" => "after_contact_resource_and_allocation_filters",
        "selection_policy" => "highest_score_candidates_are_kept_then_artifact_order_is_restored",
        "optimizer_search_performed" => false
      }
    }
    |> Common.compact_map()
  end

  defp candidate_budget_id_by_index(candidates) do
    duplicate_ids =
      candidates
      |> Enum.map(&Map.get(&1, "id"))
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.frequencies()
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> MapSet.new(fn {id, _count} -> id end)

    {_counts, id_by_index} =
      candidates
      |> Enum.with_index()
      |> Enum.reduce({%{}, %{}}, fn {candidate, index}, {counts, id_by_candidate} ->
        candidate_id = Map.get(candidate, "id")
        occurrence = Map.get(counts, candidate_id, 0) + 1
        counts = Map.put(counts, candidate_id, occurrence)

        budget_id =
          if MapSet.member?(duplicate_ids, candidate_id) and occurrence > 1 do
            "#{candidate_id}:occurrence:#{occurrence}"
          else
            candidate_id
          end

        {counts, Map.put(id_by_candidate, index, budget_id)}
      end)

    id_by_index
  end

  defp candidate_budget_ids(indexed_candidates, id_by_index) do
    indexed_candidates
    |> Enum.map(fn {candidate, index} ->
      Map.get(id_by_index, index) || Map.get(candidate, "id")
    end)
  end

  defp candidate_budget_sort_key(candidate) do
    {
      -(Map.get(candidate, "score", 0.0) * 1.0),
      Map.get(candidate, "starts_at_s") || :infinity,
      Map.get(candidate, "ends_at_s") || :infinity,
      Map.get(candidate, "id") || ""
    }
  end

  defp candidate_artifact_sort_key(candidate) do
    {
      Map.get(candidate, "scenario_id") || "",
      Map.get(candidate, "starts_at_s") || :infinity,
      Map.get(candidate, "id") || ""
    }
  end
end
