defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.ManeuverReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues

  def maneuver_review_report_feedback(%{} = report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&RowValues.stringify_keys/1)
    |> Enum.reduce(%{}, fn row, feedback ->
      if maneuver_review_feedback_row?(row) do
        merge_maneuver_review_feedback(row, feedback)
      else
        feedback
      end
    end)
    |> RowValues.compact_nonempty()
  end

  def maneuver_review_report_feedback(_report), do: %{}

  def maneuver_review_feedback_row?(%{} = row) do
    maneuver_review_feedback_key(row) not in [nil, ""] and
      (maneuver_review_success_feedback_row?(row) or
         maneuver_review_execution_uncertainty_feedback_row?(row))
  end

  def maneuver_review_success_feedback_row?(%{} = row) do
    maneuver_review_feedback_key(row) not in [nil, ""] and
      is_number(maneuver_review_success_factor(row))
  end

  def maneuver_review_execution_uncertainty_feedback_row?(%{} = row) do
    maneuver_review_feedback_key(row) not in [nil, ""] and
      maneuver_review_execution_uncertainty(row) != %{}
  end

  def maneuver_review_feedback_key(row) do
    RowValues.stable_id_or_nil(
      row["maneuver_id"] ||
        get_in(row, ["source_recommendation", "id"]) ||
        row["activity_id"] ||
        row["id"] ||
        row["timeline_id"]
    )
  end

  def maneuver_review_success_factor(row) do
    case RowValues.first_number(row, [
           "maneuver_success_factor",
           ["source_recommendation", "maneuver_success_factor"],
           ["source_maneuver_review", "maneuver_success_factor"]
         ]) do
      factor when is_number(factor) -> RowValues.unit_interval(factor)
      _factor -> maneuver_review_result_factor(row)
    end
  end

  def merge_maneuver_review_feedback(row, feedback) do
    maneuver_key = maneuver_review_feedback_key(row)

    feedback =
      case maneuver_review_success_factor(row) do
        factor when is_number(factor) ->
          update_in(feedback, ["maneuver_success_rate"], fn values ->
            values
            |> RowValues.ensure_map()
            |> Map.update(maneuver_key, factor, &min(&1, factor))
          end)

        _factor ->
          feedback
      end

    case maneuver_review_execution_uncertainty(row) do
      uncertainty when uncertainty == %{} ->
        feedback

      uncertainty ->
        update_in(feedback, ["maneuver_execution_uncertainty"], fn values ->
          values
          |> RowValues.ensure_map()
          |> Map.put(maneuver_key, uncertainty)
        end)
    end
  end

  def maneuver_review_execution_uncertainty_status(%{} = row) do
    status =
      row["execution_uncertainty_status"] ||
        get_in(row, ["source_maneuver_review", "execution_uncertainty_status"])

    case status |> RowValues.encode_value() do
      value when value in ["declared", "missing"] ->
        value

      _value ->
        if is_map(row["execution_uncertainty"]) or
             is_map(get_in(row, ["source_recommendation", "execution_uncertainty"])) or
             is_map(get_in(row, ["source_maneuver_review", "execution_uncertainty"])) do
          "declared"
        end
    end
  end

  defp maneuver_review_result_factor(row) do
    cond do
      false in [
        row["maneuver_success"],
        get_in(row, ["source_recommendation", "maneuver_success"]),
        get_in(row, ["source_maneuver_review", "maneuver_success"])
      ] ->
        0.0

      RowValues.failure_token?(
        row["maneuver_result"] ||
          get_in(row, ["source_recommendation", "maneuver_result"]) ||
            get_in(row, ["source_maneuver_review", "maneuver_result"])
      ) ->
        0.0

      true ->
        nil
    end
  end

  defp maneuver_review_execution_uncertainty(%{} = row) do
    uncertainty =
      case row["execution_uncertainty"] ||
             get_in(row, ["source_recommendation", "execution_uncertainty"]) ||
             get_in(row, ["source_maneuver_review", "execution_uncertainty"]) do
        %{} = value -> RowValues.stringify_keys(value)
        _value -> nil
      end

    %{
      "execution_uncertainty_status" => maneuver_review_execution_uncertainty_status(row),
      "execution_uncertainty" => uncertainty,
      "timing_3sigma_s" =>
        RowValues.numeric_value(
          row["timing_3sigma_s"] ||
            get_in(row, ["source_maneuver_review", "timing_3sigma_s"]) ||
            get_in(uncertainty || %{}, ["timing_3sigma_s"])
        ),
      "delta_v_3sigma_km_s" =>
        RowValues.numeric_triplet_or_nil(
          row["delta_v_3sigma_km_s"] ||
            get_in(row, ["source_maneuver_review", "delta_v_3sigma_km_s"]) ||
            get_in(uncertainty || %{}, ["delta_v_3sigma_km_s"])
        ),
      "delta_v_3sigma_magnitude_km_s" =>
        RowValues.numeric_value(
          row["delta_v_3sigma_magnitude_km_s"] ||
            get_in(row, ["source_maneuver_review", "delta_v_3sigma_magnitude_km_s"]) ||
            get_in(uncertainty || %{}, ["delta_v_3sigma_magnitude_km_s"])
        ),
      "execution_uncertainty_source" =>
        row["execution_uncertainty_source"] ||
          get_in(row, ["source_maneuver_review", "execution_uncertainty_source"]) ||
          get_in(uncertainty || %{}, ["source"])
    }
    |> RowValues.compact_nil_values()
  end
end
