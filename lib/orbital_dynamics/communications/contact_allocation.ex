defmodule OrbitalDynamics.Communications.ContactAllocation do
  @moduledoc """
  Deterministic artifact-only contact allocation review.

  This module composes the existing ground-network filter and same-station
  contention resolver into an allocation report with allocated, deferred, and
  blocked contact rows. It does not reserve provider time, mutate schedules, or
  approve contacts.
  """

  alias OrbitalDynamics.{Policy, ResourceFilter}
  alias OrbitalDynamics.Communications.{ContactContention, ContactFilter, StationCalendar}

  @schema_contract "contact_allocation_report.v1"
  @summary_schema_contract "contact_allocation_summary.v1"
  @station_pressure_summary_schema_contract "contact_allocation_station_pressure_summary.v1"
  @capacity_pack_summary_schema_contract "contact_allocation_capacity_pack_summary.v1"
  @reservation_conflict_summary_schema_contract "contact_allocation_reservation_conflict_summary.v1"
  @provider_reservation_request_summary_schema_contract "contact_allocation_provider_reservation_request_summary.v1"
  @contact_types ~w(downlink planned_contact tracking command health_check)
  @contact_directions ~w(downlink uplink command tracking health_check)
  @command_contact_directions ~w(command uplink)
  @provider_counteroffer_fields ~w(
    provider_counteroffer_id
    provider_counteroffer_status
    provider_counteroffer_negotiation_state
    provider_counteroffer_reason_code
    provider_counteroffer_cost_delta
    provider_counteroffer_lock_deadline_s
    provider_counteroffer_starts_at_s
    provider_counteroffer_ends_at_s
    provider_counteroffer_start_delta_s
    provider_counteroffer_end_delta_s
    provider_counteroffer_duration_delta_s
  )
  @row_statuses ~w(allocated deferred blocked)
  @effective_row_statuses @row_statuses ++ ["policy_blocked"]
  @unavailable_aliases ["outage", "down", "offline"]
  @station_blocking_availability ["unavailable", "maintenance"]
  @station_availability_severity %{
    "unavailable" => 5,
    "maintenance" => 5,
    "reserved" => 4,
    "reduced_capacity" => 3,
    "available" => 1
  }
  @station_capacity_fraction_paths [
    ["availability"],
    ["capacity_pack_capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_fraction"],
    ["throughput_model", "availability"],
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "availability"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "availability"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"]
  ]
  @station_capacity_percent_paths [
    ["capacity_percent"],
    ["station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["throughput_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["activity_context", "capacity_percent"],
    ["activity_context", "station_capacity_percent"]
  ]
  @required_capacity_fraction_paths [
    ["required_capacity_fraction"],
    ["required_station_capacity_fraction"],
    ["station_capacity_requirement"],
    ["throughput_model", "required_capacity_fraction"],
    ["throughput_model", "required_station_capacity_fraction"],
    ["throughput_model", "station_capacity_requirement"],
    ["capacity_model", "required_capacity_fraction"],
    ["capacity_model", "required_station_capacity_fraction"],
    ["capacity_model", "station_capacity_requirement"],
    ["activity_context", "required_capacity_fraction"],
    ["activity_context", "required_station_capacity_fraction"],
    ["activity_context", "station_capacity_requirement"]
  ]
  @required_capacity_percent_paths [
    ["required_capacity_percent"],
    ["required_station_capacity_percent"],
    ["station_capacity_requirement_percent"],
    ["throughput_model", "required_capacity_percent"],
    ["throughput_model", "required_station_capacity_percent"],
    ["throughput_model", "station_capacity_requirement_percent"],
    ["capacity_model", "required_capacity_percent"],
    ["capacity_model", "required_station_capacity_percent"],
    ["capacity_model", "station_capacity_requirement_percent"],
    ["activity_context", "required_capacity_percent"],
    ["activity_context", "required_station_capacity_percent"],
    ["activity_context", "station_capacity_requirement_percent"]
  ]
  @default_required_capacity_fraction_paths [
    ["default_required_capacity_fraction"],
    ["capacity_policy", "default_required_capacity_fraction"],
    ["policy", "default_required_capacity_fraction"]
  ]
  @required_capacity_fraction_source_values ~w(
    contact_required_capacity_fraction
    throughput_model
    capacity_model
    activity_context
    default_reduced_capacity_policy
    station_capacity_fraction_fallback
    implicit_full_station_capacity
  )
  @capacity_pack_statuses ~w(
    selected_by_contention_resolution
    selected_by_reduced_station_capacity_pack
    deferred_by_reduced_station_capacity_pack
  )
  @reduced_capacity_pack_statuses ~w(
    all_fit
    capacity_limited
  )
  @station_reservation_match_statuses ~w(
    matched
    owner_matched
    overlap
  )
  @reservation_conflict_match_statuses ~w(
    overlap
  )
  @station_reservation_expiration_statuses ~w(
    missing
    declared
    active
    expired
  )
  @provider_reservation_request_statuses ~w(
    clear
    request_ready
    review_required
  )
  @default_required_capacity_value_paths for path <- @default_required_capacity_fraction_paths,
                                             do: {:fraction, path}
  @station_capacity_value_paths [
    {:fraction, ["availability"]},
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:percent, ["capacity_percent"]},
    {:percent, ["station_capacity_percent"]},
    {:fraction, ["throughput_model", "availability"]},
    {:fraction, ["throughput_model", "station_capacity_fraction"]},
    {:fraction, ["throughput_model", "capacity_fraction"]},
    {:percent, ["throughput_model", "capacity_percent"]},
    {:percent, ["throughput_model", "station_capacity_percent"]},
    {:fraction, ["capacity_model", "availability"]},
    {:fraction, ["capacity_model", "station_capacity_fraction"]},
    {:fraction, ["capacity_model", "capacity_fraction"]},
    {:percent, ["capacity_model", "capacity_percent"]},
    {:percent, ["capacity_model", "station_capacity_percent"]},
    {:fraction, ["activity_context", "availability"]},
    {:fraction, ["activity_context", "station_capacity_fraction"]},
    {:fraction, ["activity_context", "capacity_fraction"]},
    {:percent, ["activity_context", "capacity_percent"]},
    {:percent, ["activity_context", "station_capacity_percent"]}
  ]
  @required_capacity_value_paths [
    {:fraction, ["required_capacity_fraction"]},
    {:fraction, ["required_station_capacity_fraction"]},
    {:fraction, ["station_capacity_requirement"]},
    {:percent, ["required_capacity_percent"]},
    {:percent, ["required_station_capacity_percent"]},
    {:percent, ["station_capacity_requirement_percent"]},
    {:fraction, ["throughput_model", "required_capacity_fraction"]},
    {:fraction, ["throughput_model", "required_station_capacity_fraction"]},
    {:fraction, ["throughput_model", "station_capacity_requirement"]},
    {:percent, ["throughput_model", "required_capacity_percent"]},
    {:percent, ["throughput_model", "required_station_capacity_percent"]},
    {:percent, ["throughput_model", "station_capacity_requirement_percent"]},
    {:fraction, ["capacity_model", "required_capacity_fraction"]},
    {:fraction, ["capacity_model", "required_station_capacity_fraction"]},
    {:fraction, ["capacity_model", "station_capacity_requirement"]},
    {:percent, ["capacity_model", "required_capacity_percent"]},
    {:percent, ["capacity_model", "required_station_capacity_percent"]},
    {:percent, ["capacity_model", "station_capacity_requirement_percent"]},
    {:fraction, ["activity_context", "required_capacity_fraction"]},
    {:fraction, ["activity_context", "required_station_capacity_fraction"]},
    {:fraction, ["activity_context", "station_capacity_requirement"]},
    {:percent, ["activity_context", "required_capacity_percent"]},
    {:percent, ["activity_context", "required_station_capacity_percent"]},
    {:percent, ["activity_context", "station_capacity_requirement_percent"]}
  ]
  @provider_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "up" => "uplink",
    "up_link" => "uplink",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "down_link" => "downlink",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check"
  }
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @contact_stable_identity_fields ~w(
    scenario_id
    spacecraft_id
    satellite_id
    ground_station_id
    source_window_id
    station_calendar_entry_id
    station_reservation_id
  )
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  @doc """
  Declares the contact allocation model and known limits.
  """
  def capabilities do
    contention_capabilities = ContactContention.capabilities()

    %{
      artifact_contract: @schema_contract,
      summary_artifact_contract: @summary_schema_contract,
      station_pressure_summary_artifact_contract: @station_pressure_summary_schema_contract,
      capacity_pack_summary_artifact_contract: @capacity_pack_summary_schema_contract,
      reservation_conflict_summary_artifact_contract:
        @reservation_conflict_summary_schema_contract,
      provider_reservation_request_summary_artifact_contract:
        @provider_reservation_request_summary_schema_contract,
      model: :deterministic_station_contact_allocation,
      validation_level: :artifact_contract,
      row_statuses: @row_statuses,
      effective_row_statuses: @effective_row_statuses,
      row_review_statuses: ["accepted_for_planning", "operator_review_required"],
      station_unavailable_aliases: @unavailable_aliases,
      station_blocking_availability: @station_blocking_availability,
      station_availability_precedence: @station_availability_severity,
      station_capacity_fraction_paths: @station_capacity_fraction_paths,
      station_capacity_percent_paths: @station_capacity_percent_paths,
      station_capacity_value_paths: capacity_value_path_metadata(@station_capacity_value_paths),
      source_station_capacity_fraction_paths: @station_capacity_fraction_paths,
      source_station_capacity_percent_paths: @station_capacity_percent_paths,
      source_station_capacity_value_paths:
        capacity_value_path_metadata(@station_capacity_value_paths),
      required_capacity_fraction_paths: @required_capacity_fraction_paths,
      required_capacity_percent_paths: @required_capacity_percent_paths,
      required_capacity_value_paths: capacity_value_path_metadata(@required_capacity_value_paths),
      required_capacity_fraction_source_values: @required_capacity_fraction_source_values,
      capacity_pack_statuses: @capacity_pack_statuses,
      reduced_capacity_pack_statuses: @reduced_capacity_pack_statuses,
      station_reservation_match_statuses: @station_reservation_match_statuses,
      reservation_conflict_match_statuses: @reservation_conflict_match_statuses,
      station_reservation_expiration_statuses: @station_reservation_expiration_statuses,
      provider_reservation_request_statuses: @provider_reservation_request_statuses,
      default_required_capacity_fraction_paths: @default_required_capacity_fraction_paths,
      default_required_capacity_value_paths:
        capacity_value_path_metadata(@default_required_capacity_value_paths),
      provider_direction_aliases: @provider_direction_aliases,
      provider_result_map_value_keys: @provider_result_map_value_keys,
      provider_counteroffer_fields: @provider_counteroffer_fields,
      contact_stable_identity_fields: @contact_stable_identity_fields,
      command_contact_directions: @command_contact_directions,
      contention_resolution_selection_rules: contention_capabilities.resolution_selection_rules,
      contention_resolution_tie_breakers: contention_capabilities.resolution_tie_breakers,
      contention_default_resolution_priority_fields:
        contention_capabilities.default_resolution_priority_fields,
      contention_resolution_priority_override_aliases:
        contention_capabilities.resolution_priority_override_aliases,
      public_facades: [
        :allocate_contacts,
        :contact_allocation_report,
        :contact_allocation_summary,
        :contact_allocation_capacity_pack_summary,
        :contact_allocation_station_pressure_summary,
        :contact_allocation_reservation_conflict_summary,
        :contact_allocation_provider_reservation_request_summary
      ],
      handoff_artifacts: [
        "operator_review_package.v1",
        "cadence_import_manifest.v1"
      ],
      handoff_review_types: [
        "contact_allocation_review",
        "contact_allocation_capacity_pack_review",
        "station_reservation_review"
      ],
      handoff_import_actions: [
        "review_contact_allocation",
        "review_contact_allocation_capacity_pack",
        "review_provider_reservation_request",
        "review_station_reservation"
      ],
      row_semantics: [
        :invalid_contact_input_review,
        :status_aware_contact_allocation_effects,
        :station_calendar_filtered_allocation,
        :same_station_contention_resolution,
        :same_spacecraft_contention_resolution,
        :priority_aware_contention_resolution,
        :contention_priority_evidence_handoff,
        :contention_priority_field_evidence_handoff,
        :approval_policy_effective_status,
        :nested_contention_policy_evidence,
        :direction_scoped_station_calendar,
        :station_calendar_provider_input,
        :station_calendar_provider_list_input,
        :station_capacity_value_paths,
        :source_station_capacity_value_paths,
        :required_capacity_value_paths,
        :default_required_capacity_value_paths,
        :contact_stable_identity_fields,
        :command_contact_directions,
        :provider_direction_aliases,
        :provider_result_map_value_keys,
        :provider_counteroffer_review_handoff,
        :provider_counteroffer_fields,
        :station_reservation_identity_match,
        :station_reservation_owner_match,
        :station_calendar_reservation_expiration_context,
        :station_reservation_match_status_counts,
        :station_calendar_trust_evidence_preservation,
        :station_calendar_entry_identity_preservation,
        :station_calendar_precedence_evidence_preservation,
        :station_calendar_counts_derive_from_id_sets,
        :station_calendar_trust_policy_boundary,
        :contact_source_window_provenance,
        :realized_contact_evidence_preservation,
        :status_blocked_station_calendar_context,
        :realized_status_blocked_throughput_preservation,
        :realized_status_blocked_data_rate_throughput_preservation,
        :actual_data_rate_throughput_derivation_evidence,
        :realized_status_blocked_completion_fraction_preservation,
        :feedback_unit_interval_input_validation,
        :downlink_completion_evidence_preservation,
        :resource_summary_filter_allocation_boundary,
        :resource_battery_mode_evidence_preservation,
        :resource_thermal_margin_evidence_preservation,
        :resource_activity_type_constraint_evidence_preservation,
        :allocation_capacity_fraction_validation,
        :reduced_station_capacity_requirement,
        :default_reduced_station_capacity_requirement,
        :reduced_station_capacity_packing,
        :reduced_station_capacity_pack_ledger,
        :capacity_pack_status_values,
        :reduced_capacity_pack_status_values,
        :contact_allocation_summary,
        :contact_allocation_summary_routing_id_sets,
        :contact_allocation_summary_status_station_routing,
        :contact_allocation_summary_reason_routing,
        :contact_allocation_summary_canonical_station_status_routing,
        :contact_allocation_summary_capacity_pack_routing,
        :contact_allocation_capacity_pack_summary,
        :contact_allocation_resource_pressure_summary,
        :contact_allocation_station_pressure_summary,
        :contact_allocation_station_pressure_count_maps,
        :contact_allocation_station_precedence_summary,
        :contact_allocation_summary_reservation_status_routing,
        :contact_allocation_summary_reservation_owner_routing,
        :contact_allocation_summary_reservation_id_routing,
        :contact_allocation_summary_reservation_expiration_routing,
        :contact_allocation_reservation_conflict_summary,
        :contact_allocation_reservation_conflict_status_values,
        :contact_allocation_reservation_conflict_review_handoff,
        :contact_allocation_provider_reservation_request_summary,
        :contact_allocation_provider_reservation_request_status_values,
        :contact_allocation_provider_reservation_request_review_handoff,
        :station_reservation_expiration_status_values,
        :contact_allocation_summary_direct_station_availability_routing,
        :contact_allocation_summary_required_capacity_source_routing,
        :contact_allocation_summary_row_derived_counts
      ],
      contact_directions: @contact_directions,
      approval_policy_boundary: :optional_policy_decision_v1,
      known_limits: [
        :artifact_level_only,
        :declared_ground_network_only,
        :optional_externally_supplied_resource_summary,
        :no_full_realized_contact_reconciliation,
        :no_provider_reservation,
        :no_schedule_mutation,
        :no_approval_workflow,
        :no_link_budget_model
      ]
    }
  end

  defp capacity_value_path_metadata(paths) do
    Enum.map(paths, fn {unit, path} -> %{unit: unit, path: path} end)
  end

  defp capacity_value_path_assumptions(paths) do
    Enum.map(paths, fn {unit, path} -> %{"unit" => Atom.to_string(unit), "path" => path} end)
  end

  defp capacity_pack_capability_assumptions do
    %{
      "capacity_pack_statuses" => @capacity_pack_statuses,
      "reduced_capacity_pack_statuses" => @reduced_capacity_pack_statuses,
      "required_capacity_fraction_source_values" => @required_capacity_fraction_source_values,
      "required_capacity_value_paths" =>
        capacity_value_path_assumptions(@required_capacity_value_paths),
      "default_required_capacity_value_paths" =>
        capacity_value_path_assumptions(@default_required_capacity_value_paths)
    }
  end

  defp allocation_summary_capability_assumptions do
    %{
      "row_statuses" => @row_statuses,
      "effective_row_statuses" => @effective_row_statuses,
      "station_unavailable_aliases" => @unavailable_aliases,
      "station_blocking_availability" => @station_blocking_availability,
      "station_availability_precedence" => @station_availability_severity,
      "capacity_pack_statuses" => @capacity_pack_statuses,
      "reduced_capacity_pack_statuses" => @reduced_capacity_pack_statuses,
      "station_reservation_match_statuses" => @station_reservation_match_statuses,
      "station_reservation_expiration_statuses" => @station_reservation_expiration_statuses,
      "required_capacity_fraction_source_values" => @required_capacity_fraction_source_values,
      "required_capacity_value_paths" =>
        capacity_value_path_assumptions(@required_capacity_value_paths),
      "default_required_capacity_value_paths" =>
        capacity_value_path_assumptions(@default_required_capacity_value_paths),
      "provider_direction_aliases" => @provider_direction_aliases
    }
  end

  defp provider_reservation_request_capability_assumptions do
    %{
      "provider_reservation_request_statuses" => @provider_reservation_request_statuses,
      "station_reservation_match_statuses" => @station_reservation_match_statuses,
      "provider_direction_aliases" => @provider_direction_aliases
    }
  end

  defp station_pressure_capability_assumptions do
    %{
      "station_unavailable_aliases" => @unavailable_aliases,
      "station_blocking_availability" => @station_blocking_availability,
      "station_availability_precedence" => @station_availability_severity,
      "provider_direction_aliases" => @provider_direction_aliases
    }
  end

  defp reservation_conflict_capability_assumptions do
    %{
      "station_reservation_match_statuses" => @station_reservation_match_statuses,
      "reservation_conflict_match_statuses" => @reservation_conflict_match_statuses,
      "station_reservation_expiration_statuses" => @station_reservation_expiration_statuses,
      "provider_direction_aliases" => @provider_direction_aliases
    }
  end

  @doc """
  Allocates contact candidates into deterministic planning rows.

  The returned contact list contains only contacts with allocation status
  `"allocated"` that are not blocked by the supplied approval policy. Blocked
  rows come from the contact filter; deferred rows come from same-station
  contention recommendations.
  """
  def allocate_contacts(contacts, ground_network \\ [], opts \\ [])

  def allocate_contacts(contacts, ground_network, opts)
      when is_list(contacts) do
    source = opts |> Keyword.get(:source, "contact_candidates") |> to_string()
    approval_policy = Keyword.get(opts, :approval_policy)
    resource_summaries = Keyword.get(opts, :resource_summaries, [])

    contact_inputs =
      contacts
      |> Enum.map(&normalize_contact/1)
      |> Enum.filter(&contact_like_input?/1)

    {invalid_contact_inputs, contacts} =
      contact_inputs
      |> Enum.with_index(1)
      |> Enum.split_with(fn {contact, _index} -> invalid_contact_input?(contact) end)

    valid_contacts = Enum.map(contacts, fn {contact, _index} -> contact end)
    duplicate_contact_groups = duplicate_contact_groups(valid_contacts)
    duplicate_contact_ids = duplicate_contact_ids(duplicate_contact_groups)
    ground_network = normalize_ground_network(ground_network)
    default_capacity_requirement = default_required_capacity_fraction(opts)

    allocation_input_contacts =
      Enum.reject(valid_contacts, &(contact_id(&1) in duplicate_contact_ids))

    {status_blocked_contacts, active_allocation_input_contacts} =
      Enum.split_with(allocation_input_contacts, &status_allocation_blocked?/1)

    status_blocked_contacts =
      annotate_status_blocked_contacts(
        status_blocked_contacts,
        ground_network,
        source,
        approval_policy
      )

    {resource_available_contacts, resource_filter_report} =
      apply_resource_filter(active_allocation_input_contacts, resource_summaries, opts)

    {annotated_contacts, station_calendar_report} =
      StationCalendar.overlay_contacts(resource_available_contacts, ground_network,
        source: "#{source}.ground_network",
        approval_policy: approval_policy
      )

    {available_contacts, contact_filter_report} =
      ContactFilter.filter_candidates(annotated_contacts, ground_network,
        approval_policy: approval_policy
      )

    {station_blocked_contacts, allocation_candidates} =
      Enum.split_with(available_contacts, &station_allocation_blocked?/1)

    {contention_contacts, contention_report} =
      ContactContention.annotate_contacts(allocation_candidates,
        source: source,
        approval_policy: approval_policy
      )

    resolution_report =
      ContactContention.resolution_report(contention_contacts, contention_report,
        policy: Keyword.get(opts, :policy, %{}),
        approval_policy: approval_policy
      )

    blocked_rows =
      invalid_contact_rows(invalid_contact_inputs) ++
        resource_blocked_rows(resource_filter_report) ++
        blocked_rows(contact_filter_report) ++
        station_blocked_rows(station_blocked_contacts) ++
        status_blocked_rows(status_blocked_contacts) ++
        duplicate_contact_rows(duplicate_contact_groups)

    deferred_by_contact_id = deferred_by_contact_id(resolution_report)
    selected_by_contact_id = selected_by_contact_id(resolution_report)

    {allocation_rows, reduced_capacity_pack_groups} =
      contention_contacts
      |> Enum.map(&allocation_row(&1, deferred_by_contact_id, selected_by_contact_id))
      |> Kernel.++(blocked_rows)
      |> Enum.sort_by(&allocation_sort_key/1)
      |> apply_reduced_capacity_packing(default_capacity_requirement)

    allocation_rows =
      allocation_rows
      |> maybe_apply_approval_policy(approval_policy)
      |> Enum.map(&put_effective_allocation_status/1)

    station_pressure_rows = station_pressure_summary_rows(allocation_rows)

    station_pressure_contact_ids_by_ground_station_id =
      contact_ids_by_field(station_pressure_rows, "ground_station_id")

    station_pressure_contact_ids_by_availability =
      station_pressure_contact_ids_by_availability(station_pressure_rows)

    station_pressure_contact_ids_by_precedence_availability =
      contact_ids_by_field(station_pressure_rows, "station_calendar_precedence_availability")

    station_pressure_contact_ids_by_precedence_rank =
      contact_ids_by_string_field(station_pressure_rows, "station_calendar_precedence_rank")

    station_pressure_contact_ids_by_status =
      contact_ids_by_field(station_pressure_rows, "station_calendar_status")

    station_pressure_contact_ids_by_direction_and_ground_station_id =
      contact_ids_by_direction_and_ground_station_id(station_pressure_rows)

    reservation_expiration_rows =
      station_reservation_expiration_summary_rows(allocation_rows, nil)

    capacity_pack_rows = capacity_pack_summary_rows(allocation_rows)
    selected_capacity_pack_rows = selected_capacity_pack_summary_rows(capacity_pack_rows)
    deferred_capacity_pack_rows = deferred_capacity_pack_summary_rows(capacity_pack_rows)

    allocated_contacts =
      allocation_rows
      |> Enum.filter(&allocated_contact_row?/1)
      |> Enum.map(&allocated_contact_from_row(&1, contention_contacts))

    report =
      %{
        "schema_contract" => @schema_contract,
        "model" => "deterministic_station_contact_allocation",
        "source" => source,
        "input_contact_count" => length(contact_inputs),
        "allocated_contact_count" =>
          Enum.count(allocation_rows, &(&1["allocation_status"] == "allocated")),
        "returned_allocated_contact_count" =>
          Enum.count(allocation_rows, &(&1["effective_allocation_status"] == "allocated")),
        "policy_blocked_allocated_contact_count" =>
          Enum.count(allocation_rows, &(&1["effective_allocation_status"] == "policy_blocked")),
        "deferred_contact_count" =>
          Enum.count(allocation_rows, &(&1["allocation_status"] == "deferred")),
        "blocked_contact_count" =>
          Enum.count(allocation_rows, &(&1["allocation_status"] == "blocked")),
        "allocation_status_counts" => count_by(allocation_rows, "allocation_status"),
        "effective_allocation_status_counts" =>
          count_by(allocation_rows, "effective_allocation_status"),
        "allocation_reason_counts" => count_by(allocation_rows, "allocation_reason"),
        "station_reservation_match_status_counts" =>
          count_by(allocation_rows, "station_reservation_match_status"),
        "station_reservation_ids" => row_values(allocation_rows, "station_reservation_id"),
        "station_reservation_expires_at_s" =>
          row_values(allocation_rows, "station_reservation_expires_at_s"),
        "station_reservation_expiration_status_counts" =>
          station_reservation_expiration_status_counts(reservation_expiration_rows),
        "station_reservation_declared_expiration_contact_count" =>
          station_reservation_expiration_count(reservation_expiration_rows, "declared"),
        "station_reservation_missing_expiration_contact_count" =>
          station_reservation_expiration_count(reservation_expiration_rows, "missing"),
        "earliest_station_reservation_expires_at_s" =>
          earliest_station_reservation_expires_at_s(reservation_expiration_rows),
        "station_reservation_contact_ids_by_expiration_status" =>
          station_reservation_contact_ids_by_expiration_status(reservation_expiration_rows),
        "station_reservation_ids_by_expiration_status" =>
          station_reservation_ids_by_expiration_status(reservation_expiration_rows),
        "station_reserved_bys" => row_values(allocation_rows, "station_reserved_by"),
        "station_reservation_statuses" =>
          row_values(allocation_rows, "station_reservation_status"),
        "calendar_entry_trust_boundary_status_counts" =>
          Map.get(station_calendar_report, "calendar_entry_trust_boundary_status_counts"),
        "station_calendar_trust_boundary_status_counts" =>
          station_calendar_trust_boundary_status_counts(allocation_rows),
        "station_pressure_contact_ids_by_ground_station_id" =>
          station_pressure_contact_ids_by_ground_station_id,
        "station_pressure_contact_counts_by_ground_station_id" =>
          id_set_count_map(station_pressure_contact_ids_by_ground_station_id),
        "station_pressure_contact_ids_by_availability" =>
          station_pressure_contact_ids_by_availability,
        "station_pressure_contact_counts_by_availability" =>
          id_set_count_map(station_pressure_contact_ids_by_availability),
        "station_pressure_contact_ids_by_precedence_availability" =>
          station_pressure_contact_ids_by_precedence_availability,
        "station_pressure_contact_counts_by_precedence_availability" =>
          id_set_count_map(station_pressure_contact_ids_by_precedence_availability),
        "station_pressure_contact_ids_by_precedence_rank" =>
          station_pressure_contact_ids_by_precedence_rank,
        "station_pressure_contact_counts_by_precedence_rank" =>
          id_set_count_map(station_pressure_contact_ids_by_precedence_rank),
        "station_pressure_contact_ids_by_status" => station_pressure_contact_ids_by_status,
        "station_pressure_contact_counts_by_status" =>
          id_set_count_map(station_pressure_contact_ids_by_status),
        "station_pressure_contact_ids_by_direction_and_ground_station_id" =>
          station_pressure_contact_ids_by_direction_and_ground_station_id,
        "invalid_contact_input_count" => length(invalid_contact_inputs),
        "invalid_contact_input_ids" =>
          Enum.map(invalid_contact_rows(invalid_contact_inputs), & &1["contact_id"]),
        "status_blocked_contact_count" => status_blocked_allocation_count(allocation_rows),
        "status_blocked_contact_ids" => status_blocked_allocation_ids(allocation_rows),
        "resource_blocked_contact_count" => resource_blocked_contact_count(allocation_rows),
        "resource_blocked_contact_ids" => resource_blocked_contact_ids(allocation_rows),
        "resource_blocking_dimension_counts" =>
          contact_id_count_map(
            resource_blocked_summary_rows(allocation_rows),
            "resource_blocking_dimension"
          ),
        "resource_blocked_contact_ids_by_blocking_dimension" =>
          contact_ids_by_field(
            resource_blocked_summary_rows(allocation_rows),
            "resource_blocking_dimension"
          ),
        "resource_blocked_contact_ids_by_spacecraft_id" =>
          contact_ids_by_field(resource_blocked_summary_rows(allocation_rows), "spacecraft_id"),
        "reduced_capacity_pack_group_count" => length(reduced_capacity_pack_groups),
        "reduced_capacity_pack_groups" => reduced_capacity_pack_groups,
        "reduced_capacity_pack_status_counts" =>
          count_by(reduced_capacity_pack_groups, "pack_status"),
        "capacity_pack_status_counts" => count_by(allocation_rows, "capacity_pack_status"),
        "capacity_pack_required_capacity_fraction" =>
          capacity_pack_required_fraction(capacity_pack_rows),
        "capacity_pack_selected_required_capacity_fraction" =>
          capacity_pack_required_fraction(selected_capacity_pack_rows),
        "capacity_pack_deferred_required_capacity_fraction" =>
          capacity_pack_required_fraction(deferred_capacity_pack_rows),
        "capacity_pack_required_capacity_fraction_by_status" =>
          capacity_pack_required_fraction_by_field(capacity_pack_rows, "capacity_pack_status"),
        "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
          capacity_pack_required_fraction_by_field(capacity_pack_rows, "ground_station_id"),
        "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" =>
          capacity_pack_required_fraction_by_field(
            selected_capacity_pack_rows,
            "ground_station_id"
          ),
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" =>
          capacity_pack_required_fraction_by_field(
            deferred_capacity_pack_rows,
            "ground_station_id"
          ),
        "capacity_pack_contact_ids_by_status" =>
          contact_ids_by_field(allocation_rows, "capacity_pack_status"),
        "required_capacity_fraction_source_counts" =>
          count_by(allocation_rows, "required_capacity_fraction_source"),
        "required_capacity_fraction_contact_ids_by_source" =>
          contact_ids_by_field(allocation_rows, "required_capacity_fraction_source"),
        "reduced_capacity_packed_contact_ids" =>
          allocation_summary_contact_ids(
            allocation_rows,
            "capacity_pack_status",
            "selected_by_reduced_station_capacity_pack"
          ),
        "reduced_capacity_deferred_contact_ids" =>
          allocation_summary_contact_ids(
            allocation_rows,
            "capacity_pack_status",
            "deferred_by_reduced_station_capacity_pack"
          ),
        "duplicate_contact_id_count" => length(duplicate_contact_groups),
        "duplicate_contact_candidate_count" =>
          duplicate_contact_candidate_count(duplicate_contact_groups),
        "rows" => allocation_rows,
        "resource_filter_report" => resource_filter_report,
        "station_calendar_report" => station_calendar_report,
        "contact_filter_report" => contact_filter_report,
        "contact_contention_report" => contention_report,
        "contact_contention_resolution_report" => resolution_report,
        "model_limits" => model_limits(),
        "assumptions" => %{
          "ground_network_source" => "declared_ground_network_or_station_calendar_provider",
          "contention_resolution" => "deterministic_recommendation_requires_operator_review",
          "duplicate_contact_id" =>
            "duplicate contact IDs are blocked before contention allocation to preserve deterministic identity joins",
          "invalid_contact_input" =>
            "contact-like inputs missing required allocation identity, station, or timing fields are blocked for operator review instead of being silently dropped",
          "returned_allocated_contacts" =>
            "returned contacts exclude allocated rows whose approval policy classification is blocked_by_policy",
          "effective_allocation_status" =>
            "effective_allocation_status reflects whether allocated rows are usable after policy classification",
          "contact_status_model" =>
            "terminal_or_source_policy_blocked_contacts_are_audited_as_blocked_without_station_allocation",
          "resource_filter" =>
            "optional resource summaries suppress unavailable resource contacts before station allocation",
          "default_reduced_capacity_requirement" =>
            "when configured, reduced-capacity packing may use a declared default contact capacity requirement for contacts without explicit per-contact capacity demand",
          "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation"
        }
      }
      |> compact_map()

    {allocated_contacts, report}
  end

  def allocate_contacts(_contacts, _ground_network, _opts),
    do: raise(ArgumentError, "contacts must be a list")

  @doc """
  Builds only the `contact_allocation_report.v1`, discarding allocated contacts.
  """
  def report(contact_allocation_report)

  def report(%{"schema_contract" => @schema_contract} = report) do
    report
  end

  def report(%{schema_contract: @schema_contract} = report) do
    stringify_keys(report)
  end

  def report(contacts) when is_list(contacts) do
    report(contacts, [], [])
  end

  def report(_contact_allocation_report),
    do: raise(ArgumentError, "contact allocation report must be a map or contacts must be a list")

  def report(contacts, ground_network, opts \\ []) do
    {_contacts, report} = allocate_contacts(contacts, ground_network, opts)
    report
  end

  @doc """
  Builds a compact artifact-only allocation triage summary.

  This helper accepts either an existing `contact_allocation_report.v1`, an
  existing `contact_allocation_summary.v1`, or the source contacts and
  ground-network inputs used to build one. It exposes allocation status
  counters, selected review rows, and queue identity lists without reserving
  provider time, mutating schedules, or approving contacts.
  """
  def summary(contact_allocation_report)

  def summary(%{"schema_contract" => @summary_schema_contract} = summary), do: summary

  def summary(%{"schema_contract" => @schema_contract} = report) do
    summary(report, [])
  end

  def summary(%{schema_contract: @summary_schema_contract} = summary) do
    stringify_keys(summary)
  end

  def summary(%{schema_contract: @schema_contract} = report) do
    report
    |> stringify_keys()
    |> summary()
  end

  def summary(_contact_allocation_report),
    do: raise(ArgumentError, "contact allocation report is required")

  def summary(contact_allocation_report, opts)

  def summary(%{"schema_contract" => @summary_schema_contract} = summary, opts)
      when is_list(opts),
      do: summary

  def summary(%{"schema_contract" => @schema_contract} = report, opts) when is_list(opts) do
    allocation_summary(report, opts)
  end

  def summary(%{schema_contract: @summary_schema_contract} = summary, opts) when is_list(opts) do
    stringify_keys(summary)
  end

  def summary(%{schema_contract: @schema_contract} = report, opts) when is_list(opts) do
    report
    |> stringify_keys()
    |> summary(opts)
  end

  def summary(_contact_allocation_report, _opts),
    do: raise(ArgumentError, "contact allocation report is required")

  def summary(contacts, ground_network, opts) when is_list(contacts) do
    contacts
    |> report(ground_network, opts)
    |> summary(opts)
  end

  def summary(_contacts, _ground_network, _opts),
    do: raise(ArgumentError, "contacts must be a list")

  @doc """
  Builds a compact station-pressure summary for a contact allocation report.

  The helper is a focused view over station-calendar pressure carried by
  `contact_allocation_report.v1` rows. It derives contact ID and count maps for
  station availability, precedence availability, and precedence rank without
  reserving provider time, mutating schedules, or approving contacts.
  """
  def station_pressure_summary(contact_allocation_report)

  def station_pressure_summary(
        %{"schema_contract" => @station_pressure_summary_schema_contract} = summary
      ),
      do: summary

  def station_pressure_summary(%{"schema_contract" => @schema_contract} = report) do
    station_pressure_summary(report, [])
  end

  def station_pressure_summary(
        %{schema_contract: @station_pressure_summary_schema_contract} = summary
      ) do
    stringify_keys(summary)
  end

  def station_pressure_summary(%{schema_contract: @schema_contract} = report) do
    report
    |> stringify_keys()
    |> station_pressure_summary()
  end

  def station_pressure_summary(_contact_allocation_report),
    do: raise(ArgumentError, "contact allocation report is required")

  def station_pressure_summary(contact_allocation_report, opts)

  def station_pressure_summary(
        %{"schema_contract" => @station_pressure_summary_schema_contract} = summary,
        opts
      )
      when is_list(opts),
      do: summary

  def station_pressure_summary(%{"schema_contract" => @schema_contract} = report, opts)
      when is_list(opts) do
    allocation_station_pressure_summary(report, opts)
  end

  def station_pressure_summary(
        %{schema_contract: @station_pressure_summary_schema_contract} = summary,
        opts
      )
      when is_list(opts) do
    stringify_keys(summary)
  end

  def station_pressure_summary(%{schema_contract: @schema_contract} = report, opts)
      when is_list(opts) do
    report
    |> stringify_keys()
    |> station_pressure_summary(opts)
  end

  def station_pressure_summary(_contact_allocation_report, _opts),
    do: raise(ArgumentError, "contact allocation report is required")

  def station_pressure_summary(contacts, ground_network, opts) when is_list(contacts) do
    contacts
    |> report(ground_network, opts)
    |> station_pressure_summary(opts)
  end

  def station_pressure_summary(_contacts, _ground_network, _opts),
    do: raise(ArgumentError, "contacts must be a list")

  @doc """
  Builds a compact reduced-capacity pack summary for a contact allocation report.

  The helper is a focused view over `contact_allocation_report.v1` capacity-pack
  rows and reduced-capacity pack groups. It derives demand totals, selected and
  deferred routing, capacity requirement source maps, and pack review groups
  without reserving provider time, mutating schedules, or approving contacts.
  """
  def capacity_pack_summary(contact_allocation_report)

  def capacity_pack_summary(
        %{"schema_contract" => @capacity_pack_summary_schema_contract} = summary
      ),
      do: summary

  def capacity_pack_summary(%{"schema_contract" => @schema_contract} = report) do
    capacity_pack_summary(report, [])
  end

  def capacity_pack_summary(%{schema_contract: @capacity_pack_summary_schema_contract} = summary) do
    stringify_keys(summary)
  end

  def capacity_pack_summary(%{schema_contract: @schema_contract} = report) do
    report
    |> stringify_keys()
    |> capacity_pack_summary()
  end

  def capacity_pack_summary(_contact_allocation_report),
    do: raise(ArgumentError, "contact allocation report is required")

  def capacity_pack_summary(contact_allocation_report, opts)

  def capacity_pack_summary(
        %{"schema_contract" => @capacity_pack_summary_schema_contract} = summary,
        opts
      )
      when is_list(opts),
      do: summary

  def capacity_pack_summary(%{"schema_contract" => @schema_contract} = report, opts)
      when is_list(opts) do
    allocation_capacity_pack_summary(report, opts)
  end

  def capacity_pack_summary(
        %{schema_contract: @capacity_pack_summary_schema_contract} = summary,
        opts
      )
      when is_list(opts) do
    stringify_keys(summary)
  end

  def capacity_pack_summary(%{schema_contract: @schema_contract} = report, opts)
      when is_list(opts) do
    report
    |> stringify_keys()
    |> capacity_pack_summary(opts)
  end

  def capacity_pack_summary(_contact_allocation_report, _opts),
    do: raise(ArgumentError, "contact allocation report is required")

  def capacity_pack_summary(contacts, ground_network, opts) when is_list(contacts) do
    contacts
    |> report(ground_network, opts)
    |> capacity_pack_summary(opts)
  end

  def capacity_pack_summary(_contacts, _ground_network, _opts),
    do: raise(ArgumentError, "contacts must be a list")

  @doc """
  Builds a compact reservation-conflict summary for a contact allocation report.

  The helper is a focused view over `contact_allocation_report.v1` reservation
  rows. It identifies reservation overlaps that are not matched by reservation
  identity or owner, carries expiration/status/owner routing, and preserves the
  artifact-only no-provider-reservation boundary.
  """
  def reservation_conflict_summary(contact_allocation_report)

  def reservation_conflict_summary(
        %{"schema_contract" => @reservation_conflict_summary_schema_contract} = summary
      ),
      do: summary

  def reservation_conflict_summary(%{"schema_contract" => @schema_contract} = report) do
    reservation_conflict_summary(report, [])
  end

  def reservation_conflict_summary(
        %{schema_contract: @reservation_conflict_summary_schema_contract} = summary
      ) do
    stringify_keys(summary)
  end

  def reservation_conflict_summary(%{schema_contract: @schema_contract} = report) do
    report
    |> stringify_keys()
    |> reservation_conflict_summary()
  end

  def reservation_conflict_summary(_contact_allocation_report),
    do: raise(ArgumentError, "contact allocation report is required")

  def reservation_conflict_summary(contact_allocation_report, opts)

  def reservation_conflict_summary(
        %{"schema_contract" => @reservation_conflict_summary_schema_contract} = summary,
        opts
      )
      when is_list(opts),
      do: summary

  def reservation_conflict_summary(%{"schema_contract" => @schema_contract} = report, opts)
      when is_list(opts) do
    allocation_reservation_conflict_summary(report, opts)
  end

  def reservation_conflict_summary(
        %{schema_contract: @reservation_conflict_summary_schema_contract} = summary,
        opts
      )
      when is_list(opts) do
    stringify_keys(summary)
  end

  def reservation_conflict_summary(%{schema_contract: @schema_contract} = report, opts)
      when is_list(opts) do
    report
    |> stringify_keys()
    |> reservation_conflict_summary(opts)
  end

  def reservation_conflict_summary(_contact_allocation_report, _opts),
    do: raise(ArgumentError, "contact allocation report is required")

  def reservation_conflict_summary(contacts, ground_network, opts) when is_list(contacts) do
    contacts
    |> report(ground_network, opts)
    |> reservation_conflict_summary(opts)
  end

  def reservation_conflict_summary(_contacts, _ground_network, _opts),
    do: raise(ArgumentError, "contacts must be a list")

  @doc """
  Builds an artifact-only provider reservation request summary.

  The helper is a focused handoff view over allocated `contact_allocation_report.v1`
  rows with station-reservation evidence. It separates identity/owner-matched
  reservations that are ready for provider-request review from allocated
  reservation overlaps that still require operator review, without reserving
  provider time, mutating schedules, or approving contacts.
  """
  def provider_reservation_request_summary(contact_allocation_report)

  def provider_reservation_request_summary(
        %{"schema_contract" => @provider_reservation_request_summary_schema_contract} = summary
      ),
      do: summary

  def provider_reservation_request_summary(%{"schema_contract" => @schema_contract} = report) do
    provider_reservation_request_summary(report, [])
  end

  def provider_reservation_request_summary(
        %{schema_contract: @provider_reservation_request_summary_schema_contract} = summary
      ) do
    stringify_keys(summary)
  end

  def provider_reservation_request_summary(%{schema_contract: @schema_contract} = report) do
    report
    |> stringify_keys()
    |> provider_reservation_request_summary()
  end

  def provider_reservation_request_summary(_contact_allocation_report),
    do: raise(ArgumentError, "contact allocation report is required")

  def provider_reservation_request_summary(contact_allocation_report, opts)

  def provider_reservation_request_summary(
        %{"schema_contract" => @provider_reservation_request_summary_schema_contract} = summary,
        opts
      )
      when is_list(opts),
      do: summary

  def provider_reservation_request_summary(
        %{"schema_contract" => @schema_contract} = report,
        opts
      )
      when is_list(opts) do
    allocation_provider_reservation_request_summary(report, opts)
  end

  def provider_reservation_request_summary(
        %{schema_contract: @provider_reservation_request_summary_schema_contract} = summary,
        opts
      )
      when is_list(opts) do
    stringify_keys(summary)
  end

  def provider_reservation_request_summary(%{schema_contract: @schema_contract} = report, opts)
      when is_list(opts) do
    report
    |> stringify_keys()
    |> provider_reservation_request_summary(opts)
  end

  def provider_reservation_request_summary(_contact_allocation_report, _opts),
    do: raise(ArgumentError, "contact allocation report is required")

  def provider_reservation_request_summary(contacts, ground_network, opts)
      when is_list(contacts) do
    contacts
    |> report(ground_network, opts)
    |> provider_reservation_request_summary(opts)
  end

  def provider_reservation_request_summary(_contacts, _ground_network, _opts),
    do: raise(ArgumentError, "contacts must be a list")

  defp allocation_summary(report, opts) do
    report = stringify_keys(report)
    now_s = Keyword.get(opts, :now_s)

    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&normalize_station_calendar_status_fields/1)
      |> Enum.map(&ensure_effective_allocation_status/1)

    review_rows = Enum.filter(rows, &allocation_summary_review_row?/1)
    station_pressure_rows = station_pressure_summary_rows(rows)

    station_pressure_contact_ids_by_ground_station_id =
      contact_ids_by_field(station_pressure_rows, "ground_station_id")

    station_pressure_contact_ids_by_availability =
      station_pressure_contact_ids_by_availability(station_pressure_rows)

    station_pressure_contact_ids_by_precedence_availability =
      contact_ids_by_field(station_pressure_rows, "station_calendar_precedence_availability")

    station_pressure_contact_ids_by_precedence_rank =
      contact_ids_by_string_field(station_pressure_rows, "station_calendar_precedence_rank")

    station_pressure_contact_ids_by_status =
      contact_ids_by_field(station_pressure_rows, "station_calendar_status")

    station_pressure_contact_ids_by_direction_and_ground_station_id =
      contact_ids_by_direction_and_ground_station_id(station_pressure_rows)

    capacity_pack_rows = capacity_pack_summary_rows(rows)
    selected_capacity_pack_rows = selected_capacity_pack_summary_rows(capacity_pack_rows)
    deferred_capacity_pack_rows = deferred_capacity_pack_summary_rows(capacity_pack_rows)
    reservation_expiration_rows = station_reservation_expiration_summary_rows(rows, now_s)

    %{
      "schema_contract" => @summary_schema_contract,
      "model" => "artifact_only_contact_allocation_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @schema_contract),
      "source" => report["source"],
      "input_contact_count" => length(rows),
      "allocated_contact_count" =>
        allocation_summary_count(rows, "allocation_status", "allocated"),
      "returned_allocated_contact_count" =>
        allocation_summary_count(rows, "effective_allocation_status", "allocated"),
      "policy_blocked_allocated_contact_count" =>
        allocation_summary_count(rows, "effective_allocation_status", "policy_blocked"),
      "deferred_contact_count" => allocation_summary_count(rows, "allocation_status", "deferred"),
      "blocked_contact_count" => allocation_summary_count(rows, "allocation_status", "blocked"),
      "invalid_contact_input_count" => invalid_allocation_input_count(rows),
      "status_blocked_contact_count" => status_blocked_allocation_count(rows),
      "resource_blocked_contact_count" => resource_blocked_contact_count(rows),
      "duplicate_contact_id_count" => duplicate_contact_group_count(rows),
      "reduced_capacity_pack_group_count" => length(report["reduced_capacity_pack_groups"] || []),
      "reduced_capacity_pack_status_counts" =>
        count_by(report["reduced_capacity_pack_groups"] || [], "pack_status"),
      "allocation_status_counts" => count_by(rows, "allocation_status"),
      "effective_allocation_status_counts" => count_by(rows, "effective_allocation_status"),
      "allocation_reason_counts" => count_by(rows, "allocation_reason"),
      "contact_ids_by_allocation_reason" => contact_ids_by_field(rows, "allocation_reason"),
      "capacity_pack_status_counts" => count_by(rows, "capacity_pack_status"),
      "capacity_pack_required_capacity_fraction" =>
        capacity_pack_required_fraction(capacity_pack_rows),
      "capacity_pack_selected_required_capacity_fraction" =>
        capacity_pack_required_fraction(selected_capacity_pack_rows),
      "capacity_pack_deferred_required_capacity_fraction" =>
        capacity_pack_required_fraction(deferred_capacity_pack_rows),
      "capacity_pack_required_capacity_fraction_by_status" =>
        capacity_pack_required_fraction_by_field(capacity_pack_rows, "capacity_pack_status"),
      "required_capacity_fraction_source_counts" =>
        count_by(rows, "required_capacity_fraction_source"),
      "station_reservation_match_status_counts" =>
        count_by(rows, "station_reservation_match_status"),
      "station_reservation_status_counts" => count_by(rows, "station_reservation_status"),
      "station_reserved_by_counts" => count_by(rows, "station_reserved_by"),
      "station_reservation_ids" => row_values(rows, "station_reservation_id"),
      "station_reservation_expires_at_s" => row_values(rows, "station_reservation_expires_at_s"),
      "station_reservation_expiration_now_s" => now_s,
      "station_reservation_expiration_status_counts" =>
        station_reservation_expiration_status_counts(reservation_expiration_rows),
      "station_reservation_active_contact_count" =>
        station_reservation_expiration_count(reservation_expiration_rows, "active"),
      "station_reservation_expired_contact_count" =>
        station_reservation_expiration_count(reservation_expiration_rows, "expired"),
      "station_reservation_missing_expiration_contact_count" =>
        station_reservation_expiration_count(reservation_expiration_rows, "missing"),
      "station_reservation_declared_expiration_contact_count" =>
        station_reservation_expiration_count(reservation_expiration_rows, "declared"),
      "earliest_station_reservation_expires_at_s" =>
        earliest_station_reservation_expires_at_s(reservation_expiration_rows),
      "station_calendar_trust_boundary_status_counts" =>
        station_calendar_trust_boundary_status_counts(rows) || %{},
      "calendar_entry_trust_boundary_status_counts" =>
        report["calendar_entry_trust_boundary_status_counts"] || %{},
      "resource_blocking_dimension_counts" =>
        contact_id_count_map(resource_blocked_summary_rows(rows), "resource_blocking_dimension"),
      "allocated_contact_ids" =>
        allocation_summary_contact_ids(rows, "allocation_status", "allocated"),
      "allocated_contact_ids_by_ground_station_id" =>
        allocation_summary_contact_ids_by_station(rows, "allocation_status", "allocated"),
      "returned_allocated_contact_ids" =>
        rows
        |> Enum.filter(&(&1["effective_allocation_status"] == "allocated"))
        |> row_contact_ids(),
      "returned_allocated_contact_ids_by_ground_station_id" =>
        allocation_summary_contact_ids_by_station(
          rows,
          "effective_allocation_status",
          "allocated"
        ),
      "deferred_contact_ids" =>
        allocation_summary_contact_ids(rows, "allocation_status", "deferred"),
      "deferred_contact_ids_by_ground_station_id" =>
        allocation_summary_contact_ids_by_station(rows, "allocation_status", "deferred"),
      "blocked_contact_ids" =>
        allocation_summary_contact_ids(rows, "allocation_status", "blocked"),
      "blocked_contact_ids_by_ground_station_id" =>
        allocation_summary_contact_ids_by_station(rows, "allocation_status", "blocked"),
      "policy_blocked_contact_ids" =>
        allocation_summary_contact_ids(rows, "effective_allocation_status", "policy_blocked"),
      "policy_blocked_contact_ids_by_ground_station_id" =>
        allocation_summary_contact_ids_by_station(
          rows,
          "effective_allocation_status",
          "policy_blocked"
        ),
      "invalid_contact_input_ids" => invalid_allocation_input_ids(rows),
      "status_blocked_contact_ids" => status_blocked_allocation_ids(rows),
      "resource_blocked_contact_ids" => resource_blocked_summary_rows(rows) |> row_contact_ids(),
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        contact_ids_by_field(resource_blocked_summary_rows(rows), "resource_blocking_dimension"),
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        contact_ids_by_field(resource_blocked_summary_rows(rows), "spacecraft_id"),
      "station_pressure_contact_ids_by_ground_station_id" =>
        station_pressure_contact_ids_by_ground_station_id,
      "station_pressure_contact_counts_by_ground_station_id" =>
        id_set_count_map(station_pressure_contact_ids_by_ground_station_id),
      "station_pressure_contact_ids_by_availability" =>
        station_pressure_contact_ids_by_availability,
      "station_pressure_contact_counts_by_availability" =>
        id_set_count_map(station_pressure_contact_ids_by_availability),
      "station_pressure_contact_ids_by_precedence_availability" =>
        station_pressure_contact_ids_by_precedence_availability,
      "station_pressure_contact_counts_by_precedence_availability" =>
        id_set_count_map(station_pressure_contact_ids_by_precedence_availability),
      "station_pressure_contact_ids_by_precedence_rank" =>
        station_pressure_contact_ids_by_precedence_rank,
      "station_pressure_contact_counts_by_precedence_rank" =>
        id_set_count_map(station_pressure_contact_ids_by_precedence_rank),
      "station_pressure_contact_ids_by_status" => station_pressure_contact_ids_by_status,
      "station_pressure_contact_counts_by_status" =>
        id_set_count_map(station_pressure_contact_ids_by_status),
      "station_pressure_contact_ids_by_direction_and_ground_station_id" =>
        station_pressure_contact_ids_by_direction_and_ground_station_id,
      "station_reservation_contact_ids_by_match_status" =>
        contact_ids_by_field(rows, "station_reservation_match_status"),
      "station_reservation_contact_ids_by_status" =>
        contact_ids_by_field(rows, "station_reservation_status"),
      "station_reservation_contact_ids_by_reserved_by" =>
        contact_ids_by_field(rows, "station_reserved_by"),
      "station_reservation_ids_by_match_status" =>
        ids_by_field(rows, "station_reservation_match_status", "station_reservation_id"),
      "station_reservation_ids_by_status" =>
        ids_by_field(rows, "station_reservation_status", "station_reservation_id"),
      "station_reservation_ids_by_reserved_by" =>
        ids_by_field(rows, "station_reserved_by", "station_reservation_id"),
      "station_reservation_contact_ids_by_expiration_status" =>
        station_reservation_contact_ids_by_expiration_status(reservation_expiration_rows),
      "station_reservation_ids_by_expiration_status" =>
        station_reservation_ids_by_expiration_status(reservation_expiration_rows),
      "capacity_pack_contact_ids_by_status" => contact_ids_by_field(rows, "capacity_pack_status"),
      "capacity_pack_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(capacity_pack_rows, "ground_station_id"),
      "capacity_pack_selected_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(selected_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_deferred_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(deferred_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(capacity_pack_rows, "ground_station_id"),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(selected_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(deferred_capacity_pack_rows, "ground_station_id"),
      "required_capacity_fraction_contact_ids_by_source" =>
        contact_ids_by_field(rows, "required_capacity_fraction_source"),
      "reduced_capacity_packed_contact_ids" =>
        allocation_summary_contact_ids(
          rows,
          "capacity_pack_status",
          "selected_by_reduced_station_capacity_pack"
        ),
      "reduced_capacity_deferred_contact_ids" =>
        allocation_summary_contact_ids(
          rows,
          "capacity_pack_status",
          "deferred_by_reduced_station_capacity_pack"
        ),
      "rows" => rows,
      "review_contact_ids" => row_contact_ids(review_rows),
      "review_row_count" => length(review_rows),
      "review_rows" => review_rows,
      "reduced_capacity_pack_groups" => report["reduced_capacity_pack_groups"] || [],
      "model_limits" => model_limits(),
      "assumptions" =>
        Map.merge(
          %{
            "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
            "source" => "contact_allocation_report.v1",
            "operator_authority" => "not_granted_by_summary"
          },
          allocation_summary_capability_assumptions()
        )
    }
    |> compact_map()
  end

  defp allocation_station_pressure_summary(report, _opts) do
    report = stringify_keys(report)

    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&normalize_station_calendar_status_fields/1)

    station_pressure_rows = station_pressure_summary_rows(rows)

    contact_ids_by_ground_station_id =
      contact_ids_by_field(station_pressure_rows, "ground_station_id")

    contact_ids_by_availability =
      station_pressure_contact_ids_by_availability(station_pressure_rows)

    contact_ids_by_precedence_availability =
      contact_ids_by_field(station_pressure_rows, "station_calendar_precedence_availability")

    contact_ids_by_precedence_rank =
      contact_ids_by_string_field(station_pressure_rows, "station_calendar_precedence_rank")

    contact_ids_by_status =
      contact_ids_by_field(station_pressure_rows, "station_calendar_status")

    contact_ids_by_direction_and_ground_station_id =
      contact_ids_by_direction_and_ground_station_id(station_pressure_rows)

    review_rows = Enum.filter(station_pressure_rows, &allocation_summary_review_row?/1)

    %{
      "schema_contract" => @station_pressure_summary_schema_contract,
      "model" => "artifact_only_contact_allocation_station_pressure_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @schema_contract),
      "source" => report["source"],
      "input_contact_count" => length(rows),
      "station_pressure_contact_count" => length(station_pressure_rows),
      "station_pressure_review_contact_count" => length(review_rows),
      "station_pressure_contact_ids" => row_contact_ids(station_pressure_rows),
      "station_pressure_review_contact_ids" => row_contact_ids(review_rows),
      "station_pressure_contact_ids_by_ground_station_id" => contact_ids_by_ground_station_id,
      "station_pressure_contact_counts_by_ground_station_id" =>
        id_set_count_map(contact_ids_by_ground_station_id),
      "station_pressure_contact_ids_by_availability" => contact_ids_by_availability,
      "station_pressure_contact_counts_by_availability" =>
        id_set_count_map(contact_ids_by_availability),
      "station_pressure_contact_ids_by_precedence_availability" =>
        contact_ids_by_precedence_availability,
      "station_pressure_contact_counts_by_precedence_availability" =>
        id_set_count_map(contact_ids_by_precedence_availability),
      "station_pressure_contact_ids_by_precedence_rank" => contact_ids_by_precedence_rank,
      "station_pressure_contact_counts_by_precedence_rank" =>
        id_set_count_map(contact_ids_by_precedence_rank),
      "station_pressure_contact_ids_by_status" => contact_ids_by_status,
      "station_pressure_contact_counts_by_status" => id_set_count_map(contact_ids_by_status),
      "station_pressure_contact_ids_by_direction_and_ground_station_id" =>
        contact_ids_by_direction_and_ground_station_id,
      "rows" => rows,
      "review_rows" => review_rows,
      "model_limits" => model_limits(),
      "assumptions" =>
        Map.merge(
          %{
            "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
            "source" => "contact_allocation_report.v1",
            "operator_authority" => "not_granted_by_station_pressure_summary"
          },
          station_pressure_capability_assumptions()
        )
    }
    |> compact_map()
  end

  defp allocation_capacity_pack_summary(report, _opts) do
    report = stringify_keys(report)

    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&normalize_station_calendar_status_fields/1)

    capacity_pack_rows = capacity_pack_summary_rows(rows)
    selected_capacity_pack_rows = selected_capacity_pack_summary_rows(capacity_pack_rows)
    deferred_capacity_pack_rows = deferred_capacity_pack_summary_rows(capacity_pack_rows)
    pack_groups = report["reduced_capacity_pack_groups"] || []

    %{
      "schema_contract" => @capacity_pack_summary_schema_contract,
      "model" => "artifact_only_contact_allocation_capacity_pack_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @schema_contract),
      "source" => report["source"],
      "input_contact_count" => length(rows),
      "capacity_pack_contact_count" => length(capacity_pack_rows),
      "capacity_pack_review_status" =>
        if(capacity_pack_rows == [] and pack_groups == [], do: "clear", else: "review_required"),
      "reduced_capacity_pack_group_count" => length(pack_groups),
      "reduced_capacity_pack_status_counts" => count_by(pack_groups, "pack_status"),
      "capacity_pack_status_counts" => count_by(capacity_pack_rows, "capacity_pack_status"),
      "capacity_pack_contact_ids_by_status" =>
        contact_ids_by_field(capacity_pack_rows, "capacity_pack_status"),
      "capacity_pack_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(capacity_pack_rows, "ground_station_id"),
      "capacity_pack_selected_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(selected_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_deferred_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(deferred_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_required_capacity_fraction" =>
        capacity_pack_required_fraction(capacity_pack_rows),
      "capacity_pack_selected_required_capacity_fraction" =>
        capacity_pack_required_fraction(selected_capacity_pack_rows),
      "capacity_pack_deferred_required_capacity_fraction" =>
        capacity_pack_required_fraction(deferred_capacity_pack_rows),
      "capacity_pack_required_capacity_fraction_by_status" =>
        capacity_pack_required_fraction_by_field(capacity_pack_rows, "capacity_pack_status"),
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(capacity_pack_rows, "ground_station_id"),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(selected_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_required_fraction_by_field(deferred_capacity_pack_rows, "ground_station_id"),
      "capacity_pack_required_capacity_fraction_by_direction" =>
        capacity_pack_required_fraction_by_field(capacity_pack_rows, "direction"),
      "capacity_pack_selected_required_capacity_fraction_by_direction" =>
        capacity_pack_required_fraction_by_field(selected_capacity_pack_rows, "direction"),
      "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
        capacity_pack_required_fraction_by_field(deferred_capacity_pack_rows, "direction"),
      "required_capacity_fraction_source_counts" =>
        count_by(capacity_pack_rows, "required_capacity_fraction_source"),
      "required_capacity_fraction_contact_ids_by_source" =>
        contact_ids_by_field(capacity_pack_rows, "required_capacity_fraction_source"),
      "capacity_pack_contact_ids_by_direction" =>
        contact_ids_by_field(capacity_pack_rows, "direction"),
      "capacity_pack_selected_contact_ids_by_direction" =>
        contact_ids_by_field(selected_capacity_pack_rows, "direction"),
      "capacity_pack_deferred_contact_ids_by_direction" =>
        contact_ids_by_field(deferred_capacity_pack_rows, "direction"),
      "reduced_capacity_packed_contact_ids" =>
        allocation_summary_contact_ids(
          capacity_pack_rows,
          "capacity_pack_status",
          "selected_by_reduced_station_capacity_pack"
        ),
      "reduced_capacity_deferred_contact_ids" =>
        allocation_summary_contact_ids(
          capacity_pack_rows,
          "capacity_pack_status",
          "deferred_by_reduced_station_capacity_pack"
        ),
      "capacity_pack_group_ids" => row_values(pack_groups, "contention_group_id"),
      "capacity_pack_group_ids_by_status" =>
        ids_by_field(pack_groups, "pack_status", "contention_group_id"),
      "rows" => rows,
      "reduced_capacity_pack_groups" => pack_groups,
      "review_rows" => capacity_pack_rows,
      "model_limits" => model_limits(),
      "assumptions" =>
        Map.merge(
          %{
            "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
            "source" => "contact_allocation_report.v1",
            "operator_authority" => "not_granted_by_capacity_pack_summary"
          },
          capacity_pack_capability_assumptions()
        )
    }
    |> compact_map()
  end

  defp allocation_reservation_conflict_summary(report, opts) do
    report = stringify_keys(report)
    now_s = Keyword.get(opts, :now_s)

    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&normalize_station_calendar_status_fields/1)

    reservation_rows = Enum.filter(rows, &station_reservation_summary_row?/1)
    conflict_rows = Enum.filter(reservation_rows, &reservation_conflict_row?/1)
    review_rows = Enum.filter(reservation_rows, &allocation_summary_review_row?/1)
    expiration_rows = station_reservation_expiration_summary_rows(reservation_rows, now_s)

    conflict_contact_ids_by_direction_and_ground_station_id =
      contact_ids_by_direction_and_ground_station_id(conflict_rows)

    %{
      "schema_contract" => @reservation_conflict_summary_schema_contract,
      "model" => "artifact_only_contact_allocation_reservation_conflict_summary",
      "model_limits" => model_limits(),
      "source_artifact_type" => Map.get(report, "schema_contract", @schema_contract),
      "source" => report["source"],
      "input_contact_count" => length(rows),
      "station_reservation_contact_count" => length(reservation_rows),
      "reservation_conflict_contact_count" => length(conflict_rows),
      "reservation_review_contact_count" => length(review_rows),
      "station_reservation_match_status_counts" =>
        count_by(reservation_rows, "station_reservation_match_status"),
      "reservation_conflict_match_status_counts" =>
        count_by(conflict_rows, "station_reservation_match_status"),
      "station_reservation_status_counts" =>
        count_by(reservation_rows, "station_reservation_status"),
      "station_reserved_by_counts" => count_by(reservation_rows, "station_reserved_by"),
      "station_reservation_ids" => row_values(reservation_rows, "station_reservation_id"),
      "station_reservation_expires_at_s" =>
        row_values(reservation_rows, "station_reservation_expires_at_s"),
      "station_reservation_expiration_now_s" => now_s,
      "station_reservation_expiration_status_counts" =>
        station_reservation_expiration_status_counts(expiration_rows),
      "earliest_station_reservation_expires_at_s" =>
        earliest_station_reservation_expires_at_s(expiration_rows),
      "reservation_conflict_contact_ids" => row_contact_ids(conflict_rows),
      "reservation_review_contact_ids" => row_contact_ids(review_rows),
      "station_reservation_contact_ids_by_match_status" =>
        contact_ids_by_field(reservation_rows, "station_reservation_match_status"),
      "reservation_conflict_contact_ids_by_match_status" =>
        contact_ids_by_field(conflict_rows, "station_reservation_match_status"),
      "reservation_conflict_contact_ids_by_direction" => contact_ids_by_direction(conflict_rows),
      "reservation_conflict_contact_ids_by_direction_and_ground_station_id" =>
        conflict_contact_ids_by_direction_and_ground_station_id,
      "station_reservation_contact_ids_by_status" =>
        contact_ids_by_field(reservation_rows, "station_reservation_status"),
      "station_reservation_contact_ids_by_reserved_by" =>
        contact_ids_by_field(reservation_rows, "station_reserved_by"),
      "station_reservation_contact_ids_by_expiration_status" =>
        station_reservation_contact_ids_by_expiration_status(expiration_rows),
      "station_reservation_ids_by_match_status" =>
        ids_by_field(
          reservation_rows,
          "station_reservation_match_status",
          "station_reservation_id"
        ),
      "reservation_conflict_reservation_ids_by_match_status" =>
        ids_by_field(conflict_rows, "station_reservation_match_status", "station_reservation_id"),
      "station_reservation_ids_by_status" =>
        ids_by_field(reservation_rows, "station_reservation_status", "station_reservation_id"),
      "station_reservation_ids_by_reserved_by" =>
        ids_by_field(reservation_rows, "station_reserved_by", "station_reservation_id"),
      "station_reservation_ids_by_expiration_status" =>
        station_reservation_ids_by_expiration_status(expiration_rows),
      "rows" => rows,
      "reservation_conflict_rows" => conflict_rows,
      "reservation_review_rows" => review_rows,
      "assumptions" =>
        Map.merge(
          %{
            "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
            "source" => "contact_allocation_report.v1",
            "operator_authority" => "not_granted_by_reservation_conflict_summary"
          },
          reservation_conflict_capability_assumptions()
        )
    }
    |> compact_map()
  end

  defp allocation_provider_reservation_request_summary(report, _opts) do
    report = stringify_keys(report)

    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&normalize_station_calendar_status_fields/1)
      |> Enum.map(&ensure_effective_allocation_status/1)

    reservation_candidate_rows =
      Enum.filter(rows, &provider_reservation_request_candidate_row?/1)

    request_rows =
      Enum.filter(reservation_candidate_rows, &provider_reservation_request_ready_row?/1)

    review_rows = reservation_candidate_rows -- request_rows

    no_request_rows =
      Enum.reject(rows, &provider_reservation_request_candidate_row?/1)

    %{
      "schema_contract" => @provider_reservation_request_summary_schema_contract,
      "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
      "model_limits" => model_limits(),
      "source_artifact_type" => Map.get(report, "schema_contract", @schema_contract),
      "source" => report["source"],
      "input_contact_count" => length(rows),
      "provider_reservation_candidate_contact_count" => length(reservation_candidate_rows),
      "provider_reservation_request_contact_count" => length(request_rows),
      "provider_reservation_review_contact_count" => length(review_rows),
      "provider_reservation_no_request_contact_count" =>
        length(rows) - length(reservation_candidate_rows),
      "provider_reservation_request_status" =>
        provider_reservation_request_status(request_rows, review_rows),
      "provider_reservation_request_contact_ids" => row_contact_ids(request_rows),
      "provider_reservation_review_contact_ids" => row_contact_ids(review_rows),
      "provider_reservation_no_request_contact_ids" => row_contact_ids(no_request_rows),
      "provider_reservation_request_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(request_rows, "ground_station_id"),
      "provider_reservation_review_contact_ids_by_ground_station_id" =>
        contact_ids_by_field(review_rows, "ground_station_id"),
      "provider_reservation_no_request_contact_ids_by_direction" =>
        contact_ids_by_field(no_request_rows, "direction"),
      "provider_reservation_request_contact_ids_by_direction" =>
        contact_ids_by_field(request_rows, "direction"),
      "provider_reservation_review_contact_ids_by_direction" =>
        contact_ids_by_field(review_rows, "direction"),
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" =>
        contact_ids_by_direction_and_ground_station_id(no_request_rows),
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id" =>
        contact_ids_by_direction_and_ground_station_id(request_rows),
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id" =>
        contact_ids_by_direction_and_ground_station_id(review_rows),
      "provider_reservation_request_contact_ids_by_match_status" =>
        contact_ids_by_field(request_rows, "station_reservation_match_status"),
      "provider_reservation_review_contact_ids_by_match_status" =>
        contact_ids_by_field(review_rows, "station_reservation_match_status"),
      "provider_reservation_request_ids_by_match_status" =>
        ids_by_field(request_rows, "station_reservation_match_status", "station_reservation_id"),
      "provider_reservation_review_ids_by_match_status" =>
        ids_by_field(review_rows, "station_reservation_match_status", "station_reservation_id"),
      "rows" => rows,
      "provider_reservation_request_rows" => request_rows,
      "provider_reservation_review_rows" => review_rows,
      "assumptions" =>
        Map.merge(
          %{
            "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
            "source" => "contact_allocation_report.v1",
            "provider_reservation_execution" => "not_performed_by_summary",
            "operator_authority" => "not_granted_by_provider_reservation_request_summary"
          },
          provider_reservation_request_capability_assumptions()
        )
    }
    |> compact_map()
  end

  defp provider_reservation_request_status(_request_rows, review_rows) when review_rows != [],
    do: "review_required"

  defp provider_reservation_request_status(request_rows, _review_rows) when request_rows != [],
    do: "request_ready"

  defp provider_reservation_request_status(_request_rows, _review_rows), do: "clear"

  defp ensure_effective_allocation_status(%{"effective_allocation_status" => status} = row)
       when is_binary(status),
       do: row

  defp ensure_effective_allocation_status(row), do: put_effective_allocation_status(row)

  defp reservation_conflict_row?(row) do
    station_pressure_value?(row["station_reservation_match_status"]) and
      row["station_reservation_match_status"] not in ["matched", "owner_matched"]
  end

  defp provider_reservation_request_ready_row?(row) do
    row["station_reservation_match_status"] in ["matched", "owner_matched"] and
      station_reservation_summary_ids(row) != []
  end

  defp provider_reservation_request_candidate_row?(row) do
    row["allocation_status"] == "allocated" and
      row["effective_allocation_status"] in [nil, "allocated"] and
      station_reservation_summary_row?(row)
  end

  defp station_reservation_summary_row?(row) do
    station_reservation_expiration_summary_row?(row)
  end

  defp resource_blocked_summary_rows(rows) do
    Enum.filter(rows, &Map.has_key?(&1, "source_resource_suppression"))
  end

  defp capacity_pack_summary_rows(rows) do
    Enum.filter(rows, fn row ->
      is_binary(row["capacity_pack_status"]) and is_number(row["required_capacity_fraction"])
    end)
  end

  defp selected_capacity_pack_summary_rows(rows) do
    Enum.filter(rows, fn row ->
      row["capacity_pack_status"] in [
        "selected_by_contention_resolution",
        "selected_by_reduced_station_capacity_pack"
      ]
    end)
  end

  defp deferred_capacity_pack_summary_rows(rows) do
    Enum.filter(
      rows,
      &(&1["capacity_pack_status"] == "deferred_by_reduced_station_capacity_pack")
    )
  end

  defp capacity_pack_required_fraction(rows) do
    rows
    |> Enum.map(&numeric_or_nil(&1["required_capacity_fraction"]))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp capacity_pack_required_fraction_by_field(rows, field) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      field_value = stable_id_or_nil(row[field]) || normalized_status_token(row[field])
      required_fraction = numeric_or_nil(row["required_capacity_fraction"])

      if is_nil(field_value) or is_nil(required_fraction) do
        totals
      else
        Map.update(totals, field_value, required_fraction, &(&1 + required_fraction))
      end
    end)
  end

  defp allocation_summary_count(rows, field, value) do
    Enum.count(rows, &(Map.get(&1, field) == value))
  end

  defp invalid_allocation_input_count(rows) do
    Enum.count(rows, &(&1["invalid_contact_input"] == true))
  end

  defp invalid_allocation_input_ids(rows) do
    rows
    |> Enum.filter(&(&1["invalid_contact_input"] == true))
    |> row_contact_ids()
  end

  defp status_blocked_allocation_count(rows) do
    Enum.count(rows, &status_blocked_allocation_row?/1)
  end

  defp status_blocked_allocation_ids(rows) do
    rows
    |> Enum.filter(&status_blocked_allocation_row?/1)
    |> row_contact_ids()
  end

  defp status_blocked_allocation_row?(row) do
    reason = row["allocation_reason"]

    is_binary(reason) and
      (String.starts_with?(reason, "activity_status_") or
         String.starts_with?(reason, "approval_status_"))
  end

  defp duplicate_contact_group_count(rows) do
    rows
    |> Enum.filter(&(&1["duplicate_contact_id_collision"] == true))
    |> Enum.map(& &1["contact_id"])
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> length()
  end

  defp station_pressure_summary_rows(rows) do
    Enum.filter(rows, fn row ->
      station_pressure_value?(row["station_calendar_overlap_count"]) or
        station_pressure_value?(row["station_calendar_overlap_availabilities"]) or
        station_pressure_value?(row["station_calendar_entry_id"]) or
        station_pressure_value?(row["station_reservation_match_status"]) or
        station_pressure_value?(row["station_calendar_precedence_rank"]) or
        station_pressure_value?(row["station_calendar_precedence_availability"]) or
        source_station_calendar_pressure_values(row) != []
    end)
  end

  defp station_pressure_value?(nil), do: false
  defp station_pressure_value?([]), do: false
  defp station_pressure_value?(value) when is_number(value), do: value > 0
  defp station_pressure_value?(value) when is_binary(value), do: value != ""
  defp station_pressure_value?(_value), do: true

  defp allocation_summary_contact_ids(rows, field, value) do
    rows
    |> Enum.filter(&(Map.get(&1, field) == value))
    |> row_contact_ids()
  end

  defp row_contact_ids(rows) do
    rows
    |> Enum.map(& &1["contact_id"])
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_pressure_contact_ids_by_availability(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> station_pressure_availability_values()
      |> Enum.map(&{&1, row["contact_id"]})
    end)
    |> Enum.group_by(fn {availability, _contact_id} -> availability end, fn {_availability,
                                                                             contact_id} ->
      contact_id
    end)
    |> Enum.reject(fn {availability, contact_ids} ->
      is_nil(availability) or Enum.all?(contact_ids, &is_nil/1)
    end)
    |> Map.new(fn {availability, contact_ids} ->
      {availability, sorted_stable_ids(contact_ids)}
    end)
  end

  defp station_pressure_availability_values(row) do
    direct_values =
      row
      |> Map.take(["station_availability", "availability", "station_calendar_status"])
      |> Map.values()

    source_values =
      source_station_calendar_availability_candidates(row["source_station_calendar_entry"]) ++
        source_station_calendar_availability_candidates(row["source_station_calendar_overlaps"])

    (direct_values ++ List.wrap(row["station_calendar_overlap_availabilities"]) ++ source_values)
    |> Enum.map(&normalized_status_token/1)
    |> Enum.filter(&station_availability_value?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp source_station_calendar_pressure_values(row) do
    (source_station_calendar_availability_candidates(row["source_station_calendar_entry"]) ++
       source_station_calendar_availability_candidates(row["source_station_calendar_overlaps"]))
    |> Enum.map(&normalized_status_token/1)
    |> Enum.filter(&station_pressure_availability_value?/1)
    |> Enum.uniq()
  end

  defp station_pressure_availability_value?(value)
       when value in ["unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp station_pressure_availability_value?(_value), do: false

  defp contact_ids_by_field(rows, field) do
    ids_by_field(rows, field, "contact_id")
  end

  defp contact_ids_by_string_field(rows, field) do
    rows
    |> contact_ids_by_field(field)
    |> Map.new(fn {field_value, contact_ids} -> {to_string(field_value), contact_ids} end)
  end

  defp contact_ids_by_direction(rows) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      direction = normalize_direction(row["direction"] || row["type"])
      contact_id = row["contact_id"]

      if direction in [nil, ""] or contact_id in [nil, ""] do
        acc
      else
        Map.update(acc, direction, [contact_id], fn contact_ids -> [contact_id | contact_ids] end)
      end
    end)
    |> Map.new(fn {direction, contact_ids} -> {direction, sorted_stable_ids(contact_ids)} end)
  end

  defp allocation_summary_contact_ids_by_station(rows, status_field, status) do
    rows
    |> Enum.filter(&(&1[status_field] == status))
    |> contact_ids_by_field("ground_station_id")
  end

  defp ids_by_field(rows, field, id_field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1[id_field])
    |> Enum.reject(fn {field_value, ids} ->
      is_nil(field_value) or Enum.all?(ids, &is_nil/1)
    end)
    |> Map.new(fn {field_value, ids} -> {field_value, sorted_stable_ids(ids)} end)
  end

  defp contact_ids_by_direction_and_ground_station_id(rows) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      direction = normalize_direction(row["direction"] || row["type"])
      ground_station_id = row["ground_station_id"]
      contact_id = row["contact_id"]

      if direction in [nil, ""] or ground_station_id in [nil, ""] or contact_id in [nil, ""] do
        acc
      else
        Map.update(acc, direction, %{ground_station_id => [contact_id]}, fn station_map ->
          Map.update(station_map, ground_station_id, [contact_id], fn contact_ids ->
            [contact_id | contact_ids]
          end)
        end)
      end
    end)
    |> Map.new(fn {direction, station_map} ->
      {direction,
       Map.new(station_map, fn {station_id, contact_ids} ->
         {station_id, sorted_stable_ids(contact_ids)}
       end)}
    end)
  end

  defp contact_id_count_map(rows, field) do
    rows
    |> contact_ids_by_field(field)
    |> Map.new(fn {field_value, contact_ids} -> {field_value, length(contact_ids)} end)
  end

  defp id_set_count_map(id_sets) do
    Map.new(id_sets, fn {field_value, ids} -> {field_value, length(ids)} end)
  end

  defp sorted_stable_ids(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_reservation_expiration_summary_rows(rows, now_s) do
    now_s = numeric_or_nil(now_s)

    rows
    |> Enum.filter(&station_reservation_expiration_summary_row?/1)
    |> Enum.map(fn row ->
      expires_at_s = station_reservation_summary_expires_at_s(row)

      row
      |> Map.put("station_reservation_summary_expires_at_s", expires_at_s)
      |> Map.put(
        "station_reservation_expiration_status",
        station_reservation_expiration_status(expires_at_s, now_s)
      )
    end)
  end

  defp station_reservation_expiration_summary_row?(row) do
    Enum.any?(
      [
        row["station_reservation_id"],
        row["station_reservation_status"],
        row["station_reserved_by"],
        row["station_reservation_match_status"],
        row["station_reservation_expires_at_s"],
        row["station_calendar_reservation_ids"],
        row["station_calendar_reservation_statuses"],
        row["station_calendar_reserved_by"],
        row["station_calendar_reservation_expires_at_s"]
      ],
      &station_pressure_value?/1
    )
  end

  defp station_reservation_summary_expires_at_s(row) do
    [
      row["station_reservation_expires_at_s"],
      row["station_calendar_reservation_expires_at_s"]
    ]
    |> List.flatten()
    |> Enum.find_value(&numeric_or_nil/1)
  end

  defp station_reservation_expiration_status(nil, _now_s), do: "missing"
  defp station_reservation_expiration_status(_expires_at_s, nil), do: "declared"

  defp station_reservation_expiration_status(expires_at_s, now_s)
       when expires_at_s <= now_s,
       do: "expired"

  defp station_reservation_expiration_status(_expires_at_s, _now_s), do: "active"

  defp station_reservation_expiration_status_counts(rows) do
    count_by(rows, "station_reservation_expiration_status")
  end

  defp station_reservation_expiration_count(rows, status) do
    rows
    |> Enum.count(&(&1["station_reservation_expiration_status"] == status))
  end

  defp earliest_station_reservation_expires_at_s(rows) do
    rows
    |> Enum.map(& &1["station_reservation_summary_expires_at_s"])
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  defp station_reservation_contact_ids_by_expiration_status(rows) do
    contact_ids_by_field(rows, "station_reservation_expiration_status")
  end

  defp station_reservation_ids_by_expiration_status(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> station_reservation_summary_ids()
      |> Enum.map(&{row["station_reservation_expiration_status"], &1})
    end)
    |> Enum.group_by(fn {status, _id} -> status end, fn {_status, id} -> id end)
    |> Enum.reject(fn {status, ids} ->
      is_nil(status) or Enum.all?(ids, &is_nil/1)
    end)
    |> Map.new(fn {status, ids} -> {status, sorted_stable_ids(ids)} end)
  end

  defp station_reservation_summary_ids(row) do
    [
      row["station_reservation_id"],
      row["station_calendar_reservation_ids"]
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
  end

  defp allocation_summary_review_row?(row) do
    row["review_status"] == "operator_review_required" or
      row["allocation_status"] in ["blocked", "deferred"] or
      row["effective_allocation_status"] == "policy_blocked"
  end

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp normalize_ground_network(nil), do: []

  defp normalize_ground_network(%{} = provider) do
    StationCalendar.to_ground_network(provider)
  end

  defp normalize_ground_network(entries) when is_list(entries) do
    entries
    |> Enum.flat_map(&normalize_ground_network_entry_or_provider/1)
    |> Enum.map(&normalize_station_calendar_status_fields/1)
  end

  defp normalize_ground_network(_ground_network),
    do: raise(ArgumentError, "ground network must be a list or station calendar provider")

  defp normalize_ground_network_entry_or_provider(%{} = entry) do
    entry = stringify_keys(entry)

    if station_calendar_provider_artifact?(entry) do
      StationCalendar.to_ground_network(entry)
    else
      [entry]
    end
  end

  defp normalize_ground_network_entry_or_provider(_entry), do: []

  defp station_calendar_provider_artifact?(%{
         "schema_contract" => "station_calendar_provider.v1"
       }),
       do: true

  defp station_calendar_provider_artifact?(_entry), do: false

  defp apply_resource_filter(contacts, [], _opts), do: {contacts, nil}

  defp apply_resource_filter(contacts, resource_summaries, opts)
       when is_list(resource_summaries) do
    ResourceFilter.filter_candidates(contacts, resource_summaries,
      policy: Keyword.get(opts, :resource_filter_policy, %{}),
      approval_policy: Keyword.get(opts, :approval_policy)
    )
  end

  defp apply_resource_filter(_contacts, _resource_summaries, _opts),
    do: raise(ArgumentError, "resource summaries must be a list")

  defp annotate_status_blocked_contacts([], _ground_network, _source, _approval_policy), do: []

  defp annotate_status_blocked_contacts(contacts, [], _source, _approval_policy), do: contacts

  defp annotate_status_blocked_contacts(contacts, ground_network, source, approval_policy) do
    contacts
    |> StationCalendar.overlay_contacts(ground_network,
      source: "#{source}.status_blocked_ground_network",
      approval_policy: approval_policy
    )
    |> elem(0)
  end

  defp blocked_rows(contact_filter_report) do
    contact_filter_report
    |> Map.get("suppressed_candidates", [])
    |> Enum.map(fn candidate ->
      candidate
      |> base_row()
      |> Map.put("allocation_status", "blocked")
      |> Map.put("allocation_reason", candidate["suppressed_reason"])
      |> Map.put("suppressed_reason", candidate["suppressed_reason"])
      |> Map.put("review_status", "operator_review_required")
      |> Map.put("source_contact_suppression", candidate)
      |> compact_map()
    end)
  end

  defp resource_blocked_rows(nil), do: []

  defp resource_blocked_rows(%{} = resource_filter_report) do
    resource_filter_report
    |> Map.get("suppressed_candidates", [])
    |> Enum.map(fn candidate ->
      candidate
      |> base_row()
      |> Map.merge(resource_suppression_context(candidate))
      |> Map.put("allocation_status", "blocked")
      |> Map.put("allocation_reason", candidate["suppressed_reason"])
      |> Map.put("suppressed_reason", candidate["suppressed_reason"])
      |> Map.put("review_status", "operator_review_required")
      |> Map.put("source_resource_suppression", candidate)
      |> compact_map()
    end)
  end

  defp station_blocked_rows(contacts) do
    Enum.map(contacts, fn contact ->
      contact
      |> base_row()
      |> Map.put("allocation_status", "blocked")
      |> Map.put("allocation_reason", station_allocation_blocked_reason(contact))
      |> Map.put("suppressed_reason", station_allocation_blocked_reason(contact))
      |> Map.put("review_status", "operator_review_required")
      |> Map.put("source_station_calendar_contact", contact)
      |> compact_map()
    end)
  end

  defp duplicate_contact_groups(contacts) do
    contacts
    |> Enum.group_by(&contact_id/1)
    |> Enum.filter(fn {_contact_id, grouped_contacts} -> length(grouped_contacts) > 1 end)
    |> Enum.sort_by(fn {contact_id, _grouped_contacts} -> contact_id end)
  end

  defp duplicate_contact_ids(duplicate_contact_groups) do
    duplicate_contact_groups
    |> Enum.map(fn {contact_id, _grouped_contacts} -> contact_id end)
    |> MapSet.new()
  end

  defp duplicate_contact_candidate_count(duplicate_contact_groups) do
    duplicate_contact_groups
    |> Enum.map(fn {_contact_id, grouped_contacts} -> length(grouped_contacts) end)
    |> Enum.sum()
  end

  defp invalid_contact_rows(invalid_contact_inputs) do
    Enum.map(invalid_contact_inputs, fn {contact, index} ->
      reason = invalid_contact_input_reason(contact)
      contact_id = contact_id_or_nil(contact) || invalid_contact_row_id(reason, index)
      scenario_id = stable_id_or_nil(contact["scenario_id"]) || "missing_scenario_id:#{index}"

      %{
        "id" => "contact_allocation:invalid_contact_input:#{contact_id}",
        "contact_id" => contact_id,
        "type" => contact["type"] || contact_type_from_direction(contact),
        "scenario_id" => scenario_id,
        "spacecraft_id" => contact_spacecraft_id(contact),
        "ground_station_id" => stable_id_or_nil(contact["ground_station_id"]),
        "direction" => contact_direction(contact),
        "starts_at_s" => contact["starts_at_s"],
        "ends_at_s" => contact["ends_at_s"],
        "source_window_id" => stable_id_or_nil(contact["source_window_id"]),
        "source_window_type" => contact["source_window_type"],
        "source_window" => contact["source_window"],
        "actual_throughput_mb" => actual_throughput_value(contact),
        "actual_data_rate_throughput_derivation" =>
          actual_data_rate_throughput_derivation(contact),
        "completed_fraction" => completed_fraction_value(contact),
        "required_capacity_fraction" => required_capacity_fraction_value(contact),
        "required_capacity_fraction_source" => required_capacity_fraction_source(contact),
        "allocation_status" => "blocked",
        "allocation_reason" => reason,
        "suppressed_reason" => reason,
        "invalid_contact_input" => true,
        "invalid_contact_input_reason" => reason,
        "review_status" => "operator_review_required",
        "source_contact_candidate" => contact
      }
      |> Map.merge(downlink_completion_context(contact))
      |> compact_map()
    end)
  end

  defp duplicate_contact_rows(duplicate_contact_groups) do
    Enum.flat_map(duplicate_contact_groups, fn {duplicate_contact_id, grouped_contacts} ->
      duplicate_contact_candidate_ids = Enum.map(grouped_contacts, &contact_id/1)
      duplicate_contact_candidate_count = length(grouped_contacts)

      grouped_contacts
      |> Enum.with_index(1)
      |> Enum.map(fn {contact, duplicate_contact_index} ->
        contact
        |> base_row()
        |> Map.merge(%{
          "id" =>
            "contact_allocation:duplicate_contact_id:#{duplicate_contact_id}:#{duplicate_contact_index}",
          "allocation_status" => "blocked",
          "allocation_reason" => "duplicate_contact_id",
          "suppressed_reason" => "duplicate_contact_id",
          "review_status" => "operator_review_required",
          "duplicate_contact_id_collision" => true,
          "duplicate_contact_index" => duplicate_contact_index,
          "duplicate_contact_candidate_count" => duplicate_contact_candidate_count,
          "duplicate_contact_candidate_ids" => duplicate_contact_candidate_ids,
          "duplicate_contact_candidates" => grouped_contacts,
          "source_contact_candidate" => contact
        })
        |> compact_map()
      end)
    end)
  end

  defp status_blocked_rows(contacts) do
    Enum.map(contacts, fn contact ->
      reason = status_allocation_blocked_reason(contact)

      contact
      |> base_row()
      |> Map.merge(%{
        "allocation_status" => "blocked",
        "allocation_reason" => reason,
        "suppressed_reason" => reason,
        "contact_allocation_effect_status" => "blocked",
        "contact_allocation_effect_reason" => reason,
        "review_status" => "operator_review_required",
        "source_contact_candidate" => contact
      })
      |> compact_map()
    end)
  end

  defp allocation_row(contact, deferred_by_contact_id, selected_by_contact_id) do
    contact_id = contact_id(contact)

    cond do
      recommendation = Map.get(deferred_by_contact_id, contact_id) ->
        contact
        |> base_row()
        |> Map.merge(%{
          "allocation_status" => "deferred",
          "allocation_reason" => contention_allocation_reason(recommendation),
          "selected" => false,
          "contention_group_id" => recommendation["group_id"],
          "selected_contact_id" => recommendation["selected_contact_id"],
          "selected_priority" => recommendation["selected_priority"],
          "selected_priority_source" => recommendation["selected_priority_source"],
          "deferred_contact_priorities" => recommendation["deferred_contact_priorities"],
          "requested_priority_fields" => recommendation["requested_priority_fields"],
          "priority_field_evidence_counts" => recommendation["priority_field_evidence_counts"],
          "priority_fields_without_numeric_evidence_count" =>
            recommendation["priority_fields_without_numeric_evidence_count"],
          "priority_fields_without_numeric_evidence" =>
            recommendation["priority_fields_without_numeric_evidence"],
          "resolution_priority_override_count" =>
            recommendation["resolution_priority_override_count"],
          "resolution_priority_override_contact_ids" =>
            recommendation["resolution_priority_override_contact_ids"],
          "review_status" => "operator_review_required",
          "source_contention_recommendation" => recommendation
        })
        |> compact_map()

      recommendation = Map.get(selected_by_contact_id, contact_id) ->
        contact
        |> base_row()
        |> Map.merge(%{
          "allocation_status" => "allocated",
          "allocation_reason" => "selected_by_contention_resolution",
          "selected" => true,
          "contention_group_id" => recommendation["group_id"],
          "deferred_contact_ids" => recommendation["deferred_contact_ids"],
          "selected_priority" => recommendation["selected_priority"],
          "selected_priority_source" => recommendation["selected_priority_source"],
          "deferred_contact_priorities" => recommendation["deferred_contact_priorities"],
          "requested_priority_fields" => recommendation["requested_priority_fields"],
          "priority_field_evidence_counts" => recommendation["priority_field_evidence_counts"],
          "priority_fields_without_numeric_evidence_count" =>
            recommendation["priority_fields_without_numeric_evidence_count"],
          "priority_fields_without_numeric_evidence" =>
            recommendation["priority_fields_without_numeric_evidence"],
          "resolution_priority_override_count" =>
            recommendation["resolution_priority_override_count"],
          "resolution_priority_override_contact_ids" =>
            recommendation["resolution_priority_override_contact_ids"],
          "review_status" => "operator_review_required",
          "source_contention_recommendation" => recommendation
        })
        |> compact_map()

      true ->
        contact
        |> base_row()
        |> Map.merge(%{
          "allocation_status" => "allocated",
          "allocation_reason" => "available",
          "selected" => true,
          "review_status" => "accepted_for_planning"
        })
        |> compact_map()
    end
  end

  defp base_row(contact) do
    id = contact_id(contact)

    %{
      "id" => "contact_allocation:#{id}",
      "contact_id" => id,
      "type" => contact["type"] || contact_type_from_direction(contact),
      "scenario_id" => stable_id_or_nil(contact["scenario_id"]),
      "spacecraft_id" => contact_spacecraft_id(contact),
      "ground_station_id" => stable_id_or_nil(contact["ground_station_id"]),
      "direction" => contact_direction(contact),
      "contact_status" => contact_status(contact),
      "source_approval_status" => contact_approval_status(contact),
      "starts_at_s" => contact["starts_at_s"],
      "ends_at_s" => contact["ends_at_s"],
      "source_window_id" => stable_id_or_nil(contact["source_window_id"]),
      "source_window_type" => contact["source_window_type"],
      "source_window" => contact["source_window"],
      "actual_throughput_mb" => actual_throughput_value(contact),
      "actual_data_rate_throughput_derivation" => actual_data_rate_throughput_derivation(contact),
      "completed_fraction" => completed_fraction_value(contact),
      "required_capacity_fraction" => required_capacity_fraction_value(contact),
      "required_capacity_fraction_source" => required_capacity_fraction_source(contact),
      "contact_success" => contact_boolean_value(contact, "contact_success"),
      "contact_result" =>
        provider_result_artifact_value(contact_value(contact, "contact_result")),
      "contact_success_factor" => contact_feedback_factor(contact, "contact_success_factor"),
      "contact_success_factor_source" => contact_value(contact, "contact_success_factor_source"),
      "command_success" => contact_boolean_value(contact, "command_success"),
      "command_result" =>
        provider_result_artifact_value(contact_value(contact, "command_result")),
      "command_success_factor" => contact_feedback_factor(contact, "command_success_factor"),
      "command_success_factor_source" => contact_value(contact, "command_success_factor_source"),
      "station_calendar_entry_id" => contact_station_calendar_entry_id(contact),
      "station_calendar_provider_id" => contact_station_calendar_provider_id(contact),
      "station_calendar_provider_entry_id" => contact_station_calendar_provider_entry_id(contact),
      "station_calendar_directions" => contact["station_calendar_directions"],
      "station_calendar_status" => contact["station_calendar_status"],
      "station_calendar_precedence_rank" => contact["station_calendar_precedence_rank"],
      "station_calendar_precedence_availability" =>
        contact["station_calendar_precedence_availability"],
      "station_calendar_overlap_count" => contact["station_calendar_overlap_count"],
      "station_calendar_overlap_entry_ids" => contact["station_calendar_overlap_entry_ids"],
      "station_calendar_overlap_availabilities" =>
        contact["station_calendar_overlap_availabilities"],
      "station_calendar_entry_ambiguous" => contact["station_calendar_entry_ambiguous"],
      "station_calendar_ambiguous_entry_count" =>
        contact["station_calendar_ambiguous_entry_count"],
      "station_calendar_ambiguous_entry_ids" => contact["station_calendar_ambiguous_entry_ids"],
      "station_calendar_reservation_overlap_count" =>
        contact["station_calendar_reservation_overlap_count"],
      "station_calendar_reservation_ids" => contact["station_calendar_reservation_ids"],
      "station_calendar_reservation_expires_at_s" =>
        contact["station_calendar_reservation_expires_at_s"],
      "station_calendar_reserved_by" => contact["station_calendar_reserved_by"],
      "station_calendar_reservation_statuses" => contact["station_calendar_reservation_statuses"],
      "station_calendar_trust_boundary_status" =>
        contact["station_calendar_trust_boundary_status"],
      "trust_boundary" => contact["trust_boundary"],
      "provenance" => contact["provenance"],
      "source_station_calendar_entry" => contact["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => contact["source_station_calendar_overlaps"],
      "station_availability" => station_availability(contact),
      "station_contention_status" => contact["station_contention_status"],
      "capacity_fraction" => station_capacity_fraction(contact),
      "station_reservation_id" =>
        stable_id_or_nil(contact["station_reservation_id"]) ||
          stable_id_or_nil(contact["reservation_id"]),
      "station_reserved_by" => contact["station_reserved_by"] || contact["reserved_by"],
      "station_reservation_status" =>
        contact["station_reservation_status"] || contact["reservation_status"],
      "station_reservation_expires_at_s" =>
        numeric_or_nil(contact["station_reservation_expires_at_s"]) ||
          reservation_expires_at_s(contact),
      "station_reservation_match_status" =>
        contact["station_reservation_match_status"] || contact["reservation_match_status"]
    }
    |> Map.merge(provider_counteroffer_context(contact))
    |> Map.merge(downlink_completion_context(contact))
    |> Map.merge(resource_suppression_context(contact))
    |> normalize_station_calendar_id_lists()
    |> normalize_station_calendar_number_lists()
    |> derive_station_calendar_counts()
    |> compact_map()
  end

  defp provider_counteroffer_context(row) do
    if provider_counteroffer_context_present?(row) do
      @provider_counteroffer_fields
      |> Enum.reduce(%{}, fn field, context ->
        put_provider_counteroffer_value(context, field, provider_counteroffer_value(row, field))
      end)
      |> put_provider_counteroffer_value(
        "provider_counteroffer_start_delta_s",
        provider_counteroffer_start_delta(row)
      )
      |> put_provider_counteroffer_value(
        "provider_counteroffer_end_delta_s",
        provider_counteroffer_end_delta(row)
      )
      |> put_provider_counteroffer_value(
        "provider_counteroffer_duration_delta_s",
        provider_counteroffer_duration_delta(row)
      )
      |> compact_map()
    else
      %{}
    end
  end

  defp provider_counteroffer_context_present?(row) do
    row["required_operator_action"] == "review_provider_counteroffer" or
      Enum.any?(@provider_counteroffer_fields, fn field ->
        provider_counteroffer_value_present?(provider_counteroffer_value(row, field))
      end)
  end

  defp provider_counteroffer_value(row, field) do
    provider_counteroffer_source_value(row, field)
  end

  defp provider_counteroffer_source_value(source, field),
    do: provider_counteroffer_source_value(source, field, 0)

  defp provider_counteroffer_source_value(source, field, depth)
       when is_map(source) and depth < 4 do
    [
      source[field],
      provider_counteroffer_source_value(
        source["source_station_calendar_entry"],
        field,
        depth + 1
      )
      | source_station_calendar_overlap_values(source, field, depth + 1)
    ]
    |> Enum.find(&provider_counteroffer_value_present?/1)
  end

  defp provider_counteroffer_source_value(_source, _field, _depth), do: nil

  defp source_station_calendar_overlap_values(
         %{"source_station_calendar_overlaps" => overlaps},
         field,
         depth
       )
       when is_list(overlaps),
       do: Enum.map(overlaps, &provider_counteroffer_source_value(&1, field, depth))

  defp source_station_calendar_overlap_values(
         %{"source_station_calendar_overlaps" => overlap},
         field,
         depth
       ),
       do: [provider_counteroffer_source_value(overlap, field, depth)]

  defp source_station_calendar_overlap_values(_row, _field, _depth), do: []

  defp provider_counteroffer_start_delta(row) do
    provider_counteroffer_value(row, "provider_counteroffer_start_delta_s") ||
      numeric_delta(
        provider_counteroffer_value(row, "provider_counteroffer_starts_at_s"),
        row["starts_at_s"]
      )
  end

  defp provider_counteroffer_end_delta(row) do
    provider_counteroffer_value(row, "provider_counteroffer_end_delta_s") ||
      numeric_delta(
        provider_counteroffer_value(row, "provider_counteroffer_ends_at_s"),
        row["ends_at_s"]
      )
  end

  defp provider_counteroffer_duration_delta(row) do
    provider_counteroffer_value(row, "provider_counteroffer_duration_delta_s") ||
      derived_provider_counteroffer_duration_delta(row)
  end

  defp derived_provider_counteroffer_duration_delta(row) do
    with start when is_number(start) <- numeric_or_nil(row["starts_at_s"]),
         finish when is_number(finish) <- numeric_or_nil(row["ends_at_s"]),
         counter_start when is_number(counter_start) <-
           numeric_or_nil(provider_counteroffer_value(row, "provider_counteroffer_starts_at_s")),
         counter_finish when is_number(counter_finish) <-
           numeric_or_nil(provider_counteroffer_value(row, "provider_counteroffer_ends_at_s")) do
      counter_finish - counter_start - (finish - start)
    else
      _value -> nil
    end
  end

  defp numeric_delta(value, base_value) do
    with value when is_number(value) <- numeric_or_nil(value),
         base_value when is_number(base_value) <- numeric_or_nil(base_value) do
      value - base_value
    else
      _value -> nil
    end
  end

  defp put_provider_counteroffer_value(context, _field, value) when value in [nil, "", [], %{}],
    do: context

  defp put_provider_counteroffer_value(context, field, value), do: Map.put(context, field, value)

  defp provider_counteroffer_value_present?(value), do: value not in [nil, "", [], %{}]

  defp resource_suppression_context(row) do
    Map.take(row, [
      "resource_blocking_dimension",
      "resource_source_quality",
      "resource_trust_boundary",
      "resource_trust_boundary_status",
      "resource_provenance",
      "source_resource_summary",
      "fuel_margin",
      "power_margin",
      "storage_margin",
      "downlink_margin",
      "thermal_margin_c",
      "battery_capacity_wh",
      "battery_energy_used_wh",
      "battery_state_of_charge",
      "spacecraft_available",
      "payload_available",
      "antenna_available",
      "degraded",
      "mode",
      "incompatible_activity_types",
      "suppressed_activity_types"
    ])
  end

  defp contention_allocation_reason(%{"resource_scope" => "spacecraft"}),
    do: "same_spacecraft_contention"

  defp contention_allocation_reason(_recommendation), do: "same_station_contention"

  defp deferred_by_contact_id(resolution_report) do
    resolution_report
    |> Map.get("recommendations", [])
    |> Enum.flat_map(fn recommendation ->
      recommendation
      |> Map.get("deferred_contact_ids", [])
      |> Enum.map(&{&1, recommendation})
    end)
    |> Map.new()
  end

  defp selected_by_contact_id(resolution_report) do
    resolution_report
    |> Map.get("recommendations", [])
    |> Enum.map(&{&1["selected_contact_id"], &1})
    |> Enum.reject(fn {contact_id, _recommendation} -> is_nil(contact_id) end)
    |> Map.new()
  end

  defp allocation_sort_key(row) do
    {
      row["ground_station_id"] || "",
      row["starts_at_s"] || 0.0,
      row["contact_id"] || "",
      row["id"] || ""
    }
  end

  defp default_required_capacity_fraction(opts) do
    value =
      Keyword.get(opts, :default_required_capacity_fraction) ||
        get_in(Keyword.get(opts, :capacity_policy, %{}), ["default_required_capacity_fraction"]) ||
        get_in(Keyword.get(opts, :capacity_policy, %{}), [:default_required_capacity_fraction]) ||
        get_in(Keyword.get(opts, :policy, %{}), ["default_required_capacity_fraction"]) ||
        get_in(Keyword.get(opts, :policy, %{}), [:default_required_capacity_fraction])

    case numeric_or_nil(value) do
      nil ->
        nil

      value when value > 0.0 and value <= 1.0 ->
        value

      _value ->
        raise ArgumentError, "default_required_capacity_fraction must be in the interval (0, 1]"
    end
  end

  defp apply_reduced_capacity_packing(rows, default_capacity_requirement) do
    pack_groups =
      rows
      |> Enum.filter(&reduced_capacity_pack_row?/1)
      |> Enum.group_by(& &1["contention_group_id"])
      |> Enum.map(fn {_group_id, group_rows} ->
        reduced_capacity_pack_group(group_rows, default_capacity_requirement)
      end)

    decisions =
      pack_groups
      |> Enum.flat_map(& &1["row_decisions"])
      |> Map.new()

    packed_rows =
      Enum.map(rows, fn row ->
        case Map.get(decisions, row["contact_id"]) do
          nil -> row
          decision -> apply_reduced_capacity_pack_decision(row, decision)
        end
      end)

    {packed_rows, Enum.map(pack_groups, &Map.delete(&1, "row_decisions"))}
  end

  defp reduced_capacity_pack_row?(%{
         "contention_group_id" => group_id,
         "capacity_fraction" => capacity_fraction,
         "source_contention_recommendation" => %{"resource_scope" => "ground_station"}
       })
       when is_binary(group_id) and is_number(capacity_fraction) and capacity_fraction > 0.0 and
              capacity_fraction < 1.0,
       do: true

  defp reduced_capacity_pack_row?(_row), do: false

  defp reduced_capacity_pack_group(group_rows, default_capacity_requirement) do
    recommendation =
      group_rows
      |> Enum.map(& &1["source_contention_recommendation"])
      |> Enum.find(&is_map/1)

    group_id = group_rows |> Enum.map(& &1["contention_group_id"]) |> Enum.find(&is_binary/1)
    capacity_fraction = group_rows |> Enum.map(& &1["capacity_fraction"]) |> Enum.min()
    rows_by_contact_id = Map.new(group_rows, &{&1["contact_id"], &1})

    {contention_selected_ids, contention_deferred_ids} =
      reduced_capacity_pack_contact_order(recommendation)

    selected_ids = Enum.filter(contention_selected_ids, &Map.has_key?(rows_by_contact_id, &1))
    deferred_ids = Enum.filter(contention_deferred_ids, &Map.has_key?(rows_by_contact_id, &1))

    {used_fraction, capacity_selected_ids, capacity_packed_ids, capacity_deferred_ids} =
      (selected_ids ++ deferred_ids)
      |> Enum.map(&Map.get(rows_by_contact_id, &1))
      |> Enum.reject(&is_nil/1)
      |> Enum.reduce({0.0, [], [], []}, fn row,
                                           {used_fraction, selected_fit_ids, packed_ids,
                                            deferred_ids} ->
        demand_fraction = reduced_capacity_requirement(row, default_capacity_requirement)
        contact_id = row["contact_id"]

        if used_fraction + demand_fraction <= capacity_fraction + 1.0e-9 do
          if contact_id in selected_ids do
            {used_fraction + demand_fraction, selected_fit_ids ++ [contact_id], packed_ids,
             deferred_ids}
          else
            {used_fraction + demand_fraction, selected_fit_ids, packed_ids ++ [contact_id],
             deferred_ids}
          end
        else
          {used_fraction, selected_fit_ids, packed_ids, deferred_ids ++ [contact_id]}
        end
      end)

    allocated_ids = capacity_selected_ids ++ capacity_packed_ids
    capacity_selected_contact_id = List.first(allocated_ids)

    row_decisions =
      Enum.map(capacity_selected_ids, fn contact_id ->
        {contact_id,
         reduced_capacity_pack_decision(
           "selected_by_contention_resolution",
           group_id,
           capacity_fraction,
           used_fraction,
           Map.fetch!(rows_by_contact_id, contact_id),
           default_capacity_requirement,
           nil
         )}
      end) ++
        Enum.map(capacity_packed_ids, fn contact_id ->
          {contact_id,
           reduced_capacity_pack_decision(
             "selected_by_reduced_station_capacity_pack",
             group_id,
             capacity_fraction,
             used_fraction,
             Map.fetch!(rows_by_contact_id, contact_id),
             default_capacity_requirement,
             nil
           )}
        end) ++
        Enum.map(capacity_deferred_ids, fn contact_id ->
          {contact_id,
           reduced_capacity_pack_decision(
             "deferred_by_reduced_station_capacity_pack",
             group_id,
             capacity_fraction,
             used_fraction,
             Map.fetch!(rows_by_contact_id, contact_id),
             default_capacity_requirement,
             capacity_selected_contact_id
           )}
        end)

    capacity_requirement_rows =
      capacity_requirement_rows(group_rows, row_decisions, default_capacity_requirement)

    %{
      "contention_group_id" => group_id,
      "ground_station_id" => first_present(group_rows, "ground_station_id"),
      "capacity_fraction" => capacity_fraction,
      "used_capacity_fraction" => used_fraction,
      "unused_capacity_fraction" => max(capacity_fraction - used_fraction, 0.0),
      "input_contact_ids" => Enum.map(group_rows, & &1["contact_id"]),
      "selected_contact_ids" => capacity_selected_ids,
      "capacity_packed_contact_ids" => capacity_packed_ids,
      "deferred_contact_ids" => capacity_deferred_ids,
      "capacity_requirement_rows" => capacity_requirement_rows,
      "default_required_capacity_fraction" => default_capacity_requirement,
      "pack_status" => if(capacity_deferred_ids == [], do: "all_fit", else: "capacity_limited"),
      "source_contention_recommendation" => recommendation,
      "row_decisions" => row_decisions
    }
    |> compact_map()
  end

  defp reduced_capacity_pack_decision(
         status,
         group_id,
         capacity_fraction,
         used_fraction,
         row,
         default_capacity_requirement,
         selected_contact_id
       ) do
    %{
      "capacity_pack_group_id" => group_id,
      "capacity_pack_status" => status,
      "capacity_pack_capacity_fraction" => capacity_fraction,
      "capacity_pack_used_fraction" => used_fraction,
      "selected_contact_id" => selected_contact_id
    }
    |> Map.merge(reduced_capacity_requirement_context(row, default_capacity_requirement))
    |> compact_map()
  end

  defp capacity_requirement_rows(group_rows, row_decisions, default_capacity_requirement) do
    decisions_by_contact_id = Map.new(row_decisions)

    Enum.map(group_rows, fn row ->
      decision = Map.get(decisions_by_contact_id, row["contact_id"], %{})
      allocation_row = apply_reduced_capacity_pack_decision(row, decision)

      %{
        "contact_id" => row["contact_id"],
        "allocation_status" => allocation_row["allocation_status"],
        "allocation_reason" => allocation_row["allocation_reason"],
        "capacity_pack_status" => decision["capacity_pack_status"],
        "required_capacity_fraction" =>
          reduced_capacity_requirement(row, default_capacity_requirement),
        "required_capacity_fraction_source" =>
          reduced_capacity_requirement_source(row, default_capacity_requirement)
      }
      |> compact_map()
    end)
  end

  defp reduced_capacity_pack_contact_order(%{} = recommendation) do
    selected_ids = List.wrap(recommendation["selected_contact_id"]) |> Enum.reject(&is_nil/1)
    deferred_ids = Map.get(recommendation, "deferred_contact_ids", [])
    {selected_ids, deferred_ids}
  end

  defp reduced_capacity_pack_contact_order(_recommendation), do: {[], []}

  defp reduced_capacity_requirement(row, default_capacity_requirement) do
    known_or_full_capacity_requirement(row, default_capacity_requirement)
  end

  defp known_or_full_capacity_requirement(%{"required_capacity_fraction" => value}, _default)
       when is_number(value),
       do: value

  defp known_or_full_capacity_requirement(_row, default) when is_number(default), do: default

  defp known_or_full_capacity_requirement(%{"capacity_fraction" => value}, _default)
       when is_number(value),
       do: value

  defp known_or_full_capacity_requirement(_row, _default), do: 1.0

  defp reduced_capacity_requirement_source(
         %{"required_capacity_fraction" => value, "required_capacity_fraction_source" => source},
         _default
       )
       when is_number(value) and is_binary(source),
       do: source

  defp reduced_capacity_requirement_source(%{"required_capacity_fraction" => value}, _default)
       when is_number(value),
       do: "contact_required_capacity_fraction"

  defp reduced_capacity_requirement_source(_row, default) when is_number(default),
    do: "default_reduced_capacity_policy"

  defp reduced_capacity_requirement_source(%{"capacity_fraction" => value}, _default)
       when is_number(value),
       do: "station_capacity_fraction_fallback"

  defp reduced_capacity_requirement_source(_row, _default), do: "implicit_full_station_capacity"

  defp reduced_capacity_requirement_context(row, default) do
    %{
      "required_capacity_fraction" => reduced_capacity_requirement(row, default),
      "required_capacity_fraction_source" => reduced_capacity_requirement_source(row, default)
    }
  end

  defp promote_capacity_packed_row(%{"allocation_status" => "deferred"} = row) do
    row
    |> Map.put("allocation_status", "allocated")
    |> Map.put("allocation_reason", "selected_by_reduced_station_capacity_pack")
    |> Map.put("selected", true)
    |> Map.put("selected_contact_id", row["contact_id"])
    |> Map.put("review_status", "operator_review_required")
  end

  defp promote_capacity_packed_row(row), do: row

  defp defer_capacity_limited_row(%{"allocation_status" => "allocated"} = row) do
    row
    |> Map.put("allocation_status", "deferred")
    |> Map.put("allocation_reason", "deferred_by_reduced_station_capacity_pack")
    |> Map.put("selected", false)
    |> Map.put("review_status", "operator_review_required")
  end

  defp defer_capacity_limited_row(row), do: row

  defp apply_reduced_capacity_pack_decision(row, decision) do
    row =
      case decision["capacity_pack_status"] do
        "selected_by_reduced_station_capacity_pack" -> promote_capacity_packed_row(row)
        "deferred_by_reduced_station_capacity_pack" -> defer_capacity_limited_row(row)
        _status -> row
      end

    Map.merge(row, decision)
  end

  defp allocated_contact_row?(%{"effective_allocation_status" => "allocated"}), do: true

  defp allocated_contact_row?(_row), do: false

  defp allocated_contact_from_row(row, contention_contacts) do
    contention_contacts
    |> Enum.find(&(contact_id(&1) == row["contact_id"]))
    |> Map.merge(returned_allocation_context(row))
    |> compact_map()
  end

  defp returned_allocation_context(row) do
    %{
      "allocation_status" => row["allocation_status"],
      "effective_allocation_status" => row["effective_allocation_status"],
      "allocation_reason" => row["allocation_reason"],
      "review_status" => row["review_status"],
      "selected" => row["selected"],
      "selected_contact_id" => row["selected_contact_id"],
      "deferred_contact_ids" => row["deferred_contact_ids"],
      "selected_priority" => row["selected_priority"],
      "selected_priority_source" => row["selected_priority_source"],
      "deferred_contact_priorities" => row["deferred_contact_priorities"],
      "requested_priority_fields" => row["requested_priority_fields"],
      "priority_field_evidence_counts" => row["priority_field_evidence_counts"],
      "priority_fields_without_numeric_evidence_count" =>
        row["priority_fields_without_numeric_evidence_count"],
      "priority_fields_without_numeric_evidence" =>
        row["priority_fields_without_numeric_evidence"],
      "resolution_priority_override_count" => row["resolution_priority_override_count"],
      "resolution_priority_override_contact_ids" =>
        row["resolution_priority_override_contact_ids"],
      "contention_group_id" => row["contention_group_id"],
      "station_calendar_entry_id" => row["station_calendar_entry_id"],
      "station_calendar_provider_id" => row["station_calendar_provider_id"],
      "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
      "station_reservation_id" => row["station_reservation_id"],
      "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
      "station_reserved_by" => row["station_reserved_by"],
      "station_reservation_status" => row["station_reservation_status"],
      "station_reservation_match_status" => row["station_reservation_match_status"],
      "source_window_id" => row["source_window_id"],
      "source_window_type" => row["source_window_type"],
      "source_window" => row["source_window"],
      "required_capacity_fraction" => row["required_capacity_fraction"],
      "required_capacity_fraction_source" => row["required_capacity_fraction_source"],
      "capacity_pack_group_id" => row["capacity_pack_group_id"],
      "capacity_pack_status" => row["capacity_pack_status"],
      "capacity_pack_capacity_fraction" => row["capacity_pack_capacity_fraction"],
      "capacity_pack_used_fraction" => row["capacity_pack_used_fraction"],
      "approval_status" => row["approval_status"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "policy_decision" => row["policy_decision"]
    }
    |> Map.merge(provider_counteroffer_context(row))
  end

  defp resource_blocked_contact_count(rows) do
    Enum.count(rows, &Map.has_key?(&1, "source_resource_suppression"))
  end

  defp resource_blocked_contact_ids(rows) do
    rows
    |> Enum.filter(&Map.has_key?(&1, "source_resource_suppression"))
    |> Enum.map(& &1["contact_id"])
    |> Enum.reject(&is_nil/1)
    |> Enum.sort()
  end

  defp put_effective_allocation_status(%{"allocation_status" => "allocated"} = row) do
    effective_status =
      if row["approval_status"] == "blocked_by_policy",
        do: "policy_blocked",
        else: "allocated"

    Map.put(row, "effective_allocation_status", effective_status)
  end

  defp put_effective_allocation_status(%{"allocation_status" => status} = row),
    do: Map.put(row, "effective_allocation_status", status)

  defp station_allocation_blocked?(contact) do
    availability = station_availability(contact)
    capacity_fraction = station_capacity_fraction(contact)
    required_capacity_fraction = required_capacity_fraction_value(contact) || 0.0

    cond do
      availability in @station_blocking_availability -> true
      is_number(capacity_fraction) and capacity_fraction <= 0.0 -> true
      is_number(capacity_fraction) and required_capacity_fraction > capacity_fraction -> true
      true -> false
    end
  end

  defp station_allocation_blocked_reason(contact) do
    availability = station_availability(contact)
    capacity_fraction = station_capacity_fraction(contact)
    required_capacity_fraction = required_capacity_fraction_value(contact) || 0.0

    cond do
      availability in @station_blocking_availability ->
        "ground_station_unavailable"

      is_number(capacity_fraction) and capacity_fraction <= 0.0 ->
        "ground_station_capacity_zero"

      is_number(capacity_fraction) and required_capacity_fraction > capacity_fraction ->
        "ground_station_reduced_capacity_insufficient"

      true ->
        "ground_station_capacity_zero"
    end
  end

  defp station_capacity_fraction(contact),
    do: first_unit_interval(station_capacity_fraction_candidates(contact))

  defp station_availability(contact) do
    case Enum.filter(station_availability_candidates(contact), &station_availability_value?/1) do
      [] -> nil
      values -> Enum.max_by(values, &station_availability_severity/1)
    end
  end

  defp station_availability_candidates(contact) do
    [
      contact["station_availability"],
      contact["availability"],
      contact["station_calendar_status"]
    ] ++
      source_station_calendar_availability_candidates(contact["source_station_calendar_entry"]) ++
      source_station_calendar_availability_candidates(contact["source_station_calendar_overlaps"])
  end

  defp station_availability_value?(value)
       when value in ["available", "unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp station_availability_value?(_value), do: false

  defp station_availability_severity(value), do: Map.get(@station_availability_severity, value, 0)

  defp source_station_calendar_availability_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_availability_candidates/1)

  defp source_station_calendar_availability_candidates(%{} = source) do
    [
      source["station_availability"],
      source["availability"],
      source["station_calendar_status"],
      source["status"]
    ]
  end

  defp source_station_calendar_availability_candidates(_source), do: []

  defp status_allocation_blocked?(contact) do
    contact_status(contact) in terminal_contact_statuses() or
      contact_status(contact) == "blocked_by_policy" or
      contact_approval_status(contact) in ["blocked_by_policy", "rejected"]
  end

  defp status_allocation_blocked_reason(contact) do
    status = contact_status(contact)
    approval_status = contact_approval_status(contact)

    cond do
      approval_status == "rejected" -> "approval_status_rejected"
      status == "blocked_by_policy" -> "activity_status_blocked_by_policy"
      status in terminal_contact_statuses() -> "activity_status_#{status}"
      station_allocation_blocked?(contact) -> station_allocation_blocked_reason(contact)
      approval_status == "blocked_by_policy" -> "approval_status_blocked_by_policy"
    end
  end

  defp terminal_contact_statuses,
    do: ~w(canceled cancelled completed executed failed missed partial rejected)

  defp contact_status(contact) do
    Map.get(contact, "status") || get_in(contact, ["metadata", "status"]) || "planned"
  end

  defp contact_approval_status(contact) do
    Map.get(contact, "approval_status") || get_in(contact, ["metadata", "approval_status"])
  end

  defp maybe_apply_approval_policy(rows, nil), do: rows

  defp maybe_apply_approval_policy(rows, approval_policy) do
    Enum.map(rows, fn row ->
      if allocation_policy_boundary?(row) do
        apply_approval_policy(row, approval_policy)
      else
        row
      end
    end)
  end

  defp allocation_policy_boundary?(%{"allocation_status" => status}) when status != "allocated",
    do: true

  defp allocation_policy_boundary?(%{"review_status" => "operator_review_required"}), do: true

  defp allocation_policy_boundary?(%{"station_availability" => availability})
       when availability in ["reserved", "unavailable", "maintenance", "reduced_capacity"],
       do: true

  defp allocation_policy_boundary?(%{"station_contention_status" => status})
       when is_binary(status) and status != "",
       do: true

  defp allocation_policy_boundary?(%{"station_calendar_trust_boundary_status" => status})
       when status in ["declared", "missing"],
       do: true

  defp allocation_policy_boundary?(row) do
    Enum.any?(
      [
        "contact_success",
        "contact_result",
        "contact_success_factor",
        "command_success",
        "command_result",
        "command_success_factor"
      ],
      &Map.has_key?(row, &1)
    )
  end

  defp apply_approval_policy(row, approval_policy) do
    requirement = allocation_approval_requirement(row)

    {status, requirements, rule_matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "contact_allocation", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", rule_matches)
    |> Map.put("policy_decision", decision)
  end

  defp allocation_approval_requirement(row) do
    %{
      "schema_contract" => "approval_requirement.v1",
      "id" => "approval:#{row["id"]}",
      "activity_id" => row["contact_id"],
      "activity_type" => row["type"] || "planned_contact",
      "action" => "review_contact_allocation",
      "requirement_type" => allocation_requirement_type(row),
      "reason" => allocation_requirement_reason(row),
      "activity_context" => allocation_policy_context(row)
    }
  end

  defp allocation_requirement_type(row) do
    cond do
      health_check_contact_allocation?(row) -> "health_check_review"
      command_contact_allocation?(row) -> "command_review"
      true -> "contact_schedule_change"
    end
  end

  defp allocation_requirement_reason(row) do
    cond do
      health_check_contact_allocation?(row) ->
        "health-check contact allocation #{row["allocation_status"]}: #{row["allocation_reason"]}"

      command_contact_allocation?(row) ->
        "command contact allocation #{row["allocation_status"]}: #{row["allocation_reason"]}"

      true ->
        "contact allocation #{row["allocation_status"]}: #{row["allocation_reason"]}"
    end
  end

  defp health_check_contact_allocation?(row) do
    row["direction"] == "health_check" or row["type"] == "health_check"
  end

  defp command_contact_allocation?(row) do
    row["direction"] in @command_contact_directions or row["type"] == "command"
  end

  defp allocation_policy_context(row) do
    row
    |> Map.take([
      "contact_id",
      "type",
      "direction",
      "allocation_status",
      "effective_allocation_status",
      "allocation_reason",
      "suppressed_reason",
      "contention_group_id",
      "selected_contact_id",
      "deferred_contact_ids",
      "selected_priority",
      "selected_priority_source",
      "deferred_contact_priorities",
      "requested_priority_fields",
      "priority_field_evidence_counts",
      "priority_fields_without_numeric_evidence_count",
      "priority_fields_without_numeric_evidence",
      "resolution_priority_override_count",
      "resolution_priority_override_contact_ids",
      "starts_at_s",
      "ends_at_s",
      "source_window_id",
      "source_window_type",
      "source_window",
      "actual_throughput_mb",
      "actual_data_rate_throughput_derivation",
      "completed_fraction",
      "required_downlink_mb",
      "candidate_downlink_mb",
      "downlink_completion_ratio",
      "selected_downlink_shortfall_mb",
      "downlink_requirement_status",
      "downlink_completion_source",
      "downlink_completion_sources",
      "required_capacity_fraction",
      "contact_success",
      "contact_result",
      "contact_success_factor",
      "contact_success_factor_source",
      "command_success",
      "command_result",
      "command_success_factor",
      "command_success_factor_source",
      "ground_station_id",
      "station_availability",
      "capacity_fraction",
      "station_contention_status",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id",
      "station_calendar_directions",
      "station_calendar_status",
      "station_calendar_overlap_count",
      "station_calendar_overlap_entry_ids",
      "station_calendar_overlap_availabilities",
      "station_calendar_entry_ambiguous",
      "station_calendar_ambiguous_entry_count",
      "station_calendar_ambiguous_entry_ids",
      "station_calendar_reservation_overlap_count",
      "station_calendar_reservation_ids",
      "station_calendar_reservation_expires_at_s",
      "station_calendar_reserved_by",
      "station_calendar_reservation_statuses",
      "station_calendar_trust_boundary_status",
      "trust_boundary",
      "provenance",
      "source_station_calendar_entry",
      "source_station_calendar_overlaps",
      "station_reservation_id",
      "station_reservation_expires_at_s",
      "station_reserved_by",
      "station_reservation_status",
      "station_reservation_match_status",
      "resource_blocking_dimension",
      "resource_source_quality",
      "resource_trust_boundary",
      "resource_trust_boundary_status",
      "resource_provenance",
      "fuel_margin",
      "power_margin",
      "storage_margin",
      "downlink_margin",
      "thermal_margin_c",
      "battery_capacity_wh",
      "battery_energy_used_wh",
      "battery_state_of_charge",
      "spacecraft_available",
      "payload_available",
      "antenna_available",
      "degraded",
      "mode",
      "incompatible_activity_types",
      "suppressed_activity_types",
      "source_resource_summary"
    ])
    |> Map.merge(provider_counteroffer_context(row))
    |> compact_map()
  end

  defp contact_candidate?(contact) do
    contact_like_input?(contact) and
      is_nil(contact_id_issue(contact)) and
      is_nil(contact_identity_issue(contact)) and
      is_number(Map.get(contact, "starts_at_s")) and
      is_number(Map.get(contact, "ends_at_s")) and
      not is_nil(Map.get(contact, "ground_station_id")) and
      not invalid_unit_interval_declared?(station_capacity_fraction_candidates(contact)) and
      not invalid_percent_declared?(station_capacity_percent_candidates(contact)) and
      not invalid_unit_interval_declared?(required_capacity_fraction_candidates(contact)) and
      not invalid_percent_declared?(required_capacity_percent_candidates(contact)) and
      not invalid_unit_interval_declared?(completed_fraction_candidates(contact)) and
      not invalid_unit_interval_declared?(
        contact_feedback_factor_candidates(contact, "contact_success_factor")
      ) and
      not invalid_unit_interval_declared?(
        contact_feedback_factor_candidates(contact, "command_success_factor")
      )
  end

  defp contact_like_input?(contact) do
    Map.get(contact, "invalid_contact_shape") == true or
      Map.get(contact, "type") in @contact_types or
      Map.get(contact, "direction") in @contact_directions or
      provider_downlink_contact_input?(contact)
  end

  defp provider_downlink_contact_input?(contact) do
    Map.get(contact, "type") in [nil, "contact", "planned_contact"] and
      Map.get(contact, "direction") in [nil, "downlink"] and
      provider_contact_evidence?(contact)
  end

  defp provider_contact_evidence?(contact) do
    Enum.any?(
      [
        Map.get(contact, "id"),
        Map.get(contact, "contact_id"),
        Map.get(contact, "activity_id"),
        Map.get(contact, "ground_station_id"),
        Map.get(contact, "station"),
        Map.get(contact, "ground_station"),
        Map.get(contact, "starts_at_s"),
        Map.get(contact, "ends_at_s"),
        Map.get(contact, "source_window_id"),
        Map.get(contact, "source_window"),
        get_in(contact, ["metadata", "source_window"]),
        get_in(contact, ["activity_context", "source_window"]),
        estimated_throughput_value(contact),
        actual_throughput_value(contact),
        completed_fraction_value(contact)
      ],
      fn value -> not is_nil(value) end
    )
  end

  defp actual_throughput_value(contact) do
    explicit_actual_throughput_value(contact) || actual_data_rate_derived_throughput_mb(contact)
  end

  defp explicit_actual_throughput_value(contact) do
    first_number([
      contact["actual_throughput_mb"],
      contact["actual_downlink_mb"],
      contact["actual_data_volume_mb"],
      contact["delivered_data_mb"],
      contact["received_data_mb"],
      get_in(contact, ["throughput_model", "actual_throughput_mb"]),
      get_in(contact, ["throughput_model", "actual_downlink_mb"]),
      get_in(contact, ["throughput_model", "actual_data_volume_mb"]),
      get_in(contact, ["throughput_model", "delivered_data_mb"]),
      get_in(contact, ["throughput_model", "received_data_mb"])
    ])
  end

  defp estimated_throughput_value(contact) do
    first_number([
      contact["estimated_throughput_mb"],
      contact["estimated_downlink_mb"],
      contact["planned_throughput_mb"],
      get_in(contact, ["throughput_model", "estimated_throughput_mb"]),
      get_in(contact, ["throughput_model", "estimated_downlink_mb"]),
      get_in(contact, ["throughput_model", "planned_throughput_mb"])
    ])
  end

  defp completed_fraction_value(contact) do
    first_unit_interval(completed_fraction_candidates(contact))
  end

  defp actual_data_rate_derived_throughput_mb(contact) do
    case actual_data_rate_throughput_derivation(contact) do
      %{"actual_throughput_mb" => actual_throughput_mb} when is_number(actual_throughput_mb) ->
        actual_throughput_mb

      _derivation ->
        nil
    end
  end

  defp actual_data_rate_throughput_derivation(contact) do
    duration_s = actual_duration_s(contact)

    cond do
      is_number(explicit_actual_throughput_value(contact)) ->
        nil

      not is_number(duration_s) or duration_s <= 0.0 ->
        nil

      rate_mb_s = actual_data_rate_mb_s(contact) ->
        normalized_rate_mb_s = max(rate_mb_s, 0.0)

        %{
          "derivation" => "actual_data_rate_mb_s * duration_s",
          "rate_unit" => "MB/s",
          "actual_data_rate_mb_s" => normalized_rate_mb_s,
          "duration_s" => duration_s,
          "actual_throughput_mb" => normalized_rate_mb_s * duration_s
        }

      rate_mbps = actual_data_rate_mbps(contact) ->
        normalized_rate_mbps = max(rate_mbps, 0.0)

        %{
          "derivation" => "actual_data_rate_mbps * duration_s / 8",
          "rate_unit" => "Mbps",
          "actual_data_rate_mbps" => normalized_rate_mbps,
          "duration_s" => duration_s,
          "actual_throughput_mb" => normalized_rate_mbps * duration_s / 8.0
        }

      true ->
        nil
    end
  end

  defp actual_data_rate_mb_s(contact) do
    first_number([
      contact["actual_data_rate_mb_s"],
      contact["actual_downlink_rate_mb_s"],
      contact["delivered_rate_mb_s"],
      contact["received_rate_mb_s"],
      get_in(contact, ["throughput_model", "actual_data_rate_mb_s"]),
      get_in(contact, ["throughput_model", "actual_downlink_rate_mb_s"]),
      get_in(contact, ["throughput_model", "delivered_rate_mb_s"]),
      get_in(contact, ["throughput_model", "received_rate_mb_s"])
    ])
  end

  defp actual_data_rate_mbps(contact) do
    first_number([
      contact["actual_data_rate_mbps"],
      contact["actual_downlink_rate_mbps"],
      contact["delivered_rate_mbps"],
      contact["received_rate_mbps"],
      get_in(contact, ["throughput_model", "actual_data_rate_mbps"]),
      get_in(contact, ["throughput_model", "actual_downlink_rate_mbps"]),
      get_in(contact, ["throughput_model", "delivered_rate_mbps"]),
      get_in(contact, ["throughput_model", "received_rate_mbps"])
    ])
  end

  defp actual_duration_s(contact) do
    first_number([
      contact["actual_duration_s"],
      contact["actual_contact_duration_s"],
      get_in(contact, ["throughput_model", "actual_duration_s"]),
      get_in(contact, ["throughput_model", "actual_contact_duration_s"])
    ]) || contact_duration_s(contact)
  end

  defp contact_duration_s(contact) do
    first_number([
      contact["duration_s"],
      contact["contact_duration_s"],
      contact["scheduled_duration_s"],
      get_in(contact, ["throughput_model", "duration_s"]),
      get_in(contact, ["throughput_model", "contact_duration_s"]),
      get_in(contact, ["throughput_model", "scheduled_duration_s"])
    ]) || interval_duration_s(contact)
  end

  defp interval_duration_s(contact) do
    starts_at_s = numeric_or_nil(contact["starts_at_s"])
    ends_at_s = numeric_or_nil(contact["ends_at_s"])

    if is_number(starts_at_s) and is_number(ends_at_s) do
      ends_at_s - starts_at_s
    end
  end

  defp downlink_completion_context(contact) do
    %{
      "required_downlink_mb" =>
        first_number([
          contact["required_downlink_mb"],
          get_in(contact, ["throughput_model", "required_downlink_mb"]),
          get_in(contact, ["activity_context", "required_downlink_mb"])
        ]),
      "candidate_downlink_mb" =>
        first_number([
          contact["candidate_downlink_mb"],
          get_in(contact, ["throughput_model", "candidate_downlink_mb"]),
          get_in(contact, ["activity_context", "candidate_downlink_mb"])
        ]),
      "downlink_completion_ratio" =>
        first_number([
          contact["downlink_completion_ratio"],
          get_in(contact, ["throughput_model", "downlink_completion_ratio"]),
          get_in(contact, ["activity_context", "downlink_completion_ratio"])
        ]),
      "selected_downlink_shortfall_mb" =>
        first_number([
          contact["selected_downlink_shortfall_mb"],
          get_in(contact, ["throughput_model", "selected_downlink_shortfall_mb"]),
          get_in(contact, ["activity_context", "selected_downlink_shortfall_mb"])
        ]),
      "downlink_requirement_status" =>
        first_string([
          contact["downlink_requirement_status"],
          get_in(contact, ["throughput_model", "downlink_requirement_status"]),
          get_in(contact, ["activity_context", "downlink_requirement_status"])
        ]),
      "downlink_completion_source" =>
        first_string([
          contact["downlink_completion_source"],
          get_in(contact, ["throughput_model", "downlink_completion_source"]),
          get_in(contact, ["activity_context", "downlink_completion_source"])
        ]),
      "downlink_completion_sources" =>
        first_string_list([
          contact["downlink_completion_sources"],
          get_in(contact, ["throughput_model", "downlink_completion_sources"]),
          get_in(contact, ["activity_context", "downlink_completion_sources"])
        ])
    }
  end

  defp required_capacity_fraction_value(contact) do
    first_unit_interval(required_capacity_fraction_candidates(contact))
  end

  defp required_capacity_fraction_source(contact) do
    cond do
      valid_capacity_value_declared?(contact["required_capacity_fraction"]) or
        valid_capacity_value_declared?(contact["required_station_capacity_fraction"]) or
        valid_capacity_value_declared?(contact["station_capacity_requirement"]) or
        valid_capacity_percent_declared?(contact["required_capacity_percent"]) or
        valid_capacity_percent_declared?(contact["required_station_capacity_percent"]) or
          valid_capacity_percent_declared?(contact["station_capacity_requirement_percent"]) ->
        nil

      valid_capacity_value_declared?(
        get_in(contact, ["throughput_model", "required_capacity_fraction"])
      ) or
        valid_capacity_value_declared?(
          get_in(contact, ["throughput_model", "required_station_capacity_fraction"])
        ) or
        valid_capacity_value_declared?(
          get_in(contact, ["throughput_model", "station_capacity_requirement"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["throughput_model", "required_capacity_percent"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["throughput_model", "required_station_capacity_percent"])
        ) or
          valid_capacity_percent_declared?(
            get_in(contact, ["throughput_model", "station_capacity_requirement_percent"])
          ) ->
        "throughput_model"

      valid_capacity_value_declared?(
        get_in(contact, ["capacity_model", "required_capacity_fraction"])
      ) or
        valid_capacity_value_declared?(
          get_in(contact, ["capacity_model", "required_station_capacity_fraction"])
        ) or
        valid_capacity_value_declared?(
          get_in(contact, ["capacity_model", "station_capacity_requirement"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["capacity_model", "required_capacity_percent"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["capacity_model", "required_station_capacity_percent"])
        ) or
          valid_capacity_percent_declared?(
            get_in(contact, ["capacity_model", "station_capacity_requirement_percent"])
          ) ->
        "capacity_model"

      valid_capacity_value_declared?(
        get_in(contact, ["activity_context", "required_capacity_fraction"])
      ) or
        valid_capacity_value_declared?(
          get_in(contact, ["activity_context", "required_station_capacity_fraction"])
        ) or
        valid_capacity_value_declared?(
          get_in(contact, ["activity_context", "station_capacity_requirement"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["activity_context", "required_capacity_percent"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["activity_context", "required_station_capacity_percent"])
        ) or
          valid_capacity_percent_declared?(
            get_in(contact, ["activity_context", "station_capacity_requirement_percent"])
          ) ->
        "activity_context"

      true ->
        nil
    end
  end

  defp valid_capacity_value_declared?(value) do
    case numeric_or_nil(value) do
      value when is_number(value) -> unit_interval?(value)
      _value -> false
    end
  end

  defp valid_capacity_percent_declared?(value) do
    case numeric_or_nil(value) do
      value when is_number(value) -> value >= 0.0 and value <= 100.0
      _value -> false
    end
  end

  defp contact_feedback_factor(contact, key) do
    first_unit_interval(contact_feedback_factor_candidates(contact, key))
  end

  defp contact_boolean_value(contact, key) do
    contact
    |> contact_value(key)
    |> boolean_value()
  end

  defp boolean_value(value) when is_boolean(value), do: value

  defp boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "true" -> true
      "1" -> true
      "false" -> false
      "0" -> false
      _value -> nil
    end
  end

  defp boolean_value(_value), do: nil

  defp contact_value(contact, key) do
    case Map.fetch(contact, key) do
      {:ok, nil} -> get_in(contact, ["metadata", key])
      {:ok, value} -> value
      :error -> get_in(contact, ["metadata", key])
    end
  end

  defp first_number(values), do: Enum.find_value(values, &numeric_or_nil/1)

  defp first_unit_interval(values) do
    Enum.find_value(values, fn value ->
      case numeric_or_nil(value) do
        value when is_number(value) -> if(unit_interval?(value), do: value)
        _value -> nil
      end
    end)
  end

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp first_string(values) do
    Enum.find(values, &(is_binary(&1) and &1 != ""))
  end

  defp first_string_list(values) do
    Enum.find_value(values, fn
      values when is_list(values) ->
        values =
          values
          |> Enum.map(fn
            value when is_binary(value) -> value
            value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
            value when is_integer(value) -> Integer.to_string(value)
            _value -> nil
          end)
          |> Enum.reject(&(&1 == ""))
          |> Enum.reject(&is_nil/1)

        if values == [], do: nil, else: values

      _value ->
        nil
    end)
  end

  defp invalid_contact_input?(contact), do: not contact_candidate?(contact)

  defp invalid_contact_input_reason(contact) do
    cond do
      Map.get(contact, "invalid_contact_shape") == true ->
        "invalid_contact_shape"

      reason = contact_id_issue(contact) ->
        reason

      reason = contact_identity_issue(contact) ->
        reason

      is_nil(Map.get(contact, "ground_station_id")) ->
        "missing_ground_station_id"

      not is_number(Map.get(contact, "starts_at_s")) ->
        "missing_contact_starts_at_s"

      not is_number(Map.get(contact, "ends_at_s")) ->
        "missing_contact_ends_at_s"

      invalid_unit_interval_declared?(station_capacity_fraction_candidates(contact)) ->
        "invalid_capacity_fraction"

      invalid_percent_declared?(station_capacity_percent_candidates(contact)) ->
        "invalid_capacity_fraction"

      invalid_unit_interval_declared?(required_capacity_fraction_candidates(contact)) ->
        "invalid_required_capacity_fraction"

      invalid_percent_declared?(required_capacity_percent_candidates(contact)) ->
        "invalid_required_capacity_fraction"

      invalid_unit_interval_declared?(completed_fraction_candidates(contact)) ->
        "invalid_completed_fraction"

      invalid_unit_interval_declared?(
        contact_feedback_factor_candidates(contact, "contact_success_factor")
      ) ->
        "invalid_contact_success_factor"

      invalid_unit_interval_declared?(
        contact_feedback_factor_candidates(contact, "command_success_factor")
      ) ->
        "invalid_command_success_factor"

      true ->
        "invalid_contact_input"
    end
  end

  defp completed_fraction_candidates(contact) do
    [
      contact["completed_fraction"],
      contact["completion_fraction"],
      contact["contact_completion_fraction"],
      get_in(contact, ["throughput_model", "completed_fraction"]),
      get_in(contact, ["throughput_model", "completion_fraction"]),
      get_in(contact, ["throughput_model", "contact_completion_fraction"])
    ]
  end

  defp contact_feedback_factor_candidates(contact, key) do
    [contact_value(contact, key)]
  end

  defp station_capacity_fraction_candidates(contact) do
    capacity_value_candidates(contact, @station_capacity_value_paths) ++
      source_station_capacity_fraction_candidates(contact["source_station_calendar_entry"]) ++
      source_station_capacity_overlap_fraction_candidates(contact)
  end

  defp required_capacity_fraction_candidates(contact) do
    capacity_value_candidates(contact, @required_capacity_value_paths)
  end

  defp station_capacity_percent_candidates(contact) do
    path_values(contact, @station_capacity_percent_paths) ++
      source_station_capacity_percent_candidates(contact["source_station_calendar_entry"]) ++
      source_station_capacity_overlap_percent_candidates(contact)
  end

  defp source_station_capacity_overlap_fraction_candidates(contact) do
    if station_calendar_entry_ambiguous?(contact) do
      []
    else
      source_station_capacity_fraction_candidates(contact["source_station_calendar_overlaps"])
    end
  end

  defp source_station_capacity_overlap_percent_candidates(contact) do
    if station_calendar_entry_ambiguous?(contact) do
      []
    else
      source_station_capacity_percent_candidates(contact["source_station_calendar_overlaps"])
    end
  end

  defp station_calendar_entry_ambiguous?(contact) do
    contact["station_calendar_entry_ambiguous"] == true ||
      get_in(contact, ["source_station_calendar_entry", "station_calendar_entry_ambiguous"]) ==
        true
  end

  defp source_station_capacity_fraction_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_capacity_fraction_candidates/1)

  defp source_station_capacity_fraction_candidates(%{} = source) do
    capacity_value_candidates(source, @station_capacity_value_paths)
  end

  defp source_station_capacity_fraction_candidates(_source), do: []

  defp source_station_capacity_percent_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_capacity_percent_candidates/1)

  defp source_station_capacity_percent_candidates(%{} = source) do
    path_values(source, @station_capacity_percent_paths)
  end

  defp source_station_capacity_percent_candidates(_source), do: []

  defp required_capacity_percent_candidates(contact) do
    path_values(contact, @required_capacity_percent_paths)
  end

  defp capacity_value_candidates(value, paths) do
    Enum.map(paths, fn
      {:fraction, path} ->
        path_value(value, path)

      {:percent, path} ->
        capacity_percent_fraction(path_value(value, path))
    end)
  end

  defp path_values(value, paths), do: Enum.map(paths, &path_value(value, &1))

  defp path_value(value, [field]), do: Map.get(value, field)
  defp path_value(value, path), do: get_in(value, path)

  defp capacity_percent_fraction(value) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end

  defp invalid_unit_interval_declared?(values) do
    Enum.any?(values, fn value ->
      case numeric_or_nil(value) do
        value when is_number(value) -> not unit_interval?(value)
        _value -> false
      end
    end)
  end

  defp invalid_percent_declared?(values) do
    Enum.any?(values, fn value ->
      case numeric_or_nil(value) do
        value when is_number(value) -> value < 0.0 or value > 100.0
        _value -> false
      end
    end)
  end

  defp unit_interval?(value) when is_number(value), do: value >= 0.0 and value <= 1.0

  defp station_calendar_trust_boundary_status_counts(rows) do
    counts =
      rows
      |> Enum.map(& &1["station_calendar_trust_boundary_status"])
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()

    if counts == %{}, do: nil, else: counts
  end

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {key, _count} -> key end)
    |> Map.new()
  end

  defp row_values(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp first_present(rows, field) do
    Enum.find_value(rows, &Map.get(&1, field))
  end

  defp contact_direction(%{"direction" => direction})
       when is_binary(direction) and direction != "",
       do: direction

  defp contact_direction(%{"type" => "command"}), do: "command"
  defp contact_direction(%{"type" => "tracking"}), do: "tracking"
  defp contact_direction(%{"type" => "health_check"}), do: "health_check"
  defp contact_direction(_contact), do: "downlink"

  defp contact_type_from_direction(%{"direction" => "downlink"}), do: "downlink"

  defp contact_type_from_direction(%{"direction" => direction})
       when direction in @contact_directions,
       do: "planned_contact"

  defp contact_type_from_direction(contact) do
    if provider_downlink_contact_input?(contact), do: "downlink"
  end

  defp contact_id(contact) do
    case contact_id_or_nil(contact) do
      nil -> raise ArgumentError, "contact id is required"
      value -> value
    end
  end

  defp contact_id_or_nil(contact) do
    case Map.get(contact, "id") || Map.get(contact, "contact_id") ||
           Map.get(contact, "activity_id") do
      value when is_binary(value) and value != "" -> stable_id_or_nil(value)
      value when is_atom(value) and not is_nil(value) -> stable_id_or_nil(value)
      value when is_integer(value) -> stable_id_or_nil(value)
      _value -> nil
    end
  end

  defp invalid_contact_row_id("invalid_contact_shape", index), do: "missing_contact_id:#{index}"
  defp invalid_contact_row_id(reason, index), do: "#{reason}:#{index}"

  defp contact_id_issue(contact) do
    raw_id =
      Map.get(contact, "id") || Map.get(contact, "contact_id") ||
        Map.get(contact, "activity_id")

    cond do
      raw_id in [nil, ""] -> "missing_contact_id"
      stable_id?(raw_id) -> nil
      true -> "invalid_contact_id"
    end
  end

  defp contact_spacecraft_id(contact) do
    spacecraft_identity_value(contact["spacecraft_id"]) ||
      spacecraft_identity_value(contact["satellite_id"]) ||
      spacecraft_identity_value(contact["spacecraft"]) ||
      spacecraft_identity_value(contact["satellite"]) ||
      stable_id_or_nil(contact["scenario_id"])
  end

  defp spacecraft_identity_value(%{} = spacecraft) do
    Enum.find_value(["spacecraft_id", "satellite_id", "id"], fn field ->
      spacecraft_identity_value(Map.get(spacecraft, field))
    end)
  end

  defp spacecraft_identity_value(value), do: stable_id_or_nil(value)

  defp contact_identity_issue(contact) do
    Enum.find_value(@contact_stable_identity_fields, fn field ->
      value = Map.get(contact, field)

      cond do
        value in [nil, ""] -> nil
        stable_id?(value) -> nil
        true -> "invalid_#{field}"
      end
    end)
  end

  defp stable_id?(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id?()
  end

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  defp stable_id?(_value), do: false

  defp stable_id_or_nil(nil), do: nil
  defp stable_id_or_nil("nil"), do: nil
  defp stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  defp stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(_value), do: nil

  defp normalize_station_calendar_id_lists(context) do
    Enum.reduce(
      [
        "station_calendar_overlap_entry_ids",
        "station_calendar_ambiguous_entry_ids",
        "station_calendar_reservation_ids"
      ],
      context,
      fn field, acc ->
        case normalize_id_list(Map.get(acc, field)) do
          nil -> Map.delete(acc, field)
          ids -> Map.put(acc, field, ids)
        end
      end
    )
  end

  defp normalize_station_calendar_number_lists(context) do
    Enum.reduce(
      ["station_calendar_reservation_expires_at_s"],
      context,
      fn field, acc ->
        case normalize_number_list(Map.get(acc, field)) do
          nil -> Map.delete(acc, field)
          values -> Map.put(acc, field, values)
        end
      end
    )
  end

  defp contact_station_calendar_entry_id(contact) do
    stable_id_or_nil(contact["station_calendar_entry_id"]) ||
      stable_id_or_nil(
        get_in(contact, ["source_station_calendar_entry", "station_calendar_entry_id"])
      ) ||
      stable_id_or_nil(get_in(contact, ["source_station_calendar_entry", "id"]))
  end

  defp contact_station_calendar_provider_id(contact) do
    stable_id_or_nil(contact["station_calendar_provider_id"]) ||
      stable_id_or_nil(
        get_in(contact, ["source_station_calendar_entry", "station_calendar_provider_id"])
      ) ||
      stable_id_or_nil(get_in(contact, ["source_station_calendar_entry", "provider_id"])) ||
      stable_id_or_nil(get_in(contact, ["provenance", "provider_id"]))
  end

  defp contact_station_calendar_provider_entry_id(contact) do
    stable_id_or_nil(contact["station_calendar_provider_entry_id"]) ||
      stable_id_or_nil(
        get_in(contact, ["source_station_calendar_entry", "station_calendar_provider_entry_id"])
      ) ||
      stable_id_or_nil(get_in(contact, ["source_station_calendar_entry", "provider_entry_id"])) ||
      stable_id_or_nil(get_in(contact, ["source_station_calendar_entry", "id"]))
  end

  defp normalize_id_list(nil), do: nil

  defp normalize_id_list(values) when is_list(values) do
    values
    |> Enum.flat_map(&id_values/1)
    |> Enum.flat_map(&stable_id_value/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp normalize_id_list(value), do: normalize_id_list([value])

  defp normalize_number_list(nil), do: nil

  defp normalize_number_list(values) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.map(&numeric_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  defp normalize_number_list(value), do: normalize_number_list([value])

  defp reservation_expires_at_s(contact) do
    [
      contact["station_reservation_expires_at_s"],
      contact["reservation_expires_at_s"],
      contact["reservation_hold_expires_at_s"],
      contact["hold_expires_at_s"],
      contact["expires_at_s"],
      contact["expires_at"],
      get_in(contact, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
      get_in(contact, ["source_station_calendar_entry", "reservation_expires_at_s"]),
      get_in(contact, ["source_station_calendar_entry", "reservation_hold_expires_at_s"]),
      get_in(contact, ["source_station_calendar_entry", "hold_expires_at_s"]),
      get_in(contact, ["source_station_calendar_entry", "expires_at_s"])
    ]
    |> Enum.find_value(&numeric_or_nil/1)
  end

  defp derive_station_calendar_counts(context) do
    context
    |> derive_station_calendar_count(
      "station_calendar_overlap_count",
      "station_calendar_overlap_entry_ids"
    )
    |> derive_station_calendar_count(
      "station_calendar_ambiguous_entry_count",
      "station_calendar_ambiguous_entry_ids"
    )
    |> derive_station_calendar_count(
      "station_calendar_reservation_overlap_count",
      "station_calendar_reservation_ids"
    )
  end

  defp derive_station_calendar_count(context, count_field, id_field) do
    case Map.get(context, id_field) do
      ids when is_list(ids) -> Map.put(context, count_field, length(ids))
      _ids -> context
    end
  end

  defp id_values(%{} = value) do
    ["id", "station_calendar_entry_id", "station_reservation_id", "reservation_id"]
    |> Enum.flat_map(fn key ->
      case Map.get(value, key) do
        nil -> []
        nested when is_list(nested) -> nested
        nested -> [nested]
      end
    end)
  end

  defp id_values(value), do: [value]

  defp stable_id_value(nil), do: []
  defp stable_id_value(value) when is_boolean(value), do: []

  defp stable_id_value(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_value()

  defp stable_id_value("nil"), do: []

  defp stable_id_value(value) when is_binary(value),
    do: if(stable_id?(value), do: [value], else: [])

  defp stable_id_value(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_value()

  defp stable_id_value(_value), do: []

  defp normalize_contact(%{} = contact) do
    contact
    |> stringify_keys()
    |> normalize_station_id()
    |> normalize_contact_time("starts_at_s", "start_s")
    |> normalize_contact_time("ends_at_s", "end_s")
    |> normalize_source_window()
    |> normalize_station_calendar_status_fields()
    |> normalize_activity_type_alias()
    |> normalize_contact_direction()
  end

  defp normalize_contact(contact) do
    %{
      "invalid_contact_shape" => true,
      "raw_input" => inspect(contact)
    }
  end

  defp normalize_station_id(%{"ground_station_id" => station_id} = contact)
       when not is_nil(station_id),
       do: contact

  defp normalize_station_id(%{"station_id" => station_id} = contact) when not is_nil(station_id),
    do: Map.put(contact, "ground_station_id", station_id)

  defp normalize_station_id(contact) do
    case nested_station_id(contact) do
      nil -> contact
      station_id -> Map.put(contact, "ground_station_id", station_id)
    end
  end

  defp normalize_source_window(%{"source_window" => %{} = source_window} = contact) do
    source_window = normalize_source_window_payload(source_window)

    contact
    |> Map.put("source_window", source_window)
    |> put_new_present("source_window_id", source_window_id_value(source_window))
    |> put_new_present("source_window_type", source_window_type_value(source_window))
    |> put_new_present("source_window_type", Map.get(contact, "source_window_kind"))
  end

  defp normalize_source_window(
         %{"metadata" => %{"source_window" => %{} = source_window}} = contact
       ) do
    source_window = normalize_source_window_payload(source_window)

    contact
    |> Map.put("source_window", source_window)
    |> put_new_present("source_window_id", source_window_id_value(source_window))
    |> put_new_present("source_window_type", source_window_type_value(source_window))
    |> put_new_present("source_window_type", get_in(contact, ["metadata", "source_window_kind"]))
  end

  defp normalize_source_window(
         %{"activity_context" => %{"source_window" => %{} = source_window}} = contact
       ) do
    source_window = normalize_source_window_payload(source_window)

    contact
    |> Map.put("source_window", source_window)
    |> put_new_present("source_window_id", source_window_id_value(source_window))
    |> put_new_present("source_window_type", source_window_type_value(source_window))
    |> put_new_present(
      "source_window_type",
      get_in(contact, ["activity_context", "source_window_kind"])
    )
  end

  defp normalize_source_window(contact) do
    contact
    |> put_new_present("source_window_type", Map.get(contact, "source_window_kind"))
    |> put_new_present("source_window_type", get_in(contact, ["metadata", "source_window_kind"]))
    |> put_new_present(
      "source_window_type",
      get_in(contact, ["activity_context", "source_window_kind"])
    )
  end

  defp normalize_source_window_payload(source_window) do
    source_window
    |> put_new_present("id", source_window_id_value(source_window))
    |> put_new_present("type", source_window_type_value(source_window))
  end

  defp source_window_id_value(%{} = source_window) do
    Map.get(source_window, "id") || Map.get(source_window, "window_id")
  end

  defp source_window_type_value(%{} = source_window) do
    Map.get(source_window, "type") || Map.get(source_window, "kind") ||
      Map.get(source_window, "window_type")
  end

  defp put_new_present(contact, _key, value) when value in [nil, ""], do: contact

  defp put_new_present(contact, key, value), do: Map.put_new(contact, key, value)

  defp nested_station_id(contact) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(contact, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp normalize_station_calendar_status_fields(row) do
    row
    |> normalize_status_field("availability")
    |> normalize_status_field("status")
    |> normalize_status_field("station_availability")
    |> normalize_status_field("station_calendar_status")
    |> normalize_status_field("station_calendar_precedence_availability")
    |> normalize_status_field("station_contention_status")
    |> normalize_status_field("reservation_status")
    |> normalize_status_field("station_reservation_status")
    |> normalize_status_field("reservation_match_status")
    |> normalize_status_field("station_reservation_match_status")
    |> normalize_status_list_field("station_calendar_overlap_availabilities")
    |> normalize_status_list_field("station_calendar_reservation_statuses")
    |> normalize_source_station_calendar_field("source_station_calendar_entry")
    |> normalize_source_station_calendar_field("source_station_calendar_overlaps")
  end

  defp normalize_status_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, value} when value in [nil, ""] ->
        row

      {:ok, value} ->
        Map.put(row, field, normalized_status_token(value))

      :error ->
        row
    end
  end

  defp normalize_status_list_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, values} when is_list(values) ->
        values =
          values
          |> Enum.map(&normalized_status_token/1)
          |> Enum.reject(&(&1 in [nil, ""]))

        Map.put(row, field, values)

      {:ok, value} when value not in [nil, ""] ->
        Map.put(row, field, [normalized_status_token(value)])

      _missing_or_empty ->
        row
    end
  end

  defp normalize_source_station_calendar_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, values} when is_list(values) ->
        Map.put(row, field, Enum.map(values, &normalize_source_station_calendar/1))

      {:ok, value} ->
        Map.put(row, field, normalize_source_station_calendar(value))

      :error ->
        row
    end
  end

  defp normalize_source_station_calendar(%{} = source),
    do: normalize_station_calendar_status_fields(source)

  defp normalize_source_station_calendar(value), do: value

  defp normalized_status_token(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> canonical_status_token()
  end

  defp normalized_status_token(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalized_status_token()
  end

  defp normalized_status_token(value), do: value

  defp canonical_status_token(value) when value in @unavailable_aliases, do: "unavailable"
  defp canonical_status_token(value), do: value

  defp normalize_contact_time(contact, canonical_key, alternate_key) do
    case numeric_or_nil(Map.get(contact, canonical_key)) ||
           numeric_or_nil(Map.get(contact, alternate_key)) do
      value when is_number(value) -> Map.put(contact, canonical_key, value)
      _value -> contact
    end
  end

  defp normalize_activity_type_alias(%{"type" => type} = contact) when not is_nil(type),
    do: contact

  defp normalize_activity_type_alias(%{"activity_type" => type} = contact)
       when is_binary(type) and type != "",
       do: Map.put(contact, "type", type)

  defp normalize_activity_type_alias(contact), do: contact

  defp normalize_contact_direction(%{"direction" => direction} = contact) do
    case normalize_direction(direction) do
      nil -> contact
      direction -> Map.put(contact, "direction", direction)
    end
  end

  defp normalize_contact_direction(%{"type" => "downlink"} = contact),
    do: Map.put(contact, "direction", "downlink")

  defp normalize_contact_direction(%{"type" => "tracking"} = contact),
    do: Map.put(contact, "direction", "tracking")

  defp normalize_contact_direction(%{"type" => "command"} = contact),
    do: Map.put(contact, "direction", "command")

  defp normalize_contact_direction(%{"type" => "health_check"} = contact),
    do: Map.put(contact, "direction", "health_check")

  defp normalize_contact_direction(contact), do: contact

  defp normalize_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_direction(direction) do
    direction
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      "uplink" -> "uplink"
      "downlink" -> "downlink"
      "tracking" -> "tracking"
      "health_check" -> "health_check"
      "nil" -> nil
      "" -> nil
      value -> Map.get(@provider_direction_aliases, value, value)
    end
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp provider_result_values(values) when is_list(values) do
    values
    |> Enum.flat_map(&provider_result_values/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(%{} = result) do
    @provider_result_map_value_keys
    |> Enum.flat_map(fn key -> provider_result_values(Map.get(result, key)) end)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> []
      normalized -> [normalized]
    end
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(value) when is_atom(value),
    do: provider_result_values(Atom.to_string(value))

  defp provider_result_values(value), do: provider_result_values(to_string(value))

  defp provider_result_artifact_value(value) do
    case provider_result_values(value) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
