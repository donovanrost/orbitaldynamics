defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.TimelineDiffDownlinkRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues

  @provider_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "uplink" => "uplink",
    "up" => "uplink",
    "up_link" => "uplink",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "downlink" => "downlink",
    "down_link" => "downlink",
    "tracking" => "tracking",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "health_check" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check",
    "contact" => "contact"
  }

  def timeline_diff_removed_downlink_feedback_row?(%{} = row) do
    timeline_diff_status(row) == "removed" and
      timeline_diff_removed_downlink_activity?(row) and
      timeline_diff_removed_downlink_station_id(row) not in [nil, ""] and
      positive_number_value?(timeline_diff_removed_downlink_required_mb(row))
  end

  def timeline_diff_changed_downlink_shortfall_feedback_row?(%{} = row) do
    timeline_diff_status(row) == "changed" and
      timeline_diff_downlink_activity?(row) and
      timeline_diff_changed_downlink_station_id(row) not in [nil, ""] and
      positive_number_value?(timeline_diff_changed_downlink_shortfall_mb(row))
  end

  def merge_removed_downlink_feedback(row, feedback) do
    station_id = timeline_diff_removed_downlink_station_id(row)
    required_mb = timeline_diff_removed_downlink_required_mb(row)
    source = timeline_diff_removed_downlink_source(row)
    context = timeline_diff_removed_downlink_context(row)

    feedback
    |> update_in(["downlink_demand_mb"], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(station_id, required_mb, &(&1 + required_mb))
    end)
    |> update_in(["downlink_demand_sources"], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(station_id, [source], fn existing ->
        (List.wrap(existing) ++ [source])
        |> Enum.uniq()
        |> Enum.sort()
      end)
    end)
    |> update_in(["downlink_demand_context"], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(station_id, context, &merge_downlink_demand_context(&1, context))
    end)
  end

  def merge_changed_downlink_shortfall_feedback(row, feedback) do
    station_id = timeline_diff_changed_downlink_station_id(row)
    shortfall_mb = timeline_diff_changed_downlink_shortfall_mb(row)
    source = timeline_diff_changed_downlink_shortfall_source(row)
    context = timeline_diff_changed_downlink_shortfall_context(row)

    feedback
    |> update_in(["downlink_demand_mb"], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(station_id, shortfall_mb, &(&1 + shortfall_mb))
    end)
    |> update_in(["downlink_demand_sources"], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(station_id, [source], fn existing ->
        (List.wrap(existing) ++ [source])
        |> Enum.uniq()
        |> Enum.sort()
      end)
    end)
    |> update_in(["downlink_demand_context"], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(station_id, context, &merge_downlink_demand_context(&1, context))
    end)
  end

  defp timeline_diff_status(row), do: RowValues.normalized_token(row["diff_status"])

  defp timeline_diff_changed_fields(row) do
    row
    |> Map.get("changed_fields", [])
    |> List.wrap()
    |> Enum.map(&RowValues.encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp timeline_diff_removed_downlink_activity?(row) do
    timeline_diff_downlink_activity?(row, "source")
  end

  defp timeline_diff_downlink_activity?(row) do
    timeline_diff_downlink_activity?(row, "source") or
      timeline_diff_downlink_activity?(row, "replacement")
  end

  defp timeline_diff_downlink_activity?(row, side) do
    activity_type =
      row["#{side}_activity_type"] ||
        get_in(row, ["#{side}_activity_context", "activity_type"]) ||
        get_in(row, ["#{side}_activity_context", "type"])

    direction = row["#{side}_direction"] || get_in(row, ["#{side}_activity_context", "direction"])

    activity_type = RowValues.normalized_token(activity_type)

    activity_type in ["downlink", "planned_contact", "contact"] or
      normalize_direction(direction) == "downlink"
  end

  defp timeline_diff_removed_downlink_station_id(row) do
    RowValues.stable_id_or_nil(
      row["source_ground_station_id"] ||
        get_in(row, ["source_activity_context", "ground_station_id"]) ||
        get_in(row, ["source_activity_context", "timeline_identity", "subject_id"])
    )
  end

  defp timeline_diff_removed_downlink_required_mb(row) do
    RowValues.numeric_value(
      row["source_required_downlink_mb"] ||
        get_in(row, ["source_activity_context", "required_downlink_mb"])
    )
  end

  defp timeline_diff_changed_downlink_station_id(row) do
    RowValues.stable_id_or_nil(
      row["replacement_ground_station_id"] ||
        row["source_ground_station_id"] ||
        get_in(row, ["replacement_activity_context", "ground_station_id"]) ||
        get_in(row, ["source_activity_context", "ground_station_id"]) ||
        get_in(row, ["replacement_activity_context", "station_id"]) ||
        get_in(row, ["source_activity_context", "station_id"]) ||
        get_in(row, ["replacement_activity_context", "timeline_identity", "subject_id"]) ||
        get_in(row, ["source_activity_context", "timeline_identity", "subject_id"])
    )
  end

  defp timeline_diff_changed_downlink_shortfall_mb(row) do
    first_positive_number(row, [
      "selected_downlink_shortfall_mb",
      "downlink_shortfall_mb",
      "data_volume_shortfall_mb",
      "selected_data_volume_shortfall_mb",
      "missing_data_volume_mb",
      "required_data_volume_gap_mb",
      "replacement_selected_downlink_shortfall_mb",
      "source_selected_downlink_shortfall_mb",
      ["replacement_activity_context", "selected_downlink_shortfall_mb"],
      ["source_activity_context", "selected_downlink_shortfall_mb"],
      ["replacement_activity_context", "downlink_shortfall_mb"],
      ["source_activity_context", "downlink_shortfall_mb"],
      ["replacement_activity_context", "data_volume_shortfall_mb"],
      ["source_activity_context", "data_volume_shortfall_mb"],
      ["replacement_activity_context", "selected_data_volume_shortfall_mb"],
      ["source_activity_context", "selected_data_volume_shortfall_mb"],
      ["replacement_activity_context", "missing_data_volume_mb"],
      ["source_activity_context", "missing_data_volume_mb"],
      ["replacement_activity_context", "required_data_volume_gap_mb"],
      ["source_activity_context", "required_data_volume_gap_mb"],
      ["throughput_model", "selected_downlink_shortfall_mb"],
      ["throughput_model", "data_volume_shortfall_mb"],
      ["replacement_activity_context", "throughput_model", "selected_downlink_shortfall_mb"],
      ["source_activity_context", "throughput_model", "selected_downlink_shortfall_mb"]
    ]) ||
      timeline_diff_required_vs_planned_downlink_shortfall(row)
  end

  defp timeline_diff_required_vs_planned_downlink_shortfall(row) do
    required_mb =
      first_positive_number(row, [
        "required_downlink_mb",
        "source_required_downlink_mb",
        "replacement_required_downlink_mb",
        "required_data_volume_mb",
        "source_required_data_volume_mb",
        "replacement_required_data_volume_mb",
        "target_downlink_mb",
        "target_data_volume_mb",
        "min_downlink_mb",
        ["replacement_activity_context", "required_downlink_mb"],
        ["source_activity_context", "required_downlink_mb"],
        ["replacement_activity_context", "required_data_volume_mb"],
        ["source_activity_context", "required_data_volume_mb"],
        ["replacement_activity_context", "target_downlink_mb"],
        ["source_activity_context", "target_downlink_mb"],
        ["replacement_activity_context", "target_data_volume_mb"],
        ["source_activity_context", "target_data_volume_mb"],
        ["replacement_activity_context", "min_downlink_mb"],
        ["source_activity_context", "min_downlink_mb"]
      ])

    planned_mb =
      RowValues.first_number(row, [
        "planned_downlink_mb",
        "selected_downlink_mb",
        "candidate_downlink_mb",
        "estimated_downlink_mb",
        "planned_data_volume_mb",
        "selected_data_volume_mb",
        "replacement_planned_downlink_mb",
        "replacement_selected_downlink_mb",
        "replacement_candidate_downlink_mb",
        "replacement_estimated_downlink_mb",
        "source_planned_downlink_mb",
        "source_selected_downlink_mb",
        "source_candidate_downlink_mb",
        "source_estimated_downlink_mb",
        ["replacement_activity_context", "planned_downlink_mb"],
        ["replacement_activity_context", "selected_downlink_mb"],
        ["replacement_activity_context", "candidate_downlink_mb"],
        ["replacement_activity_context", "estimated_downlink_mb"],
        ["replacement_activity_context", "planned_data_volume_mb"],
        ["replacement_activity_context", "selected_data_volume_mb"],
        ["source_activity_context", "planned_downlink_mb"],
        ["source_activity_context", "selected_downlink_mb"],
        ["source_activity_context", "candidate_downlink_mb"],
        ["source_activity_context", "estimated_downlink_mb"],
        ["source_activity_context", "planned_data_volume_mb"],
        ["source_activity_context", "selected_data_volume_mb"],
        ["throughput_model", "estimated_downlink_mb"],
        ["throughput_model", "candidate_downlink_mb"],
        ["throughput_model", "selected_downlink_mb"],
        ["replacement_activity_context", "throughput_model", "estimated_downlink_mb"],
        ["replacement_activity_context", "throughput_model", "candidate_downlink_mb"],
        ["replacement_activity_context", "throughput_model", "selected_downlink_mb"],
        ["source_activity_context", "throughput_model", "estimated_downlink_mb"],
        ["source_activity_context", "throughput_model", "candidate_downlink_mb"],
        ["source_activity_context", "throughput_model", "selected_downlink_mb"]
      ])

    case {required_mb, planned_mb} do
      {required_mb, planned_mb} when is_number(required_mb) and is_number(planned_mb) ->
        max(required_mb - max(planned_mb, 0.0), 0.0)

      _values ->
        nil
    end
  end

  defp timeline_diff_removed_downlink_source(row) do
    activity_id =
      RowValues.stable_id_or_nil(row["source_activity_id"]) ||
        RowValues.stable_id_or_nil(get_in(row, ["source_activity_context", "id"])) ||
        RowValues.stable_id_or_nil(row["timeline_id"]) ||
        "removed_downlink"

    "timeline_diff.removed.required_downlink_mb:#{activity_id}"
  end

  defp timeline_diff_removed_downlink_context(row) do
    %{
      "source" => "timeline_diff_report.rows",
      "source_diff_status" => timeline_diff_status(row),
      "source_timeline_id" => row["timeline_id"],
      "source_activity_id" => row["source_activity_id"],
      "source_activity_type" => row["source_activity_type"],
      "source_required_operator_action" => row["required_operator_action"],
      "source_reason" => row["reason"]
    }
    |> RowValues.compact_nil_values()
  end

  defp timeline_diff_changed_downlink_shortfall_source(row) do
    source_activity_id =
      RowValues.stable_id_or_nil(row["source_activity_id"]) ||
        RowValues.stable_id_or_nil(get_in(row, ["source_activity_context", "id"])) ||
        RowValues.stable_id_or_nil(row["timeline_id"]) ||
        "source"

    replacement_activity_id =
      RowValues.stable_id_or_nil(row["replacement_activity_id"]) ||
        RowValues.stable_id_or_nil(get_in(row, ["replacement_activity_context", "id"])) ||
        "replacement"

    "timeline_diff.changed.downlink_shortfall_mb:#{source_activity_id}:#{replacement_activity_id}"
  end

  defp timeline_diff_changed_downlink_shortfall_context(row) do
    %{
      "source" => "timeline_diff_report.rows",
      "source_diff_status" => timeline_diff_status(row),
      "source_timeline_id" => row["timeline_id"],
      "source_activity_id" => row["source_activity_id"],
      "replacement_activity_id" => row["replacement_activity_id"],
      "source_activity_type" => row["source_activity_type"],
      "replacement_activity_type" => row["replacement_activity_type"],
      "source_required_operator_action" => row["required_operator_action"],
      "source_reason" => row["reason"],
      "source_changed_fields" => timeline_diff_changed_fields(row),
      "required_downlink_mb" => timeline_diff_changed_required_downlink_mb(row),
      "planned_downlink_mb" => timeline_diff_changed_planned_downlink_mb(row),
      "selected_downlink_shortfall_mb" => timeline_diff_changed_downlink_shortfall_mb(row),
      "source_starts_at_s" => RowValues.numeric_value(row["source_starts_at_s"]),
      "source_ends_at_s" => RowValues.numeric_value(row["source_ends_at_s"]),
      "replacement_starts_at_s" => RowValues.numeric_value(row["replacement_starts_at_s"]),
      "replacement_ends_at_s" => RowValues.numeric_value(row["replacement_ends_at_s"])
    }
    |> RowValues.compact_nil_values()
  end

  defp timeline_diff_changed_required_downlink_mb(row) do
    first_positive_number(row, [
      "required_downlink_mb",
      "source_required_downlink_mb",
      "replacement_required_downlink_mb",
      "required_data_volume_mb",
      "source_required_data_volume_mb",
      "replacement_required_data_volume_mb",
      ["replacement_activity_context", "required_downlink_mb"],
      ["source_activity_context", "required_downlink_mb"],
      ["replacement_activity_context", "required_data_volume_mb"],
      ["source_activity_context", "required_data_volume_mb"]
    ])
  end

  defp timeline_diff_changed_planned_downlink_mb(row) do
    RowValues.first_number(row, [
      "planned_downlink_mb",
      "selected_downlink_mb",
      "candidate_downlink_mb",
      "estimated_downlink_mb",
      "replacement_selected_downlink_mb",
      "replacement_candidate_downlink_mb",
      "replacement_estimated_downlink_mb",
      ["replacement_activity_context", "selected_downlink_mb"],
      ["replacement_activity_context", "candidate_downlink_mb"],
      ["replacement_activity_context", "estimated_downlink_mb"]
    ])
  end

  defp merge_downlink_demand_context(existing, context) when is_map(existing) do
    sources =
      [existing["source"], context["source"]]
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()
      |> Enum.sort()

    existing
    |> Map.merge(context)
    |> maybe_put_nonempty("sources", sources)
  end

  defp merge_downlink_demand_context(_existing, context), do: context

  defp first_positive_number(row, paths) do
    Enum.find_value(paths, fn
      path when is_list(path) ->
        case row |> get_in(path) |> RowValues.numeric_value() do
          value when is_number(value) and value > 0.0 -> value
          _value -> nil
        end

      path ->
        case row |> Map.get(path) |> RowValues.numeric_value() do
          value when is_number(value) and value > 0.0 -> value
          _value -> nil
        end
    end)
  end

  defp normalize_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_direction(direction) do
    direction
    |> RowValues.encode_value()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      token when is_map_key(@provider_direction_aliases, token) ->
        Map.fetch!(@provider_direction_aliases, token)

      "nil" ->
        nil

      "" ->
        nil

      value ->
        value
    end
  end

  defp positive_number_value?(value), do: is_number(value) and value > 0.0

  defp maybe_put_nonempty(map, _key, []), do: map
  defp maybe_put_nonempty(map, key, values), do: Map.put(map, key, values)
end
