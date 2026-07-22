defmodule OrbitalDynamics.Schema.CandidateRefreshCommunicationPressureContracts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.CountMaps.ResourceScopes

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.{
    ConflictGroupDirections.ContactPairs,
    Correlation,
    RouteMap
  }

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting,
    as: ContactAllocationDirectionRouting

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CountMapCorrelation,
    as: ContactAllocationCountMapCorrelation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.RowCountCorrelation,
    as: ContactAllocationRowCountCorrelation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.OutcomeIdentityCorrelation,
    as: ContactAllocationOutcomeIdentityCorrelation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.BlockedInputIdentityCorrelation,
    as: ContactAllocationBlockedInputIdentityCorrelation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ReasonIdentityCorrelation,
    as: ContactAllocationReasonIdentityCorrelation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ResourceBlockingCorrelation,
    as: ContactAllocationResourceBlockingCorrelation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ReviewIdentityCorrelation,
    as: ContactAllocationReviewIdentityCorrelation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.StationPressureReviewCorrelation,
    as: ContactAllocationStationPressureReviewCorrelation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.StationPressureRoutingCorrelation,
    as: ContactAllocationStationPressureRoutingCorrelation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ReservationConflictCorrelation,
    as: ContactAllocationReservationConflictCorrelation

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting.Correlation,
    as: ContactAllocationDirectionCorrelation

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
    |> validate_contact_contention_direction_counts(path, summary)
    |> validate_contact_contention_contact_ids(path, summary)
    |> validate_contact_contention_direction_routing(path, summary)
    |> validate_count_maps(path, summary, [
      "contact_contention_ground_station_counts",
      "contact_contention_contact_id_counts"
    ])
  end

  def validate_contact_allocation(issues, path, summary) do
    issues =
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

    issues
    |> validate_contact_allocation_row_counts(path, summary)
    |> validate_contact_allocation_count_maps(path, summary)
    |> validate_contact_allocation_resource_blocking(path, summary)
    |> validate_contact_allocation_contact_identities(path, summary)
    |> validate_contact_allocation_station_pressure_review(path, summary)
    |> validate_contact_allocation_station_pressure_routing(path, summary)
    |> validate_contact_allocation_reservation_conflict(path, summary)
    |> validate_contact_allocation_reason_identities(path, summary)
    |> validate_contact_allocation_direction_fields(path, summary)
    |> validate_contact_allocation_direction_routing(path, summary)
  end

  defp validate_contact_allocation_row_counts(
         issues,
         path,
         %{"contract" => "contact_allocation_report.v1"} = summary
       ) do
    canonical_counts =
      ContactAllocationRowCountCorrelation.correlated_counts(
        Map.get(summary, "row_count"),
        Map.get(summary, "blocked_row_count", 0),
        Map.get(summary, "deferred_row_count", 0)
      )

    Enum.reduce(ContactAllocationRowCountCorrelation.count_fields(), issues, fn field, acc ->
      if Map.has_key?(summary, field) and
           Map.get(summary, field) != Map.fetch!(canonical_counts, field) do
        [
          error(
            path <> ".#{field}",
            "must be a nonnegative blocked/deferred row count within row_count"
          )
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp validate_contact_allocation_row_counts(issues, _path, _summary), do: issues

  defp validate_contact_allocation_contact_identities(
         issues,
         path,
         %{"contract" => "contact_allocation_report.v1"} = summary
       ) do
    issues
    |> validate_contact_allocation_outcome_identities(path, summary)
    |> validate_contact_allocation_blocked_input_identities(path, summary)
    |> validate_contact_allocation_review_identity(path, summary)
  end

  defp validate_contact_allocation_contact_identities(issues, _path, _summary), do: issues

  defp validate_contact_allocation_outcome_identities(issues, path, summary) do
    canonical = ContactAllocationOutcomeIdentityCorrelation.fields(summary)

    Enum.reduce(
      ContactAllocationOutcomeIdentityCorrelation.field_specs(),
      issues,
      fn {count_field, ids_field, routes_field}, acc ->
        acc
        |> validate_canonical_supplied_field(path, summary, canonical, ids_field)
        |> validate_canonical_supplied_field(path, summary, canonical, routes_field)
        |> validate_canonical_supplied_field(path, summary, canonical, count_field)
      end
    )
  end

  defp validate_contact_allocation_blocked_input_identities(issues, path, summary) do
    canonical =
      summary
      |> ContactAllocationResourceBlockingCorrelation.fields()
      |> ContactAllocationBlockedInputIdentityCorrelation.fields()

    Enum.reduce(ContactAllocationBlockedInputIdentityCorrelation.field_pairs(), issues, fn
      {count_field, ids_field}, acc ->
        acc
        |> validate_canonical_supplied_field(path, summary, canonical, ids_field)
        |> validate_canonical_supplied_field(path, summary, canonical, count_field)
    end)
  end

  defp validate_contact_allocation_review_identity(issues, path, summary) do
    validate_canonical_supplied_field(
      issues,
      path,
      summary,
      ContactAllocationReviewIdentityCorrelation.fields(summary),
      ContactAllocationReviewIdentityCorrelation.field()
    )
  end

  defp validate_canonical_supplied_field(issues, path, summary, canonical, field) do
    if Map.has_key?(summary, field) and Map.get(summary, field) != Map.get(canonical, field) do
      [error(path <> ".#{field}", "must equal canonical allocation identity routing") | issues]
    else
      issues
    end
  end

  defp validate_contact_allocation_reason_identities(
         issues,
         path,
         %{"contract" => "contact_allocation_report.v1"} = summary
       ) do
    routes = Map.get(summary, "contact_ids_by_allocation_reason")

    canonical_routes =
      ContactAllocationReasonIdentityCorrelation.routes(
        Map.get(summary, "allocation_reason_counts"),
        routes
      )

    if is_map(routes) and routes != (canonical_routes || %{}) do
      [
        error(
          path <> ".contact_ids_by_allocation_reason",
          "must use canonical reason keys and IDs within local reason counts"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_contact_allocation_reason_identities(issues, _path, _summary), do: issues

  defp validate_contact_allocation_count_maps(
         issues,
         path,
         %{"contract" => "contact_allocation_report.v1"} = summary
       ) do
    Enum.reduce(ContactAllocationCountMapCorrelation.count_fields(), issues, fn field, acc ->
      counts = Map.get(summary, field)

      canonical_counts =
        ContactAllocationCountMapCorrelation.correlated_counts(
          counts,
          Map.get(summary, "row_count")
        ) || %{}

      if is_map(counts) and counts != canonical_counts do
        [
          error(
            path <> ".#{field}",
            "must use canonical positive counts whose total does not exceed positive row_count"
          )
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp validate_contact_allocation_count_maps(issues, _path, _summary), do: issues

  defp validate_contact_allocation_resource_blocking(
         issues,
         path,
         %{"contract" => "contact_allocation_report.v1"} = summary
       ) do
    canonical = ContactAllocationResourceBlockingCorrelation.fields(summary)

    ContactAllocationResourceBlockingCorrelation.fields()
    |> Enum.take(3)
    |> Enum.reduce(issues, fn field, acc ->
      validate_canonical_supplied_field(acc, path, summary, canonical, field)
    end)
  end

  defp validate_contact_allocation_resource_blocking(issues, _path, _summary), do: issues

  defp validate_contact_allocation_station_pressure_review(
         issues,
         path,
         %{"contract" => "contact_allocation_report.v1"} = summary
       ) do
    canonical = ContactAllocationStationPressureReviewCorrelation.fields(summary)

    Enum.reduce(ContactAllocationStationPressureReviewCorrelation.fields(), issues, fn field,
                                                                                       acc ->
      validate_canonical_supplied_field(acc, path, summary, canonical, field)
    end)
  end

  defp validate_contact_allocation_station_pressure_review(issues, _path, _summary), do: issues

  defp validate_contact_allocation_station_pressure_routing(
         issues,
         path,
         %{"contract" => "contact_allocation_report.v1"} = summary
       ) do
    canonical = ContactAllocationStationPressureRoutingCorrelation.fields(summary)

    Enum.reduce(ContactAllocationStationPressureRoutingCorrelation.fields(), issues, fn field,
                                                                                        acc ->
      validate_canonical_supplied_field(acc, path, summary, canonical, field)
    end)
  end

  defp validate_contact_allocation_station_pressure_routing(issues, _path, _summary), do: issues

  defp validate_contact_allocation_reservation_conflict(
         issues,
         path,
         %{"contract" => "contact_allocation_report.v1"} = summary
       ) do
    canonical = ContactAllocationReservationConflictCorrelation.fields(summary)

    Enum.reduce(ContactAllocationReservationConflictCorrelation.fields(), issues, fn field, acc ->
      validate_canonical_supplied_field(acc, path, summary, canonical, field)
    end)
  end

  defp validate_contact_allocation_reservation_conflict(issues, _path, _summary), do: issues

  defp validate_contact_allocation_direction_fields(
         issues,
         path,
         %{"contract" => "contact_allocation_report.v1"} = summary
       ) do
    counts = Map.get(summary, "direction_counts")
    contact_ids_by_direction = Map.get(summary, "contact_ids_by_direction")
    canonical_counts = ContactAllocationDirectionCorrelation.direction_counts(counts)

    issues =
      if is_map(counts) and counts != canonical_counts do
        [
          error(
            path <> ".direction_counts",
            "must use canonical stable direction keys with positive integer counts"
          )
          | issues
        ]
      else
        issues
      end

    canonical_contact_ids =
      ContactAllocationDirectionCorrelation.contact_ids_by_direction(
        canonical_counts,
        contact_ids_by_direction
      ) || %{}

    if is_map(contact_ids_by_direction) and contact_ids_by_direction != canonical_contact_ids do
      [
        error(
          path <> ".contact_ids_by_direction",
          "must contain sorted unique stable IDs within each positive local direction count"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_contact_allocation_direction_fields(issues, _path, _summary), do: issues

  defp validate_contact_allocation_direction_routing(
         issues,
         path,
         %{
           "contract" => "contact_allocation_report.v1",
           "direction_routing" => direction_routing
         } = summary
       )
       when is_map(direction_routing) do
    expected_routing = ContactAllocationDirectionRouting.fields_from_summary(summary) || %{}

    if direction_routing == expected_routing do
      issues
    else
      [
        error(
          path <> ".direction_routing",
          "must equal canonical routing rebuilt from contact-allocation field maps"
        )
        | issues
      ]
    end
  end

  defp validate_contact_allocation_direction_routing(issues, _path, _summary), do: issues

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

  defp validate_contact_contention_direction_counts(
         issues,
         path,
         %{
           "contract" => "contact_contention_report.v1",
           "direction_counts" => counts
         }
       )
       when is_map(counts) do
    Enum.reduce(counts, issues, fn {direction, count}, acc ->
      canonical_direction = ContactPairs.normalize_direction(direction)

      if is_integer(count) and count > 0 and StableIdValidation.valid?(direction) and
           canonical_direction == direction and direction not in ["mixed", "contact"] do
        acc
      else
        [
          error(
            path <> ".direction_counts.#{direction}",
            "must use a canonical stable direction key with a positive integer count"
          )
          | acc
        ]
      end
    end)
  end

  defp validate_contact_contention_direction_counts(issues, _path, _summary), do: issues

  defp validate_contact_contention_contact_ids(
         issues,
         path,
         %{
           "contract" => "contact_contention_report.v1"
         } = summary
       ) do
    counts = Map.get(summary, "contact_contention_contact_id_counts")
    direction_counts = Map.get(summary, "direction_counts")
    contact_ids_by_direction = Map.get(summary, "contact_ids_by_direction")

    if is_map(counts) or is_map(contact_ids_by_direction) do
      counts = if is_map(counts), do: counts, else: %{}

      positive_directions =
        if is_map(direction_counts) do
          direction_counts
          |> Enum.filter(fn {_direction, count} -> is_integer(count) and count > 0 end)
          |> Map.new()
        else
          %{}
        end

      allowed_contact_ids =
        if is_map(contact_ids_by_direction) do
          positive_directions
          |> Map.keys()
          |> Enum.flat_map(fn direction ->
            case Map.get(contact_ids_by_direction, direction) do
              ids when is_list(ids) -> ids
              _ids -> []
            end
          end)
          |> MapSet.new()
        else
          MapSet.new()
        end

      issues =
        Enum.reduce(counts, issues, fn {contact_id, count}, acc ->
          if StableIdValidation.valid?(contact_id) and is_integer(count) and count > 0 and
               MapSet.member?(allowed_contact_ids, contact_id) do
            acc
          else
            [
              error(
                path <> ".contact_contention_contact_id_counts.#{contact_id}",
                "must use a positive stable contact ID present in positive direction evidence"
              )
              | acc
            ]
          end
        end)

      counted_contact_ids = Map.keys(counts) |> MapSet.new()

      issues =
        if is_map(contact_ids_by_direction) do
          Enum.reduce(contact_ids_by_direction, issues, fn {direction, ids}, acc ->
            direction_count = Map.get(positive_directions, direction)

            if is_integer(direction_count) and is_list(ids) and ids == Enum.uniq(ids) and
                 length(ids) <= direction_count and
                 Enum.all?(ids, &MapSet.member?(counted_contact_ids, &1)) do
              acc
            else
              [
                error(
                  path <> ".contact_ids_by_direction.#{direction}",
                  "must correlate unique counted contact IDs within the positive direction count"
                )
                | acc
              ]
            end
          end)
        else
          issues
        end

      contact_count =
        counts
        |> Map.values()
        |> Enum.filter(&(is_integer(&1) and &1 > 0))
        |> Enum.sum()

      direction_count = Enum.sum(Map.values(positive_directions))

      if contact_count <= direction_count do
        issues
      else
        [
          error(
            path <> ".contact_contention_contact_id_counts",
            "contact-ID counts must not exceed positive direction counts"
          )
          | issues
        ]
      end
    else
      issues
    end
  end

  defp validate_contact_contention_contact_ids(issues, _path, _summary), do: issues

  defp validate_contact_contention_direction_routing(
         issues,
         path,
         %{
           "contract" => "contact_contention_report.v1",
           "direction_routing" => direction_routing
         } = summary
       )
       when is_map(direction_routing) do
    direction_counts = Correlation.direction_counts(Map.get(summary, "direction_counts"))

    contact_id_counts =
      Correlation.contact_id_counts(
        direction_counts,
        Map.get(summary, "contact_ids_by_direction"),
        Map.get(summary, "contact_contention_contact_id_counts")
      )

    contact_ids_by_direction =
      Correlation.contact_ids_by_direction(
        direction_counts,
        Map.get(summary, "contact_ids_by_direction"),
        contact_id_counts
      )

    expected_routing = RouteMap.field(direction_counts, contact_ids_by_direction) || %{}

    if direction_routing == expected_routing do
      issues
    else
      [
        error(
          path <> ".direction_routing",
          "must equal canonical routing rebuilt from correlated direction counts and contact IDs"
        )
        | issues
      ]
    end
  end

  defp validate_contact_contention_direction_routing(issues, _path, _summary), do: issues
end
