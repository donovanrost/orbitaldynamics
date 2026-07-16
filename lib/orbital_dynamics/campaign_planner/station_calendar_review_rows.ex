defmodule OrbitalDynamics.CampaignPlanner.StationCalendarReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{StationCalendarPressureBranches, ValueEncoding}

  @fields [
    "activity_id",
    "contact_id",
    "subject_id",
    "id",
    "scenario_id",
    "ground_station_id",
    "station_id",
    "station_availability",
    "availability",
    "station_calendar_status",
    "status",
    "starts_at_s",
    "ends_at_s",
    "overlap_starts_at_s",
    "overlap_ends_at_s",
    "capacity_fraction",
    "station_calendar_entry_id",
    "station_calendar_provider_id",
    "station_calendar_provider_entry_id",
    "station_calendar_directions",
    "station_calendar_overlap_count",
    "station_calendar_overlap_entry_ids",
    "station_calendar_overlap_availabilities",
    "station_calendar_entry_ambiguous",
    "station_calendar_ambiguous_entry_count",
    "station_calendar_ambiguous_entry_ids",
    "station_calendar_reservation_overlap_count",
    "station_calendar_reservation_ids",
    "station_calendar_reserved_by",
    "station_calendar_reservation_statuses",
    "station_calendar_trust_boundary_status",
    "station_contention_status",
    "station_reservation_match_status",
    "station_reservation_id",
    "station_reserved_by",
    "station_reservation_status",
    "trust_boundary",
    "provenance",
    "source_station_calendar_entry",
    "source_station_calendar_overlaps"
  ]

  def source(row), do: source(row, [])

  def source(%{"source_station_calendar_review" => %{} = source} = row, callbacks)
      when map_size(source) > 0,
      do: {row(source, row, callbacks), "source_station_calendar_review"}

  def source(row, callbacks), do: {row(row, row, callbacks), "station_calendar_review"}

  def pressure_branches(
        %{"source_station_calendar_provider_contention" => %{} = provider_contention} = row,
        trust_boundary,
        source_prefix,
        callbacks
      ) do
    stringify_keys = stringify_keys_callback(callbacks)
    provider_contention_pressure_branch = Keyword.fetch!(callbacks, :provider_contention_branch)

    provider_contention
    |> stringify_keys.()
    |> Map.put_new("approval_status", row["approval_status"])
    |> Map.put("_source_report_trust_boundary", trust_boundary)
    |> provider_contention_pressure_branch.(
      "#{source_prefix}.source_station_calendar_provider_contention"
    )
  end

  def pressure_branches(row, trust_boundary, source_prefix, callbacks) do
    stringify_keys = stringify_keys_callback(callbacks)
    pressure_branch = Keyword.fetch!(callbacks, :pressure_branch)
    {source, source_suffix} = source(row, callbacks)

    source
    |> stringify_keys.()
    |> Map.put_new("approval_status", row["approval_status"])
    |> Map.put("_source_report_trust_boundary", trust_boundary)
    |> pressure_branch.("#{source_prefix}.#{source_suffix}")
  end

  def pressure_branches(row, trust_boundary, source_prefix),
    do: pressure_branches(row, trust_boundary, source_prefix, default_callbacks())

  def row(source, row), do: row(source, row, [])

  def row(source, row, callbacks) do
    stringify_keys = stringify_keys_callback(callbacks)
    put_default_if_present = put_default_if_present_callback(callbacks)

    Enum.reduce(@fields, stringify_keys.(source), fn field, acc ->
      put_default_if_present.(acc, field, row[field])
    end)
  end

  def review_row?(row), do: review_row?(row, default_callbacks())

  def review_row?(row, callbacks) do
    pressure_event = Keyword.fetch!(callbacks, :pressure_event)

    (row["source_review_type"] == "station_calendar_review" or
       row["review_type"] == "station_calendar_review" or
       row["import_action"] == "review_station_calendar") and
      pressure_event.(row, "candidate") != nil
  end

  defp stringify_keys_callback(callbacks) do
    Keyword.get(callbacks, :stringify_keys, &ValueEncoding.stringify_keys/1)
  end

  defp put_default_if_present_callback(callbacks) do
    Keyword.get(callbacks, :put_default_if_present, &put_default_if_present/3)
  end

  defp put_default_if_present(map, _field, value) when value in [nil, "", [], %{}], do: map

  defp put_default_if_present(map, field, value) do
    case Map.get(map, field) do
      existing when existing in [nil, ""] -> Map.put(map, field, value)
      _existing -> map
    end
  end

  defp default_callbacks,
    do: [
      pressure_branch: &StationCalendarPressureBranches.branch/2,
      provider_contention_branch: &StationCalendarPressureBranches.provider_contention_branch/2,
      pressure_event: &StationCalendarPressureBranches.event/2
    ]
end
