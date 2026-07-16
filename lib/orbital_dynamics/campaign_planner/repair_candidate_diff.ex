defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateDiff do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{CandidateReviewSourceReports, ValueEncoding}

  def report(nil), do: nil

  def report(%{} = candidate_refresh) do
    case Map.get(candidate_refresh, "candidate_diff_report") do
      %{} = report -> ValueEncoding.stringify_keys(report)
      _report -> nil
    end
  end

  def replacements(nil), do: %{}

  def replacements(%{} = candidate_refresh) do
    candidate_refresh
    |> report()
    |> case do
      %{} = report ->
        replacements_by_invalidated_id(report)

      _report ->
        %{}
    end
  end

  def replacements_by_invalidated_id(%{} = report) do
    report
    |> replacement_rows()
    |> group_replacement_rows(&Map.get(&1, "id"))
  end

  def replacements_by_replacement_id(nil), do: %{}

  def replacements_by_replacement_id(%{} = report) do
    report
    |> replacement_rows()
    |> group_replacement_rows(&Map.get(&1, "replacement_candidate_id"))
  end

  def replacement_rows(report) do
    CandidateReviewSourceReports.candidate_diff_replacement_rows(report)
  end

  def replacement_map_rows(replacements_by_key) do
    replacements_by_key
    |> Map.values()
    |> Enum.flat_map(fn
      rows when is_list(rows) -> rows
      row -> [row]
    end)
  end

  def match(nil, _scope), do: nil
  def match([], _scope), do: nil
  def match(%{} = row, _scope), do: row
  def match([row], _scope), do: row

  def match(rows, scope) when is_list(rows) do
    replacement_ids =
      rows
      |> Enum.map(&Map.get(&1, "replacement_candidate_id"))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    budget_dropped_candidate_ids =
      rows
      |> Enum.flat_map(&(Map.get(&1, "budget_dropped_candidate_ids") || []))
      |> Enum.uniq()
      |> Enum.sort()

    %{
      "replacement_candidate_id" => single_value(replacement_ids),
      "invalidated_reason" => "ambiguous_candidate_diff_match",
      "candidate_diff_match_status" => "ambiguous_#{scope}_candidate_diff",
      "candidate_diff_match_count" => length(rows),
      "invalidated_candidate_ids" =>
        Enum.map(rows, &(Map.get(&1, "invalidated_candidate_id") || Map.get(&1, "id"))),
      "candidate_budget_match_status" =>
        single_value(
          rows
          |> Enum.map(&Map.get(&1, "candidate_budget_match_status"))
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()
        ),
      "candidate_budget_match_count" =>
        case budget_dropped_candidate_ids do
          [] -> nil
          ids -> length(ids)
        end,
      "budget_dropped_candidate_ids" => budget_dropped_candidate_ids,
      "semantic_change_reasons" =>
        rows
        |> Enum.flat_map(&Map.get(&1, "semantic_change_reasons", []))
        |> Enum.uniq()
        |> Enum.sort()
    }
    |> ValueEncoding.compact_map()
  end

  defp group_replacement_rows(rows, key_fun) do
    rows
    |> Enum.group_by(key_fun)
    |> Enum.reject(fn {key, _rows} -> is_nil(key) end)
    |> Map.new()
  end

  defp single_value([value]), do: value
  defp single_value(_values), do: nil
end
