defmodule OrbitalDynamics.CampaignPlanner.ContactFilterPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    DownlinkActivityNormalization,
    ScalarValues,
    ValueEncoding
  }

  def from_reports(reports, callbacks \\ default_callbacks()) do
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
        |> build(source_path, callbacks)
      end)
    end)
  end

  def build(row, source_path, callbacks \\ default_callbacks()) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    contact_id = Keyword.fetch!(callbacks, :contact_id)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    event = pressure_event(row, source_path, callbacks)
    contact_id = contact_id.(row)

    if is_nil(event) or not stable_id_string?.(contact_id) do
      []
    else
      reason =
        row
        |> Map.get("suppressed_reason", "suppressed")
        |> branch_id_fragment.()

      [
        %{
          "id" => "derived_contact_filter_pressure_#{reason}_#{branch_id_fragment.(contact_id)}",
          "label" => "Derived contact filter pressure #{contact_id}",
          "events" => [event],
          "metadata" =>
            %{
              "derived_source" => source_path,
              "suppressed_reason" => row["suppressed_reason"],
              "suppression_review_status" => row["review_status"],
              "station_reservation_match_status" => row["station_reservation_match_status"]
            }
            |> compact_map.()
        }
      ]
    end
  end

  def disambiguate(branches, callbacks \\ default_callbacks()) do
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
          |> Map.put("contact_filter_branch_base_id", branch_id)
          |> Map.put("contact_filter_branch_identity", suffix)
        end)
      else
        branch
      end
    end)
    |> disambiguate_duplicate_suffixes()
  end

  defp branch_id?(id) when is_binary(id),
    do: String.starts_with?(id, "derived_contact_filter_pressure_")

  defp branch_id?(_id), do: false

  defp disambiguate_duplicate_suffixes(branches) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      metadata = Map.get(branch, "metadata", %{})

      if Map.has_key?(metadata, "contact_filter_branch_base_id") and
           Map.get(id_counts, branch["id"], 0) > 1 do
        suffix = "#{metadata["contact_filter_branch_identity"]}_#{index}"

        branch
        |> Map.put("id", "#{metadata["contact_filter_branch_base_id"]}_#{suffix}")
        |> Map.update("metadata", %{}, &Map.put(&1, "contact_filter_branch_identity", suffix))
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
        event["source_window_id"],
        event["source_window_ids"],
        event["feedback_source"],
        event["source_activity_id"],
        event["source_activity_ids"],
        event["maneuver_id"],
        event["execution_uncertainty_status"],
        event["execution_uncertainty_source"],
        event["timing_3sigma_s"],
        event["delta_v_3sigma_magnitude_km_s"],
        event["ground_station_id"],
        event["required_downlink_mb"],
        event["starts_at_s"],
        event["ends_at_s"]
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
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)

    if downlink_activity?.(row) do
      contact_id = Keyword.fetch!(callbacks, :contact_id)
      compact_map = Keyword.fetch!(callbacks, :compact_map)
      numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
      contact_id = contact_id.(row)

      %{
        "type" => "downlink_completion_gap",
        "scenario_id" => row["scenario_id"] || row["spacecraft_id"],
        "spacecraft_id" => row["spacecraft_id"] || row["scenario_id"],
        "ground_station_id" => ground_station_id(row, callbacks),
        "required_contacts" => 1,
        "planned_contacts" => 0,
        "required_downlink_mb" => required_downlink_mb(row, callbacks),
        "planned_downlink_mb" => 0.0,
        "starts_at_s" => numeric_or_nil.(row["starts_at_s"] || row["start_s"]),
        "ends_at_s" => numeric_or_nil.(row["ends_at_s"] || row["end_s"]),
        "contact_id" => contact_id,
        "source_activity_id" => contact_id,
        "source_activity_ids" => List.wrap(contact_id),
        "source_window_id" => row["source_window_id"] || get_in(row, ["source_window", "id"]),
        "suppressed_reason" => row["suppressed_reason"],
        "review_status" => row["review_status"],
        "approval_status" => row["approval_status"],
        "policy_classification" => row["policy_classification"],
        "contact_filter_status" => row["contact_filter_status"],
        "suppression_status" => row["suppression_status"],
        "required_operator_action" => row["required_operator_action"],
        "station_reservation_id" => row["station_reservation_id"],
        "station_reserved_by" => row["station_reserved_by"],
        "station_reservation_status" => row["station_reservation_status"],
        "station_reservation_match_status" => row["station_reservation_match_status"],
        "station_calendar_entry_status" => row["station_calendar_entry_status"],
        "station_calendar_entry_id" => row["station_calendar_entry_id"],
        "downlink_demand_sources" => downlink_demand_sources(row, callbacks),
        "downlink_completion_sources" => downlink_completion_sources(row, callbacks),
        "derivation_reasons" => pressure_reasons(row),
        "feedback_source" => source_path,
        "feedback_scope" => "contact_filter",
        "trust_boundary" => trust_boundary(row)
      }
      |> compact_map.()
    end
  end

  defp ground_station_id(row, callbacks) do
    nested_ground_station_id = Keyword.fetch!(callbacks, :nested_ground_station_id)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    [
      row["ground_station_id"],
      row["station_id"],
      nested_ground_station_id.(row)
    ]
    |> Enum.find(&stable_id_string?.(&1))
  end

  defp required_downlink_mb(row, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    [
      row["required_downlink_mb"],
      row["estimated_throughput_mb"],
      row["planned_throughput_mb"],
      get_in(row, ["throughput_model", "required_downlink_mb"]),
      get_in(row, ["throughput_model", "estimated_throughput_mb"]),
      get_in(row, ["throughput_model", "planned_throughput_mb"])
    ]
    |> Enum.map(fn value -> numeric_or_nil.(value) end)
    |> Enum.find(fn value -> is_number(value) and value > 0.0 end)
  end

  defp downlink_demand_sources(row, callbacks) do
    normalize_downlink_source_list = Keyword.fetch!(callbacks, :normalize_downlink_source_list)

    [
      row["downlink_demand_source"],
      row["downlink_demand_sources"],
      get_in(row, ["throughput_model", "downlink_demand_source"]),
      get_in(row, ["throughput_model", "downlink_demand_sources"]),
      get_in(row, ["activity_context", "downlink_demand_source"]),
      get_in(row, ["activity_context", "downlink_demand_sources"])
    ]
    |> normalize_downlink_source_list.()
    |> case do
      [] -> downlink_completion_sources(row, callbacks)
      sources -> sources
    end
  end

  defp downlink_completion_sources(row, callbacks) do
    normalize_downlink_source_list = Keyword.fetch!(callbacks, :normalize_downlink_source_list)

    [
      row["downlink_completion_source"],
      row["downlink_completion_sources"],
      get_in(row, ["throughput_model", "downlink_completion_source"]),
      get_in(row, ["throughput_model", "downlink_completion_sources"]),
      get_in(row, ["activity_context", "downlink_completion_source"]),
      get_in(row, ["activity_context", "downlink_completion_sources"])
    ]
    |> normalize_downlink_source_list.()
    |> case do
      [] -> nil
      sources -> sources
    end
  end

  defp pressure_reasons(row) do
    [
      "contact_filter_suppressed",
      row["suppressed_reason"],
      row["station_reservation_match_status"],
      row["station_calendar_entry_status"]
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      Map.get(row, "resource_trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp default_callbacks do
    [
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      compact_map: &ValueEncoding.compact_map/1,
      contact_id: &contact_id/1,
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      encode_value: &ValueEncoding.encode_value/1,
      nested_ground_station_id: &DownlinkActivityNormalization.nested_ground_station_id/1,
      normalize_downlink_source_list: &normalize_downlink_source_values/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end

  defp contact_id(row) do
    row["contact_id"] || row["id"] || row["activity_id"]
  end

  defp normalize_downlink_source_values(values) do
    values
    |> List.flatten()
    |> Enum.map(&ValueEncoding.encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end
end
