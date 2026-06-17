defmodule OrbitalDynamics.CampaignPlanner.ResourceFilterPressureBranches do
  @moduledoc false

  def from_reports(reports, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    Enum.flat_map(reports, fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> Map.get("suppressed_candidates", [])
      |> Enum.map(&stringify_keys.(&1))
      |> Enum.flat_map(fn row ->
        row
        |> Map.put("_source_report_trust_boundary", trust_boundary)
        |> Map.put("_source_report_policy", Map.get(report, "policy") || %{})
        |> build(source_path, callbacks)
      end)
    end)
  end

  def build(row, source_path, callbacks) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    event = pressure_event(row, source_path, callbacks)
    candidate_id = candidate_id(row)

    if is_nil(event) or not stable_id_string?.(candidate_id) do
      []
    else
      reason =
        row
        |> Map.get("suppressed_reason", "suppressed")
        |> branch_id_fragment.()

      [
        %{
          "id" =>
            "derived_resource_filter_pressure_#{reason}_#{branch_id_fragment.(candidate_id)}",
          "label" => "Derived resource filter pressure #{candidate_id}",
          "events" => [event],
          "metadata" =>
            %{
              "derived_source" => source_path,
              "suppressed_reason" => row["suppressed_reason"],
              "resource_source_quality" => row["resource_source_quality"],
              "resource_trust_boundary_status" => row["resource_trust_boundary_status"]
            }
            |> compact_map.()
        }
      ]
    end
  end

  def disambiguate(branches, callbacks) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      branch_id = branch["id"]

      if branch_id?(branch_id) and Map.get(id_counts, branch_id, 0) > 1 do
        suffix =
          branch
          |> branch_identity(index, callbacks)
          |> branch_id_fragment.()

        branch
        |> Map.put("id", "#{branch_id}_#{suffix}")
        |> Map.update("metadata", %{}, fn metadata ->
          metadata
          |> Map.put("resource_filter_branch_base_id", branch_id)
          |> Map.put("resource_filter_branch_identity", suffix)
        end)
      else
        branch
      end
    end)
    |> disambiguate_duplicate_suffixes()
  end

  defp branch_id?(id) when is_binary(id),
    do: String.starts_with?(id, "derived_resource_filter_pressure_")

  defp branch_id?(_id), do: false

  defp disambiguate_duplicate_suffixes(branches) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      metadata = Map.get(branch, "metadata", %{})

      if Map.has_key?(metadata, "resource_filter_branch_base_id") and
           Map.get(id_counts, branch["id"], 0) > 1 do
        suffix = "#{metadata["resource_filter_branch_identity"]}_#{index}"

        branch
        |> Map.put("id", "#{metadata["resource_filter_branch_base_id"]}_#{suffix}")
        |> Map.update("metadata", %{}, &Map.put(&1, "resource_filter_branch_identity", suffix))
      else
        branch
      end
    end)
  end

  defp branch_identity(branch, index, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    branch
    |> Map.get("events", [])
    |> List.wrap()
    |> Enum.flat_map(fn event ->
      [
        event["feedback_source"],
        event["source_activity_id"],
        event["source_activity_ids"],
        event["resource_field"],
        event["starts_at_s"],
        event["ends_at_s"],
        event["trust_boundary"]
      ]
    end)
    |> List.flatten()
    |> Enum.map(fn value -> encode_value.(value) end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> case do
      [] -> index
      identifiers -> Enum.join(identifiers, "_")
    end
  end

  defp pressure_event(row, source_path, callbacks) do
    case pressure(row) do
      {:availability, field} -> availability_event(row, source_path, field, callbacks)
      {:margin, field} -> margin_event(row, source_path, field, callbacks)
      nil -> nil
    end
  end

  defp pressure(%{"suppressed_reason" => "spacecraft_unavailable"}),
    do: {:availability, "spacecraft_available"}

  defp pressure(%{"suppressed_reason" => "fuel_margin_below_policy"}),
    do: {:margin, "fuel_margin"}

  defp pressure(%{"suppressed_reason" => "payload_unavailable"}),
    do: {:availability, "payload_available"}

  defp pressure(%{"suppressed_reason" => "spacecraft_degraded_payload_unavailable"}),
    do: {:availability, "payload_available"}

  defp pressure(%{"suppressed_reason" => "power_margin_below_observe_policy"}),
    do: {:margin, "power_margin"}

  defp pressure(%{"suppressed_reason" => "storage_margin_below_observe_policy"}),
    do: {:margin, "storage_margin"}

  defp pressure(%{"suppressed_reason" => "antenna_unavailable"}),
    do: {:availability, "antenna_available"}

  defp pressure(%{"suppressed_reason" => "power_margin_below_downlink_policy"}),
    do: {:margin, "power_margin"}

  defp pressure(%{"suppressed_reason" => "downlink_margin_below_policy"}),
    do: {:margin, "downlink_margin"}

  defp pressure(%{"suppressed_reason" => "thermal_margin_below_policy"}),
    do: {:margin, "thermal_margin_c"}

  defp pressure(_row), do: nil

  defp availability_event(row, source_path, field, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    %{
      "type" => "resource_availability_constraint",
      "scenario_id" => row["scenario_id"] || row["spacecraft_id"],
      "spacecraft_id" => row["spacecraft_id"] || row["scenario_id"],
      "resource_field" => field,
      "available" => false,
      "starts_at_s" => numeric_or_nil.(row["starts_at_s"] || row["start_s"]),
      "ends_at_s" => numeric_or_nil.(row["ends_at_s"] || row["end_s"]),
      "source_activity_id" => candidate_id(row),
      "source_activity_ids" => List.wrap(candidate_id(row)),
      "suppressed_reason" => row["suppressed_reason"],
      "approval_status" => row["approval_status"],
      "policy_classification" => row["policy_classification"],
      "resource_filter_status" => row["resource_filter_status"],
      "suppression_status" => row["suppression_status"],
      "required_operator_action" => row["required_operator_action"],
      "source_quality" => row["resource_source_quality"],
      "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
      "derivation_reasons" => pressure_reasons(row),
      "feedback_source" => source_path,
      "feedback_scope" => "resource_filter",
      "trust_boundary" => trust_boundary(row)
    }
    |> compact_map.()
  end

  defp margin_event(row, source_path, field, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    operator_training_context = Keyword.fetch!(callbacks, :operator_training_context)
    value = margin_value(row, field, callbacks)

    if is_nil(value) do
      nil
    else
      %{
        "type" => "resource_margin_pressure",
        "scenario_id" => row["scenario_id"] || row["spacecraft_id"],
        "spacecraft_id" => row["spacecraft_id"] || row["scenario_id"],
        "resource_field" => field,
        field => value,
        "#{field}_threshold" => margin_threshold(row, field, callbacks),
        "starts_at_s" => numeric_or_nil.(row["starts_at_s"] || row["start_s"]),
        "ends_at_s" => numeric_or_nil.(row["ends_at_s"] || row["end_s"]),
        "source_activity_id" => candidate_id(row),
        "source_activity_ids" => List.wrap(candidate_id(row)),
        "suppressed_reason" => row["suppressed_reason"],
        "source_quality" => row["resource_source_quality"],
        "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
        "derivation_reasons" => pressure_reasons(row),
        "feedback_source" => source_path,
        "feedback_scope" => "resource_filter",
        "trust_boundary" => trust_boundary(row)
      }
      |> Map.merge(operator_training_context.(row))
      |> compact_map.()
    end
  end

  defp candidate_id(row) do
    row["activity_id"] || row["contact_id"] || row["id"]
  end

  defp margin_value(row, field, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    [
      row[field],
      get_in(row, ["source_resource_summary", field]),
      get_in(row, ["resource_summary", field])
    ]
    |> Enum.map(fn value -> numeric_or_nil.(value) end)
    |> Enum.find(&is_number/1)
  end

  defp margin_threshold(row, "fuel_margin", callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    numeric_or_nil.(
      row["min_activity_fuel_margin"] ||
        get_in(row, ["_source_report_policy", "min_activity_fuel_margin"]) ||
        row["fuel_margin_threshold"]
    )
  end

  defp margin_threshold(row, "power_margin", callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    numeric_or_nil.(
      row["min_observe_power_margin"] || row["min_downlink_power_margin"] ||
        get_in(row, ["_source_report_policy", "min_observe_power_margin"]) ||
        get_in(row, ["_source_report_policy", "min_downlink_power_margin"]) ||
        row["power_margin_threshold"]
    )
  end

  defp margin_threshold(row, "storage_margin", callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    numeric_or_nil.(
      row["min_observe_storage_margin"] ||
        get_in(row, ["_source_report_policy", "min_observe_storage_margin"]) ||
        row["storage_margin_threshold"]
    )
  end

  defp margin_threshold(row, "downlink_margin", callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    numeric_or_nil.(
      row["min_downlink_margin"] ||
        get_in(row, ["_source_report_policy", "min_downlink_margin"]) ||
        row["downlink_margin_threshold"]
    )
  end

  defp margin_threshold(row, "thermal_margin_c", callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    numeric_or_nil.(
      row["min_activity_thermal_margin_c"] ||
        get_in(row, ["_source_report_policy", "min_activity_thermal_margin_c"]) ||
        row["thermal_margin_c_threshold"]
    )
  end

  defp pressure_reasons(row) do
    [
      "resource_filter_suppressed",
      row["suppressed_reason"]
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      Map.get(row, "resource_trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["resource_provenance", "trust_boundary"]) ||
      get_in(row, ["source_resource_summary", "resource_trust_boundary"]) ||
      get_in(row, ["source_resource_summary", "provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end
end
