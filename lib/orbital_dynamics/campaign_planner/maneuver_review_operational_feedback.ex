defmodule OrbitalDynamics.CampaignPlanner.ManeuverReviewOperationalFeedback do
  @moduledoc false

  def from_rows(rows, opts) when is_list(opts) do
    feedback_row? = Keyword.fetch!(opts, :feedback_row?)
    row_success_value = Keyword.fetch!(opts, :row_success_value)
    activity_feedback_average = Keyword.fetch!(opts, :activity_feedback_average)
    execution_uncertainty_feedback = Keyword.fetch!(opts, :execution_uncertainty_feedback)

    rates =
      rows
      |> Enum.filter(feedback_row?)
      |> activity_feedback_average.(row_success_value)

    uncertainties = execution_uncertainty_feedback.(rows)

    %{}
    |> put_feedback_map("maneuver_success_rate", rates)
    |> put_feedback_map("maneuver_execution_uncertainty", uncertainties)
  end

  def prior_plan_source_rows(report_rows, result_artifact_rows, opts) when is_list(opts) do
    (report_rows ++ result_artifact_rows)
    |> source_rows(opts)
  end

  def mission_state_source_rows(reports_with_sources, opts) when is_list(opts) do
    reports_with_sources
    |> Enum.flat_map(fn {report, _source_path} -> Map.get(report, "rows", []) end)
    |> source_rows(opts)
  end

  def source(%{"source_maneuver_review" => %{} = source} = row, opts)
      when map_size(source) > 0 and is_list(opts) do
    {row(source, row, opts), "source_maneuver_review"}
  end

  def source(row, opts) when is_list(opts), do: {row(row, row, opts), "maneuver_review"}

  def operator_review_rows(rows, opts) when is_list(opts) do
    normalize_row = Keyword.fetch!(opts, :normalize_row)

    rows
    |> Enum.filter(&(&1["review_type"] == "maneuver_review"))
    |> Enum.map(fn row ->
      row(Map.get(row, "source_maneuver_review", row), row, opts)
    end)
    |> Enum.map(normalize_row)
  end

  def row(source, row, opts) when is_list(opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    put_default_if_present = Keyword.fetch!(opts, :put_default_if_present)
    put_feedback_weight_fields = Keyword.fetch!(opts, :put_feedback_weight_fields)
    normalize_row = Keyword.fetch!(opts, :normalize_row)

    source
    |> stringify_keys.()
    |> put_default_if_present.("activity_id", row["activity_id"] || row["maneuver_id"])
    |> put_default_if_present.("maneuver_id", row["maneuver_id"])
    |> put_default_if_present.("id", row["activity_id"] || row["maneuver_id"])
    |> put_default_if_present.("type", row["maneuver_type"])
    |> put_default_if_present.("scenario_id", row["scenario_id"])
    |> put_default_if_present.("maneuver_success_factor", row["maneuver_success_factor"])
    |> put_default_if_present.("maneuver_success", row["maneuver_success"])
    |> put_default_if_present.("maneuver_result", row["maneuver_result"])
    |> put_default_if_present.("execution_uncertainty", row["execution_uncertainty"])
    |> put_default_if_present.(
      "execution_uncertainty_status",
      row["execution_uncertainty_status"]
    )
    |> put_default_if_present.("timing_3sigma_s", row["timing_3sigma_s"])
    |> put_default_if_present.("delta_v_3sigma_km_s", row["delta_v_3sigma_km_s"])
    |> put_default_if_present.(
      "delta_v_3sigma_magnitude_km_s",
      row["delta_v_3sigma_magnitude_km_s"]
    )
    |> put_default_if_present.(
      "execution_uncertainty_source",
      row["execution_uncertainty_source"]
    )
    |> put_default_if_present.("required_operator_action", row["required_operator_action"])
    |> put_default_if_present.("cadence_import_status", row["cadence_import_status"])
    |> put_feedback_weight_fields.(row)
    |> normalize_row.()
  end

  def pressure_branch(row, source_path, index, opts) when is_list(opts) do
    case pressure_events(row, source_path, opts) do
      [] ->
        []

      events ->
        [
          %{
            "id" => pressure_branch_id(row, index, opts),
            "label" => "Derived maneuver-review feedback #{pressure_identity(row, index, opts)}",
            "events" => events,
            "metadata" => %{"derived_source" => source_path}
          }
        ]
    end
  end

  def pressure_events(row, source_path, opts) when is_list(opts) do
    [
      pressure_event(row, source_path, opts),
      uncertainty_pressure_event(row, source_path, opts)
    ]
    |> Enum.reject(&is_nil/1)
  end

  def pressure_event(row, source_path, opts) when is_list(opts) do
    row_success_value = Keyword.fetch!(opts, :row_success_value)
    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)
    activity_raw_start = Keyword.fetch!(opts, :activity_raw_start)
    activity_raw_end = Keyword.fetch!(opts, :activity_raw_end)
    clamp_unit_interval = Keyword.fetch!(opts, :clamp_unit_interval)
    provider_result_artifact_value = Keyword.fetch!(opts, :provider_result_artifact_value)
    explicit_timeline_id = Keyword.fetch!(opts, :explicit_timeline_id)
    operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)
    put_feedback_weight_fields = Keyword.fetch!(opts, :put_feedback_weight_fields)
    compact_map = Keyword.fetch!(opts, :compact_map)

    with value when is_number(value) <- row_success_value.(row),
         true <- value < 1.0,
         activity_id when activity_id not in [nil, ""] <- realized_feedback_activity_id.(row) do
      %{
        "type" => "maneuver_success_feedback",
        "activity_id" => activity_id,
        "scenario_id" => row["scenario_id"],
        "starts_at_s" => activity_raw_start.(row) || 0.0,
        "ends_at_s" => activity_raw_end.(row),
        "maneuver_success_factor" => clamp_unit_interval.(value),
        "maneuver_result" => provider_result_artifact_value.(row["maneuver_result"]),
        "required_operator_action" => row["required_operator_action"],
        "cadence_import_status" => row["cadence_import_status"],
        "timeline_id" => explicit_timeline_id.(row),
        "maneuver_id" => row["maneuver_id"],
        "derivation_reasons" => ["maneuver_review_feedback"],
        "feedback_source" => source_path,
        "feedback_scope" => "maneuver_review",
        "feedback_key" => activity_id,
        "trust_boundary" => operator_review_trust_boundary.(row)
      }
      |> put_feedback_weight_fields.(row)
      |> compact_map.()
    else
      _missing -> nil
    end
  end

  defp uncertainty_pressure_event(row, source_path, opts) when is_list(opts) do
    execution_uncertainty_entry = Keyword.fetch!(opts, :execution_uncertainty_entry)
    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)
    activity_raw_start = Keyword.fetch!(opts, :activity_raw_start)
    activity_raw_end = Keyword.fetch!(opts, :activity_raw_end)
    explicit_timeline_id = Keyword.fetch!(opts, :explicit_timeline_id)
    operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)
    compact_map = Keyword.fetch!(opts, :compact_map)

    entry = execution_uncertainty_entry.(row)
    activity_id = realized_feedback_activity_id.(row)

    if entry == %{} or activity_id in [nil, ""] do
      nil
    else
      %{
        "type" => "maneuver_execution_uncertainty_feedback",
        "activity_id" => activity_id,
        "scenario_id" => row["scenario_id"],
        "starts_at_s" => activity_raw_start.(row) || 0.0,
        "ends_at_s" => activity_raw_end.(row),
        "execution_uncertainty_status" => entry["execution_uncertainty_status"],
        "execution_uncertainty" => entry["execution_uncertainty"],
        "timing_3sigma_s" => entry["timing_3sigma_s"],
        "delta_v_3sigma_km_s" => entry["delta_v_3sigma_km_s"],
        "delta_v_3sigma_magnitude_km_s" => entry["delta_v_3sigma_magnitude_km_s"],
        "execution_uncertainty_source" => entry["execution_uncertainty_source"],
        "required_operator_action" => row["required_operator_action"],
        "cadence_import_status" => row["cadence_import_status"],
        "timeline_id" => explicit_timeline_id.(row),
        "maneuver_id" => row["maneuver_id"],
        "derivation_reasons" => ["maneuver_review_uncertainty"],
        "feedback_source" => source_path,
        "feedback_scope" => "maneuver_review",
        "feedback_key" => activity_id,
        "trust_boundary" => operator_review_trust_boundary.(row)
      }
      |> compact_map.()
    end
  end

  defp source_rows(rows, opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    normalize_row = Keyword.fetch!(opts, :normalize_row)

    rows
    |> Enum.map(stringify_keys)
    |> Enum.map(normalize_row)
  end

  defp put_feedback_map(feedback, _field, values) when values in [%{}, nil], do: feedback

  defp put_feedback_map(feedback, field, %{} = values), do: Map.put(feedback, field, values)

  defp pressure_branch_id(row, index, opts),
    do: "derived_maneuver_review_feedback_#{pressure_identity(row, index, opts)}"

  defp pressure_identity(row, index, opts) do
    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)
    explicit_timeline_id = Keyword.fetch!(opts, :explicit_timeline_id)
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      realized_feedback_activity_id.(row),
      row["maneuver_id"],
      explicit_timeline_id.(row),
      row["id"],
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end
end
