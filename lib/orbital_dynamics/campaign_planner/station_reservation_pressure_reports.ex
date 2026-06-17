defmodule OrbitalDynamics.CampaignPlanner.StationReservationPressureReports do
  @moduledoc false

  def hold_summary(%{} = summary, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    summary = stringify_keys.(summary)
    {affected_rows, provider_rows} = station_reservation_summary_pressure_rows(summary, callbacks)

    %{
      "schema_contract" => "station_reservation_report.v1",
      "model" => "preserved_station_reservation_hold_summary",
      "source_row_collection" => "review_rows",
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "trust_boundary" =>
        Map.get(summary, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"]),
      "affected_contacts" =>
        Enum.map(
          affected_rows,
          &station_reservation_hold_summary_affected_pressure_row(&1, summary, callbacks)
        ),
      "provider_calendar_contention_groups" =>
        Enum.map(
          provider_rows,
          &station_reservation_hold_summary_provider_pressure_group(&1, summary, callbacks)
        )
    }
    |> compact_map.()
  end

  def hold_import_readiness_summary(%{} = summary, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    summary = stringify_keys.(summary)
    {affected_rows, provider_rows} = station_reservation_summary_pressure_rows(summary, callbacks)

    %{
      "schema_contract" => "station_reservation_report.v1",
      "model" => "preserved_station_reservation_hold_import_readiness_summary",
      "source_row_collection" => "import_readiness_rows",
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "trust_boundary" =>
        Map.get(summary, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"]),
      "affected_contacts" =>
        Enum.map(
          affected_rows,
          &station_reservation_hold_import_readiness_affected_pressure_row(
            &1,
            summary,
            callbacks
          )
        ),
      "provider_calendar_contention_groups" =>
        Enum.map(
          provider_rows,
          &station_reservation_hold_import_readiness_provider_pressure_group(
            &1,
            summary,
            callbacks
          )
        )
    }
    |> compact_map.()
  end

  def review_summary(%{} = summary, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    summary = stringify_keys.(summary)

    {affected_rows, provider_rows} =
      summary
      |> Map.get("review_rows", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(fn row -> stringify_keys.(row) end)
      |> Enum.split_with(fn row ->
        row["reservation_review_row_type"] != "provider_calendar_contention_group"
      end)

    %{
      "schema_contract" => "station_reservation_report.v1",
      "model" => "preserved_station_reservation_review_summary",
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "trust_boundary" =>
        Map.get(summary, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"]),
      "affected_contacts" =>
        Enum.map(
          affected_rows,
          &station_reservation_review_summary_affected_pressure_row(&1, summary, callbacks)
        ),
      "provider_calendar_contention_groups" =>
        Enum.map(
          provider_rows,
          &station_reservation_review_summary_provider_pressure_group(&1, summary, callbacks)
        )
    }
    |> compact_map.()
  end

  defp station_reservation_summary_pressure_rows(summary, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    summary
    |> Map.get("review_rows", Map.get(summary, "import_readiness_rows", []))
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(fn row -> stringify_keys.(row) end)
    |> Enum.split_with(fn row ->
      row["reservation_review_row_type"] != "provider_calendar_contention_group"
    end)
  end

  defp station_reservation_review_summary_affected_pressure_row(row, summary, callbacks) do
    reservation_id = first_string([row["station_reservation_id"], row["reservation_ids"]])
    reserved_by = first_string([row["station_reserved_by"], row["reserved_by"]])

    reservation_status =
      first_string([row["station_reservation_status"], row["reservation_statuses"]])

    row
    |> Map.put_new("station_contention_status", "reserved_overlap")
    |> Map.put_new("station_availability", "reserved")
    |> Map.put_new("station_calendar_status", "reserved")
    |> put_if_absent("station_calendar_directions", row["direction"] || row["directions"])
    |> put_if_absent("station_reservation_id", reservation_id)
    |> put_if_absent("station_reserved_by", reserved_by)
    |> put_if_absent("station_reservation_status", reservation_status)
    |> put_if_absent("station_reservation_match_status", row["station_reservation_match_status"])
    |> put_if_absent(
      "station_reservation_expires_at_s",
      first_numeric(
        [row["station_reservation_expires_at_s"], row["reservation_expires_at_s"]],
        callbacks
      )
    )
    |> put_if_absent(
      "station_reservation_expiration_status",
      row["station_reservation_expiration_status"]
    )
    |> put_if_absent("source_station_reservation_review", row)
    |> put_if_absent(
      "trust_boundary",
      Map.get(row, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"])
    )
  end

  defp station_reservation_review_summary_provider_pressure_group(row, summary, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    reservation_id = first_string([row["station_reservation_id"], row["reservation_ids"]])
    reserved_by = first_string([row["station_reserved_by"], row["reserved_by"]])

    reservation_status =
      first_string([row["station_reservation_status"], row["reservation_statuses"]])

    group_id = row["provider_calendar_contention_group_id"] || row["id"] || reservation_id

    source_entry =
      %{
        "id" => reservation_id || group_id,
        "ground_station_id" => row["ground_station_id"] || row["station_id"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "availability" => "reserved",
        "status" => "reserved",
        "directions" => row["directions"] || row["direction"],
        "reservation_id" => reservation_id,
        "reserved_by" => reserved_by,
        "reservation_status" => reservation_status,
        "trust_boundary" =>
          Map.get(row, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"])
      }
      |> compact_map.()

    %{
      "id" => group_id,
      "ground_station_id" => row["ground_station_id"] || row["station_id"],
      "provider_calendar_contention_status" =>
        row["provider_calendar_contention_status"] || "contention",
      "directions" => row["directions"] || row["direction"],
      "reservation_ids" => List.wrap(row["reservation_ids"] || reservation_id),
      "reserved_by" => List.wrap(row["reserved_by"] || reserved_by),
      "reservation_statuses" => List.wrap(row["reservation_statuses"] || reservation_status),
      "trust_boundary" =>
        Map.get(row, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"]),
      "source_station_calendar_entries" => [source_entry],
      "source_station_reservation_review" => row
    }
    |> compact_map.()
  end

  defp station_reservation_hold_summary_affected_pressure_row(row, summary, callbacks) do
    row
    |> station_reservation_hold_common_pressure_row(summary, callbacks)
    |> put_if_absent(
      "required_operator_action",
      station_reservation_hold_required_operator_action(row, summary)
    )
    |> put_if_absent("station_reservation_hold_summary_model", summary["model"])
    |> put_if_absent("station_reservation_hold_summary_source", summary["source"])
    |> put_if_absent(
      "station_reservation_hold_summary_source_artifact_type",
      summary["source_artifact_type"]
    )
    |> put_if_absent(
      "station_reservation_hold_review_status",
      station_reservation_hold_pressure_row_review_status(row, summary)
    )
    |> put_if_absent("source_station_reservation_hold_summary", row)
    |> Map.merge(station_reservation_hold_summary_context(row, summary, callbacks))
  end

  defp station_reservation_hold_summary_provider_pressure_group(row, summary, callbacks) do
    row
    |> station_reservation_hold_summary_affected_pressure_row(summary, callbacks)
    |> station_reservation_hold_provider_pressure_group(row, summary, callbacks)
  end

  defp station_reservation_hold_import_readiness_affected_pressure_row(
         row,
         summary,
         callbacks
       ) do
    row
    |> station_reservation_hold_common_pressure_row(summary, callbacks)
    |> put_if_absent("required_operator_action", row["required_operator_action"])
    |> put_if_absent(
      "station_reservation_hold_import_status",
      row["station_reservation_hold_import_status"]
    )
    |> put_if_absent("station_reservation_hold_import_readiness_summary_model", summary["model"])
    |> put_if_absent(
      "station_reservation_hold_import_readiness_source",
      summary["source"]
    )
    |> put_if_absent(
      "station_reservation_hold_import_readiness_source_artifact_type",
      summary["source_artifact_type"]
    )
    |> put_if_absent(
      "station_reservation_hold_import_readiness_status",
      summary["import_readiness_status"]
    )
    |> put_if_absent(
      "station_reservation_hold_import_classification",
      summary["import_classification"]
    )
    |> put_if_absent("source_station_reservation_hold_import_readiness_summary", row)
    |> Map.merge(station_reservation_hold_import_readiness_context(summary, callbacks))
  end

  defp station_reservation_hold_import_readiness_provider_pressure_group(
         row,
         summary,
         callbacks
       ) do
    row
    |> station_reservation_hold_import_readiness_affected_pressure_row(summary, callbacks)
    |> station_reservation_hold_provider_pressure_group(row, summary, callbacks)
  end

  defp station_reservation_hold_common_pressure_row(row, summary, callbacks) do
    reservation_id = first_string([row["station_reservation_id"], row["reservation_ids"]])
    reserved_by = first_string([row["station_reserved_by"], row["reserved_by"]])

    reservation_status =
      first_string([row["station_reservation_status"], row["reservation_statuses"]])

    row
    |> Map.put_new("station_contention_status", "reserved_overlap")
    |> Map.put_new("station_availability", "reserved")
    |> Map.put_new("station_calendar_status", "reserved")
    |> put_if_absent("station_calendar_directions", row["direction"] || row["directions"])
    |> put_if_absent("station_reservation_id", reservation_id)
    |> put_if_absent("station_reserved_by", reserved_by)
    |> put_if_absent("station_reservation_status", reservation_status)
    |> put_if_absent(
      "station_reservation_match_status",
      row["station_reservation_match_status"] || row["station_reservation_expiration_status"]
    )
    |> put_if_absent(
      "station_reservation_expires_at_s",
      first_numeric(
        [row["station_reservation_expires_at_s"], row["reservation_expires_at_s"]],
        callbacks
      )
    )
    |> put_if_absent(
      "station_reservation_expiration_status",
      row["station_reservation_expiration_status"]
    )
    |> put_if_absent(
      "trust_boundary",
      Map.get(row, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"])
    )
  end

  defp station_reservation_hold_provider_pressure_group(row, source_row, summary, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    reservation_id = first_string([row["station_reservation_id"], row["reservation_ids"]])
    reserved_by = first_string([row["station_reserved_by"], row["reserved_by"]])

    reservation_status =
      first_string([row["station_reservation_status"], row["reservation_statuses"]])

    group_id = row["provider_calendar_contention_group_id"] || row["id"] || reservation_id

    source_entry =
      %{
        "id" => reservation_id || group_id,
        "ground_station_id" => row["ground_station_id"] || row["station_id"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "availability" => "reserved",
        "status" => "reserved",
        "directions" => row["directions"] || row["direction"],
        "reservation_id" => reservation_id,
        "reserved_by" => reserved_by,
        "reservation_status" => reservation_status,
        "trust_boundary" =>
          Map.get(row, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"])
      }
      |> compact_map.()

    row
    |> Map.merge(%{
      "id" => group_id,
      "ground_station_id" => row["ground_station_id"] || row["station_id"],
      "provider_calendar_contention_status" =>
        row["provider_calendar_contention_status"] || "contention",
      "directions" => row["directions"] || row["direction"],
      "reservation_ids" => List.wrap(row["reservation_ids"] || reservation_id),
      "reserved_by" => List.wrap(row["reserved_by"] || reserved_by),
      "reservation_statuses" => List.wrap(row["reservation_statuses"] || reservation_status),
      "trust_boundary" =>
        Map.get(row, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"]),
      "source_station_calendar_entries" => [source_entry],
      "source_station_reservation_hold" => source_row
    })
    |> compact_map.()
  end

  defp station_reservation_hold_required_operator_action(row, summary) do
    row["required_operator_action"] ||
      if(station_reservation_hold_pressure_row_review_status(row, summary) == "review_required",
        do: "review_station_reservation_hold"
      )
  end

  defp station_reservation_hold_pressure_row_review_status(row, summary) do
    row["station_reservation_hold_review_status"] ||
      row["reservation_hold_review_status"] ||
      if(station_reservation_hold_pressure_row_reservation_ids(row) != [],
        do: "review_required",
        else: summary["reservation_hold_review_status"]
      )
  end

  defp station_reservation_hold_summary_context(row, summary, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    reservation_ids = station_reservation_hold_pressure_row_reservation_ids(row)
    directions = station_reservation_hold_pressure_row_strings(row, ["direction", "directions"])

    contact_ids =
      station_reservation_hold_pressure_row_strings(row, ["contact_id", "contact_ids"])

    expiration_statuses =
      station_reservation_hold_pressure_row_strings(row, [
        "station_reservation_expiration_status"
      ])

    %{
      "station_reservation_hold_count" =>
        if(reservation_ids == [], do: nil, else: length(reservation_ids)),
      "station_reservation_hold_ids" => if(reservation_ids == [], do: nil, else: reservation_ids),
      "station_reservation_hold_ids_by_direction" =>
        station_reservation_hold_pressure_row_values_by(reservation_ids, directions),
      "station_reservation_hold_contact_ids_by_expiration_status" =>
        station_reservation_hold_pressure_row_values_by(contact_ids, expiration_statuses),
      "station_reservation_hold_contact_ids_by_direction" =>
        station_reservation_hold_pressure_row_values_by(contact_ids, directions),
      "station_reservation_hold_provider_write" =>
        get_in(summary, ["assumptions", "provider_write"]),
      "station_reservation_hold_reservation_acceptance" =>
        get_in(summary, ["assumptions", "reservation_acceptance"])
    }
    |> compact_map.()
  end

  defp station_reservation_hold_pressure_row_reservation_ids(row) do
    station_reservation_hold_pressure_row_strings(row, [
      "station_reservation_id",
      "reservation_ids"
    ])
  end

  defp station_reservation_hold_pressure_row_strings(row, keys) do
    keys
    |> Enum.flat_map(fn key -> List.wrap(row[key]) end)
    |> List.flatten()
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
  end

  defp station_reservation_hold_pressure_row_values_by([], _keys), do: nil
  defp station_reservation_hold_pressure_row_values_by(_values, []), do: nil

  defp station_reservation_hold_pressure_row_values_by(values, keys) do
    Map.new(keys, &{&1, values})
  end

  defp station_reservation_hold_import_readiness_context(summary, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    %{
      "station_reservation_hold_count" => summary["reservation_hold_count"],
      "station_reservation_hold_ids" => summary["reservation_hold_ids"],
      "station_reservation_hold_ids_by_import_status" =>
        summary["reservation_hold_ids_by_import_status"],
      "station_reservation_hold_ids_by_required_import_action" =>
        summary["reservation_hold_ids_by_required_import_action"],
      "station_reservation_hold_ids_by_direction" => summary["reservation_hold_ids_by_direction"],
      "station_reservation_hold_ids_by_direction_and_ground_station_id" =>
        summary["reservation_hold_ids_by_direction_and_ground_station_id"],
      "station_reservation_hold_contact_ids_by_import_status" =>
        summary["reservation_hold_contact_ids_by_import_status"],
      "station_reservation_hold_contact_ids_by_expiration_status" =>
        summary["reservation_hold_contact_ids_by_expiration_status"],
      "station_reservation_hold_contact_ids_by_direction" =>
        summary["reservation_hold_contact_ids_by_direction"],
      "station_reservation_hold_contact_ids_by_direction_and_ground_station_id" =>
        summary["reservation_hold_contact_ids_by_direction_and_ground_station_id"],
      "station_reservation_hold_import_status_counts" =>
        summary["reservation_hold_import_status_counts"],
      "station_reservation_hold_required_import_action_counts" =>
        summary["required_import_action_counts"],
      "station_reservation_hold_import_execution_boundary" =>
        get_in(summary, ["assumptions", "execution_boundary"]),
      "station_reservation_hold_provider_write" =>
        get_in(summary, ["assumptions", "provider_write"]),
      "station_reservation_hold_cadence_write" =>
        get_in(summary, ["assumptions", "cadence_write"]),
      "station_reservation_hold_reservation_acceptance" =>
        get_in(summary, ["assumptions", "reservation_acceptance"])
    }
    |> compact_map.()
  end

  defp first_string(values) do
    values
    |> List.wrap()
    |> List.flatten()
    |> Enum.find(&(is_binary(&1) and &1 != ""))
  end

  defp first_numeric(values, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    values
    |> List.wrap()
    |> List.flatten()
    |> Enum.map(fn value -> numeric_or_nil.(value) end)
    |> Enum.find(&is_number/1)
  end

  defp put_if_absent(map, _key, value) when value in [nil, "", [], %{}], do: map

  defp put_if_absent(map, key, value) do
    case Map.get(map, key) do
      existing when existing in [nil, "", [], %{}] -> Map.put(map, key, value)
      _existing -> map
    end
  end
end
