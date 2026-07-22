defmodule OrbitalDynamics.Schema.CandidateRefreshCommunicationPressureContracts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.CountMaps.ResourceScopes
  alias OrbitalDynamics.Schema.StableIdValidation

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_optional_non_negative_integer: 4,
      validate_non_negative_integer_count_map: 3
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_nested_stable_id_array_map: 3,
      validate_stable_id_list: 3
    ]

  def validate_contact_contention(issues, path, summary) do
    issues
    |> validate_contact_contention_invalid_inputs(path, summary)
    |> validate_contact_contention_required_actions(path, summary)
    |> validate_contact_contention_resource_scopes(path, summary)
    |> validate_contact_contention_ground_stations(path, summary)
    |> validate_count_maps(path, summary, [
      "contact_contention_ground_station_counts",
      "contact_contention_contact_id_counts"
    ])
  end

  def validate_contact_allocation(issues, path, summary) do
    Enum.reduce(
      [
        "provider_reservation_no_request_contact_ids_by_direction_and_ground_station",
        "provider_reservation_request_contact_ids_by_direction_and_ground_station",
        "provider_reservation_review_contact_ids_by_direction_and_ground_station"
      ],
      issues,
      fn field, acc ->
        validate_nested_stable_id_array_map(acc, path <> ".#{field}", Map.get(summary, field))
      end
    )
  end

  def validate_station_pressure(issues, path, summary) do
    issues
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "station_pressure_contact_count"
    )
    |> validate_count_maps(path, summary, [
      "station_pressure_ground_station_counts",
      "station_pressure_availability_counts",
      "station_pressure_precedence_availability_counts",
      "station_pressure_precedence_rank_counts"
    ])
  end

  def validate_contact_filter(issues, path, summary) do
    issues
    |> validate_stable_id_list(
      path <> ".invalid_contact_input_ids",
      Map.get(summary, "invalid_contact_input_ids")
    )
    |> expect_optional_non_negative_integer(path, summary, "station_suppression_count")
    |> validate_count_maps(path, summary, [
      "station_suppression_ground_station_counts",
      "station_suppression_availability_counts",
      "station_suppression_status_counts"
    ])
  end

  defp validate_count_maps(issues, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_non_negative_integer_count_map(acc, path <> ".#{field}", Map.get(summary, field))
    end)
  end

  defp validate_invalid_contact_input_identity_count(issues, path, summary) do
    ids = Map.get(summary, "invalid_contact_input_ids")
    count = Map.get(summary, "invalid_contact_input_count")

    normalized_id_count = if is_list(ids), do: ids |> Enum.uniq() |> length()

    if is_list(ids) and (not is_integer(count) or count != normalized_id_count) do
      [
        error(
          path <> ".invalid_contact_input_ids",
          "must have length equal to invalid_contact_input_count"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_contact_contention_invalid_inputs(
         issues,
         path,
         %{
           "contract" => "contact_contention_report.v1"
         } = summary
       ) do
    issues
    |> expect_optional_non_negative_integer(path, summary, "invalid_contact_input_count")
    |> validate_stable_id_list(
      path <> ".invalid_contact_input_ids",
      Map.get(summary, "invalid_contact_input_ids")
    )
    |> validate_invalid_contact_input_identity_count(path, summary)
  end

  defp validate_contact_contention_invalid_inputs(issues, _path, _summary), do: issues

  defp validate_contact_contention_required_actions(
         issues,
         path,
         %{
           "contract" => "contact_contention_report.v1"
         } = summary
       ) do
    counts = Map.get(summary, "required_operator_action_counts")

    issues =
      validate_non_negative_integer_count_map(
        issues,
        path <> ".required_operator_action_counts",
        counts
      )

    if is_map(counts) do
      expected_counts = %{
        "review_contact_contention" => Map.get(summary, "conflict_group_count"),
        "review_invalid_contact_contention_input" =>
          Map.get(summary, "invalid_contact_input_count")
      }

      Enum.reduce(counts, issues, fn {action, count}, acc ->
        expected_count = Map.get(expected_counts, action)

        if is_integer(count) and count > 0 and is_integer(expected_count) and
             expected_count > 0 and count <= expected_count do
          acc
        else
          [
            error(
              path <> ".required_operator_action_counts.#{action}",
              "must be a canonical contention action whose count does not exceed its scalar evidence"
            )
            | acc
          ]
        end
      end)
    else
      issues
    end
  end

  defp validate_contact_contention_required_actions(issues, _path, _summary), do: issues

  defp validate_contact_contention_resource_scopes(
         issues,
         path,
         %{
           "contract" => "contact_contention_report.v1"
         } = summary
       ) do
    counts = Map.get(summary, "resource_scope_counts")

    issues =
      validate_non_negative_integer_count_map(issues, path <> ".resource_scope_counts", counts)

    if is_map(counts) do
      issues =
        Enum.reduce(counts, issues, fn {scope, count}, acc ->
          if scope in ResourceScopes.canonical_scopes() and is_integer(count) and count > 0 do
            acc
          else
            [
              error(
                path <> ".resource_scope_counts.#{scope}",
                "must be a canonical contention resource scope with a positive count"
              )
              | acc
            ]
          end
        end)

      conflict_group_count = Map.get(summary, "conflict_group_count")

      scope_count =
        counts
        |> Map.values()
        |> Enum.filter(&(is_integer(&1) and &1 > 0))
        |> Enum.sum()

      if is_integer(conflict_group_count) and scope_count <= conflict_group_count do
        issues
      else
        [
          error(
            path <> ".resource_scope_counts",
            "canonical scope counts must not exceed conflict_group_count"
          )
          | issues
        ]
      end
    else
      issues
    end
  end

  defp validate_contact_contention_resource_scopes(issues, _path, _summary), do: issues

  defp validate_contact_contention_ground_stations(
         issues,
         path,
         %{
           "contract" => "contact_contention_report.v1"
         } = summary
       ) do
    counts = Map.get(summary, "contact_contention_ground_station_counts")

    if is_map(counts) do
      issues =
        Enum.reduce(counts, issues, fn {ground_station_id, count}, acc ->
          if StableIdValidation.valid?(ground_station_id) and is_integer(count) and count > 0 do
            acc
          else
            [
              error(
                path <> ".contact_contention_ground_station_counts.#{ground_station_id}",
                "must use a stable ground-station ID with a positive count"
              )
              | acc
            ]
          end
        end)

      if map_size(counts) == 0 do
        issues
      else
        ground_station_scope_count =
          summary
          |> Map.get("resource_scope_counts", %{})
          |> Map.get("ground_station")

        station_count =
          counts
          |> Map.values()
          |> Enum.filter(&(is_integer(&1) and &1 > 0))
          |> Enum.sum()

        if is_integer(ground_station_scope_count) and ground_station_scope_count > 0 and
             station_count <= ground_station_scope_count do
          issues
        else
          [
            error(
              path <> ".contact_contention_ground_station_counts",
              "station counts must not exceed positive ground_station resource-scope evidence"
            )
            | issues
          ]
        end
      end
    else
      issues
    end
  end

  defp validate_contact_contention_ground_stations(issues, _path, _summary), do: issues
end
