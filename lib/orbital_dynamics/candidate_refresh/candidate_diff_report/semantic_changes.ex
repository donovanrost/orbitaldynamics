defmodule OrbitalDynamics.CandidateRefresh.CandidateDiffReport.SemanticChanges do
  @moduledoc false

  def replacement_change_details(_candidate, nil), do: []

  def replacement_change_details(_candidate, {:ambiguous, _candidates}), do: []

  def replacement_change_details(candidate, {:unique, match}),
    do: change_details(candidate, match)

  def prior_change_details(nil, _candidate), do: []
  def prior_change_details({:ambiguous, _candidates}, _candidate), do: []

  def prior_change_details({:unique, prior_candidate}, candidate),
    do: change_details(prior_candidate, candidate)

  def put_match_ambiguity(row, {:ambiguous, candidates}, role) do
    row
    |> Map.put("semantic_match_status", "ambiguous_#{role}_candidate")
    |> Map.put("semantic_match_candidate_count", length(candidates))
    |> Map.put("semantic_match_candidate_ids", Enum.map(candidates, &Map.get(&1, "id")))
  end

  def put_match_ambiguity(row, _match, _role), do: row

  def put_changed_fields(row, change_details) do
    case change_fields(change_details) do
      [] ->
        row

      fields ->
        row
        |> Map.put("changed_fields", fields)
        |> Map.put("candidate_diff_changed_fields", fields)
        |> Map.put("candidate_diff_changed_field_count", length(fields))
    end
  end

  def change_detail_reasons(details) do
    details
    |> Enum.map(&Map.get(&1, "reason"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  def change_details(nil, _candidate), do: []
  def change_details(_prior_candidate, nil), do: []

  def change_details(prior_candidate, candidate) do
    [
      change_detail(prior_candidate, candidate, "type"),
      change_detail(prior_candidate, candidate, "scenario_id"),
      change_detail(prior_candidate, candidate, "target_id"),
      change_detail(prior_candidate, candidate, "ground_station_id"),
      change_detail(prior_candidate, candidate, "starts_at_s"),
      change_detail(prior_candidate, candidate, "ends_at_s"),
      source_window_change_detail(prior_candidate, candidate),
      change_detail(prior_candidate, candidate, "estimated_throughput_mb"),
      change_detail(prior_candidate, candidate, "target_priority"),
      change_detail(prior_candidate, candidate, "observation_success_factor"),
      change_detail(prior_candidate, candidate, "contact_success_factor"),
      change_detail(prior_candidate, candidate, "station_availability"),
      change_detail(prior_candidate, candidate, "station_contention_status"),
      change_detail(prior_candidate, candidate, "station_calendar_entry_id"),
      change_detail(prior_candidate, candidate, "station_calendar_provider_id"),
      change_detail(prior_candidate, candidate, "station_calendar_provider_entry_id"),
      change_detail(prior_candidate, candidate, "station_reservation_id"),
      change_detail(prior_candidate, candidate, "station_reservation_status"),
      change_detail(prior_candidate, candidate, "station_reservation_expires_at_s"),
      change_detail(prior_candidate, candidate, "station_reservation_match_status"),
      nested_change_detail(
        prior_candidate,
        candidate,
        ["throughput_model", "station_capacity_fraction"],
        "station_capacity_fraction"
      ),
      nested_change_detail(
        prior_candidate,
        candidate,
        ["throughput_model", "station_throughput_factor"],
        "station_throughput_factor"
      )
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq_by(&Map.get(&1, "field"))
  end

  def candidate_groups(candidates) do
    candidates
    |> Enum.map(&{candidate_semantic_key(&1), &1})
    |> Enum.reject(fn {key, _candidate} -> is_nil(key) end)
    |> Enum.group_by(fn {key, _candidate} -> key end, fn {_key, candidate} -> candidate end)
  end

  def candidate_match(groups, candidate) do
    case Map.get(groups, candidate_semantic_key(candidate), []) do
      [] -> nil
      [match] -> {:unique, match}
      matches -> {:ambiguous, matches}
    end
  end

  defp change_fields(details) do
    details
    |> List.wrap()
    |> Enum.map(&Map.get(&1, "field"))
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp change_detail(prior_candidate, candidate, field) do
    prior_value = Map.get(prior_candidate, field)
    value = Map.get(candidate, field)

    if not is_nil(prior_value) and not is_nil(value) and prior_value != value do
      change_detail(field, prior_value, value, field, field)
    end
  end

  defp nested_change_detail(prior_candidate, candidate, path, field) do
    prior_value = get_in(prior_candidate, path)
    value = get_in(candidate, path)

    if not is_nil(prior_value) and not is_nil(value) and prior_value != value do
      path = Enum.join(path, ".")
      change_detail(field, prior_value, value, path, path)
    end
  end

  defp source_window_change_detail(prior_candidate, candidate) do
    prior_source_window_id =
      Map.get(prior_candidate, "source_window_id") ||
        get_in(prior_candidate, ["source_window", "id"])

    source_window_id =
      Map.get(candidate, "source_window_id") || get_in(candidate, ["source_window", "id"])

    if not is_nil(prior_source_window_id) and not is_nil(source_window_id) and
         prior_source_window_id != source_window_id do
      change_detail(
        "source_window_id",
        prior_source_window_id,
        source_window_id,
        source_window_id_path(prior_candidate),
        source_window_id_path(candidate)
      )
    end
  end

  defp change_detail(field, prior_value, value, prior_path, refreshed_path) do
    %{
      "field" => field,
      "reason" => field <> "_changed",
      "prior_path" => prior_path,
      "refreshed_path" => refreshed_path,
      "prior_value" => prior_value,
      "refreshed_value" => value
    }
  end

  defp source_window_id_path(candidate) do
    if Map.has_key?(candidate, "source_window_id") do
      "source_window_id"
    else
      "source_window.id"
    end
  end

  defp candidate_semantic_key(candidate) do
    type = Map.get(candidate, "type")
    scenario_id = Map.get(candidate, "scenario_id")
    subject_id = Map.get(candidate, "target_id") || Map.get(candidate, "ground_station_id")

    if type && scenario_id && subject_id do
      {type, scenario_id, subject_id}
    end
  end
end
