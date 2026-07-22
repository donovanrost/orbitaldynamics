defmodule OrbitalDynamics.OperatorReview.ContactAllocationSummary do
  @moduledoc false

  def put_from_paths(package, artifact, paths) do
    artifact = stringify_keys(artifact || %{})
    reports = Enum.map(paths, &get_in(artifact, &1))

    put(package, reports)
  end

  def put_candidate_refresh(package, artifact) do
    artifact = stringify_keys(artifact || %{})

    reports =
      [
        artifact["source_contact_allocation_report"],
        artifact["contact_allocation_report"],
        artifact["source_contact_allocation_summary"],
        artifact["contact_allocation_summary"],
        artifact["source_contact_allocation_station_pressure_summary"],
        artifact["contact_allocation_station_pressure_summary"],
        artifact["source_contact_allocation_reservation_conflict_summary"],
        artifact["contact_allocation_reservation_conflict_summary"],
        artifact["source_contact_allocation_capacity_pack_summary"],
        artifact["contact_allocation_capacity_pack_summary"],
        artifact["source_contact_allocation_provider_reservation_request_summary"],
        artifact["contact_allocation_provider_reservation_request_summary"]
      ] ++
        result_artifact_contact_allocation_summary_reports(artifact["source_result_artifact"]) ++
        result_artifact_contact_allocation_summary_reports(artifact["result_artifact"])

    put(package, reports)
  end

  defp result_artifact_contact_allocation_summary_reports(artifacts) when is_list(artifacts) do
    Enum.flat_map(artifacts, &result_artifact_contact_allocation_summary_reports/1)
  end

  defp result_artifact_contact_allocation_summary_reports(%{} = artifact) do
    artifact = stringify_keys(artifact)

    direct_reports =
      if result_artifact_contact_allocation_summary?(artifact), do: [artifact], else: []

    nested_reports =
      [
        artifact["source_contact_allocation_report"],
        artifact["contact_allocation_report"],
        artifact["source_contact_allocation_summary"],
        artifact["contact_allocation_summary"],
        artifact["source_contact_allocation_station_pressure_summary"],
        artifact["contact_allocation_station_pressure_summary"],
        artifact["source_contact_allocation_reservation_conflict_summary"],
        artifact["contact_allocation_reservation_conflict_summary"],
        artifact["source_contact_allocation_capacity_pack_summary"],
        artifact["contact_allocation_capacity_pack_summary"],
        artifact["source_contact_allocation_provider_reservation_request_summary"],
        artifact["contact_allocation_provider_reservation_request_summary"]
      ]

    direct_reports ++ nested_reports
  end

  defp result_artifact_contact_allocation_summary_reports(_artifact), do: []

  defp result_artifact_contact_allocation_summary?(%{"schema_contract" => schema_contract})
       when schema_contract in [
              "contact_allocation_report.v1",
              "contact_allocation_summary.v1",
              "contact_allocation_station_pressure_summary.v1",
              "contact_allocation_reservation_conflict_summary.v1",
              "contact_allocation_capacity_pack_summary.v1",
              "contact_allocation_provider_reservation_request_summary.v1"
            ],
       do: true

  defp result_artifact_contact_allocation_summary?(_artifact), do: false

  def put_strategy(package, artifact) do
    artifact = stringify_keys(artifact || %{})

    reports =
      artifact
      |> Map.get("branches", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.flat_map(fn branch ->
        [
          get_in(branch, ["repair_result", "source_contact_allocation_report"]),
          get_in(branch, ["repair_result", "contact_allocation_report"]),
          get_in(branch, [
            "repair_result",
            "source_contact_allocation_provider_reservation_request_summary"
          ]),
          get_in(branch, [
            "repair_result",
            "contact_allocation_provider_reservation_request_summary"
          ])
        ]
      end)

    put(package, reports)
  end

  def put(package, reports) do
    reports =
      reports
      |> Enum.flat_map(&contact_allocation_summary_reports/1)

    package
    |> put_contact_allocation_count_summary(
      reports,
      "calendar_entry_trust_boundary_status_counts"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "station_reservation_match_status_counts"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "station_reservation_expiration_status_counts"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "resource_blocking_dimension_counts"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "station_pressure_contact_counts_by_ground_station_id"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "station_pressure_contact_counts_by_availability"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "station_pressure_contact_counts_by_precedence_availability"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "station_pressure_contact_counts_by_precedence_rank"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "station_pressure_contact_counts_by_status"
    )
    |> put_station_pressure_identity_summary(reports)
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "station_pressure_review_contact_count"
    )
    |> put_contact_allocation_number_summary(
      reports,
      "capacity_pack_required_capacity_fraction"
    )
    |> put_contact_allocation_number_summary(
      reports,
      "capacity_pack_selected_required_capacity_fraction"
    )
    |> put_contact_allocation_number_summary(
      reports,
      "capacity_pack_deferred_required_capacity_fraction"
    )
    |> put_contact_allocation_number_map_summary(
      reports,
      "capacity_pack_required_capacity_fraction_by_status"
    )
    |> put_contact_allocation_number_map_summary(
      reports,
      "capacity_pack_required_capacity_fraction_by_ground_station_id"
    )
    |> put_contact_allocation_number_map_summary(
      reports,
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id"
    )
    |> put_contact_allocation_number_map_summary(
      reports,
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "required_capacity_fraction_source_counts"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "provider_reservation_candidate_contact_count"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "provider_reservation_request_contact_count"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "provider_reservation_review_contact_count"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "provider_reservation_no_request_contact_count"
    )
    |> put_contact_allocation_status_count_summary(
      reports,
      "provider_reservation_request_status",
      "provider_reservation_request_status_counts"
    )
    |> put_contact_allocation_count_summary(
      reports,
      "reduced_capacity_pack_status_counts"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "reduced_capacity_pack_group_count"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "station_reservation_declared_expiration_contact_count"
    )
    |> put_contact_allocation_scalar_count_summary(
      reports,
      "station_reservation_missing_expiration_contact_count"
    )
    |> put_contact_allocation_min_number_summary(
      reports,
      "earliest_station_reservation_expires_at_s"
    )
    |> put_contact_allocation_list_summary(reports, "station_reservation_ids")
    |> put_contact_allocation_list_summary(reports, "station_reservation_expires_at_s")
    |> put_contact_allocation_list_summary(reports, "station_reserved_bys")
    |> put_contact_allocation_list_summary(reports, "station_reservation_statuses")
    |> put_contact_allocation_list_summary(reports, "capacity_pack_group_ids")
    |> put_contact_allocation_list_summary(reports, "reduced_capacity_packed_contact_ids")
    |> put_contact_allocation_list_summary(reports, "reduced_capacity_deferred_contact_ids")
    |> put_contact_allocation_list_summary(reports, "station_pressure_review_contact_ids")
    |> put_contact_allocation_list_summary(reports, "provider_reservation_request_contact_ids")
    |> put_contact_allocation_list_summary(reports, "provider_reservation_review_contact_ids")
    |> put_contact_allocation_list_summary(reports, "provider_reservation_no_request_contact_ids")
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_contact_ids_by_match_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_contact_ids_by_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_contact_ids_by_reserved_by"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_ids_by_match_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_ids_by_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_ids_by_reserved_by"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_pressure_contact_ids_by_direction"
    )
    |> put_contact_allocation_id_map_summary(reports, "capacity_pack_contact_ids_by_status")
    |> put_contact_allocation_id_map_summary(reports, "capacity_pack_contact_ids_by_direction")
    |> put_contact_allocation_id_map_summary(
      reports,
      "capacity_pack_selected_contact_ids_by_direction"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "capacity_pack_deferred_contact_ids_by_direction"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "capacity_pack_contact_ids_by_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "capacity_pack_selected_contact_ids_by_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "capacity_pack_deferred_contact_ids_by_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "required_capacity_fraction_contact_ids_by_source"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_request_contact_ids_by_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_review_contact_ids_by_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_no_request_contact_ids_by_direction"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_request_contact_ids_by_direction"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_review_contact_ids_by_direction"
    )
    |> put_contact_allocation_nested_id_map_summary(
      reports,
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
    )
    |> put_contact_allocation_nested_id_map_summary(
      reports,
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id"
    )
    |> put_contact_allocation_nested_id_map_summary(
      reports,
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_request_contact_ids_by_match_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_review_contact_ids_by_match_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_request_ids_by_match_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "provider_reservation_review_ids_by_match_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "reservation_conflict_contact_ids_by_direction"
    )
    |> put_contact_allocation_nested_id_map_summary(
      reports,
      "reservation_conflict_contact_ids_by_direction_and_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "capacity_pack_group_ids_by_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_contact_ids_by_expiration_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_reservation_ids_by_expiration_status"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "resource_blocked_contact_ids_by_blocking_dimension"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "resource_blocked_contact_ids_by_spacecraft_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_pressure_contact_ids_by_ground_station_id"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_pressure_contact_ids_by_availability"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_pressure_contact_ids_by_precedence_availability"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_pressure_contact_ids_by_precedence_rank"
    )
    |> put_contact_allocation_id_map_summary(
      reports,
      "station_pressure_contact_ids_by_status"
    )
    |> put_contact_allocation_nested_id_map_summary(
      reports,
      "station_pressure_contact_ids_by_direction_and_ground_station_id"
    )
  end

  defp contact_allocation_summary_reports(%{} = report), do: [stringify_keys(report)]

  defp contact_allocation_summary_reports(reports) when is_list(reports) do
    Enum.flat_map(reports, &contact_allocation_summary_reports/1)
  end

  defp contact_allocation_summary_reports(_report), do: []

  defp put_contact_allocation_count_summary(package, reports, field) do
    counts =
      reports
      |> contact_allocation_count_maps(field)
      |> merge_count_maps()

    put_merged_count_map(package, field, counts)
  end

  defp put_contact_allocation_scalar_count_summary(package, reports, field) do
    counts =
      reports
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_integer/1)

    case counts do
      [] -> package
      counts -> Map.put(package, field, Enum.sum(counts))
    end
  end

  defp put_contact_allocation_number_summary(package, reports, field) do
    values =
      reports
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_number/1)

    case values do
      [] -> package
      values -> Map.put(package, field, Enum.sum(values))
    end
  end

  defp put_contact_allocation_number_map_summary(package, reports, field) do
    values =
      reports
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_map/1)
      |> merge_number_maps()

    case values do
      values when values == %{} -> package
      values -> Map.put(package, field, values)
    end
  end

  defp put_contact_allocation_status_count_summary(package, reports, source_field, target_field) do
    counts =
      reports
      |> Enum.map(&Map.get(&1, source_field))
      |> Enum.filter(&(is_binary(&1) and &1 != ""))
      |> Enum.frequencies()

    put_merged_count_map(package, target_field, counts)
  end

  defp put_contact_allocation_min_number_summary(package, reports, field) do
    values =
      reports
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_number/1)

    case values do
      [] -> package
      values -> Map.put(package, field, Enum.min(values))
    end
  end

  defp put_contact_allocation_list_summary(package, reports, field) do
    values =
      reports
      |> Enum.flat_map(fn report ->
        case Map.get(report, field) do
          values when is_list(values) -> values
          _values -> []
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    case values do
      [] -> package
      values -> Map.put(package, field, values)
    end
  end

  defp put_station_pressure_identity_summary(package, reports) do
    identity_supplied? =
      Enum.any?(reports, &is_list(Map.get(&1, "station_pressure_contact_ids")))

    if identity_supplied? do
      contact_ids =
        reports
        |> Enum.flat_map(fn report ->
          case Map.get(report, "station_pressure_contact_ids") do
            values when is_list(values) -> values
            _values -> []
          end
        end)
        |> Enum.filter(&(is_binary(&1) and &1 != ""))
        |> Enum.uniq()
        |> Enum.sort()

      package
      |> Map.put("station_pressure_contact_count", length(contact_ids))
      |> Map.put("station_pressure_contact_ids", contact_ids)
    else
      put_contact_allocation_scalar_count_summary(
        package,
        reports,
        "station_pressure_contact_count"
      )
    end
  end

  defp put_contact_allocation_id_map_summary(package, reports, field) do
    values =
      reports
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_map/1)
      |> merge_string_list_maps()

    case values do
      values when values == %{} -> package
      values -> Map.put(package, field, values)
    end
  end

  defp put_contact_allocation_nested_id_map_summary(package, reports, field) do
    values =
      reports
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_map/1)
      |> merge_nested_string_list_maps()

    case values do
      values when values == %{} -> package
      values -> Map.put(package, field, values)
    end
  end

  defp contact_allocation_count_maps(reports, field) do
    reports
    |> Enum.map(fn
      %{} = report -> Map.get(report, field)
      _report -> nil
    end)
    |> Enum.filter(&is_map/1)
  end

  defp merge_count_maps(count_maps) do
    Enum.reduce(count_maps, %{}, fn count_map, acc ->
      Enum.reduce(count_map, acc, fn {key, value}, acc ->
        Map.update(acc, key, value, fn
          current when is_integer(current) and is_integer(value) -> current + value
          current -> current
        end)
      end)
    end)
  end

  defp merge_number_maps(maps) do
    Enum.reduce(maps, %{}, fn map, acc ->
      Enum.reduce(map, acc, fn {key, value}, acc ->
        if is_number(value), do: Map.update(acc, key, value, &(&1 + value)), else: acc
      end)
    end)
  end

  defp put_merged_count_map(package, _field, counts) when counts == %{}, do: package
  defp put_merged_count_map(package, field, counts), do: Map.put(package, field, counts)

  defp merge_string_list_maps(maps) do
    Enum.reduce(maps, %{}, fn map, acc ->
      Enum.reduce(map, acc, fn {key, values}, acc ->
        values = if is_list(values), do: values, else: []

        Map.update(acc, key, values, fn current ->
          (current ++ values)
          |> Enum.uniq()
          |> Enum.sort()
        end)
      end)
    end)
  end

  defp merge_nested_string_list_maps(maps) do
    Enum.reduce(maps, %{}, fn map, acc ->
      Enum.reduce(map, acc, fn {outer_key, inner_map}, acc ->
        inner_values = if is_map(inner_map), do: merge_string_list_maps([inner_map]), else: %{}

        Map.update(acc, outer_key, inner_values, fn current ->
          merge_string_list_maps([current, inner_values])
        end)
      end)
    end)
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
