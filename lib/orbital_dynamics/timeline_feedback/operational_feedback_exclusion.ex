defmodule OrbitalDynamics.TimelineFeedback.OperationalFeedbackExclusion do
  @moduledoc false

  def apply(row) do
    case operational_feedback_exclusion_reason(row) do
      nil ->
        row

      reason ->
        status =
          case reason do
            "contact_link_quality_review_required" -> "review_only_link_quality"
            "feedback_weight_invalid_review_required" -> "review_only_invalid_feedback_weight"
            "resource_availability_variance_review_required" -> "review_only_resource_variance"
            _reason -> "review_only_identity_mismatch"
          end

        row
        |> Map.put("operational_feedback_excluded", true)
        |> Map.put("operational_feedback_status", status)
        |> Map.put("operational_feedback_exclusion_reason", reason)
    end
  end

  defp operational_feedback_exclusion_reason(%{} = row) do
    cond do
      invalid_feedback_weight_section?(row) ->
        "feedback_weight_invalid_review_required"

      resource_availability_variance?(row) ->
        "resource_availability_variance_review_required"

      true ->
        operational_feedback_exclusion_reason_for_kind(row)
    end
  end

  defp resource_availability_variance?(row) do
    [
      "spacecraft_available_match_status",
      "payload_available_match_status",
      "antenna_available_match_status",
      "degraded_match_status",
      "mode_match_status"
    ]
    |> Enum.any?(&(row[&1] == "mismatch"))
  end

  defp operational_feedback_exclusion_reason_for_kind(%{"feedback_kind" => kind} = row)
       when kind in ["contact", "command", "health_check"] do
    operational_feedback_contact_exclusion_reason(row)
  end

  defp operational_feedback_exclusion_reason_for_kind(%{"feedback_kind" => "observation"} = row) do
    if row["target_match_status"] == "mismatch" or
         row["pointing_target_match_status"] == "mismatch" do
      "target_identity_mismatch_review_required"
    end
  end

  defp operational_feedback_exclusion_reason_for_kind(_row), do: nil

  defp invalid_feedback_weight_section?(row) do
    row
    |> Map.get("invalid_realized_feedback_sections")
    |> list_value()
    |> Enum.any?(
      &(&1["field"] in [
          "feedback_weight",
          "feedback_sample_weight",
          "sample_weight",
          "confidence_weight"
        ])
    )
  end

  defp list_value(value) when is_list(value), do: value
  defp list_value(_value), do: []

  defp operational_feedback_contact_exclusion_reason(row) do
    if Enum.any?(
         [
           row["direction_match_status"],
           row["ground_station_match_status"],
           row["source_window_match_status"],
           row["link_protocol_match_status"],
           row["frequency_band_match_status"],
           row["modulation_match_status"],
           row["coding_scheme_match_status"],
           row["polarization_match_status"]
         ],
         &(&1 == "mismatch")
       ) do
      "contact_identity_mismatch_review_required"
    else
      if contact_link_quality_review_required?(row) do
        "contact_link_quality_review_required"
      end
    end
  end

  defp contact_link_quality_review_required?(row) do
    row["realized_carrier_lock"] == false or
      row["realized_symbol_lock"] == false or
      negative_number?(row["realized_link_margin_db"]) or
      link_quality_failure_status?(row["realized_link_quality_status"])
  end

  defp link_quality_failure_status?(status) when is_binary(status) do
    status
    |> normalize_status()
    |> then(
      &(&1 in [
          "below_threshold",
          "degraded",
          "failed",
          "link_failed",
          "lock_lost",
          "low_margin",
          "no_lock",
          "poor",
          "unusable"
        ])
    )
  end

  defp link_quality_failure_status?(_status), do: false

  defp negative_number?(value), do: is_number(value) and value < 0.0

  defp normalize_status(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp normalize_status(status) when is_atom(status),
    do: status |> Atom.to_string() |> normalize_status()

  defp normalize_status(_status), do: nil
end
