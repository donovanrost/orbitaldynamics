defmodule OrbitalDynamics.Communications.ContactAllocation do
  @moduledoc """
  Deterministic artifact-only contact allocation review.

  This module composes the existing ground-network filter and same-station
  contention resolver into an allocation report with allocated, deferred, and
  blocked contact rows. It does not reserve provider time, mutate schedules, or
  approve contacts.
  """

  alias OrbitalDynamics.ResourceFilter

  alias OrbitalDynamics.Communications.{
    ContactContention,
    ContactFilter,
    DownlinkLinkBudget,
    StationCalendar
  }

  alias OrbitalDynamics.Communications.ContactAllocation.{
    AllocationRow,
    AllocationSummary,
    ApprovalPolicy,
    CapacityPacking,
    ContactValidation,
    ProviderCounteroffer,
    ReturnedAllocation,
    StationCapacityEvidence,
    ThroughputEvidence
  }

  @schema_contract "contact_allocation_report.v1"
  @summary_schema_contract "contact_allocation_summary.v1"
  @station_pressure_summary_schema_contract "contact_allocation_station_pressure_summary.v1"
  @capacity_pack_summary_schema_contract "contact_allocation_capacity_pack_summary.v1"
  @reservation_conflict_summary_schema_contract "contact_allocation_reservation_conflict_summary.v1"
  @provider_reservation_request_summary_schema_contract "contact_allocation_provider_reservation_request_summary.v1"
  @contact_types ~w(downlink planned_contact tracking command health_check)
  @contact_directions ~w(downlink uplink command tracking health_check)
  @command_contact_directions ~w(command uplink)
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
      provider_counteroffer_fields: ProviderCounteroffer.fields(),
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

    normalized_contacts =
      contacts
      |> Enum.map(&normalize_contact/1)

    Enum.each(normalized_contacts, &DownlinkLinkBudget.evidence_for_contact/1)

    contact_inputs =
      normalized_contacts
      |> Enum.filter(&contact_like_input?/1)

    {invalid_contact_inputs, contacts} =
      contact_inputs
      |> Enum.with_index(1)
      |> Enum.split_with(fn {contact, _index} -> invalid_contact_input?(contact) end)

    valid_contacts = Enum.map(contacts, fn {contact, _index} -> contact end)
    duplicate_contact_groups = duplicate_contact_groups(valid_contacts)
    duplicate_contact_ids = duplicate_contact_ids(duplicate_contact_groups)
    ground_network = normalize_ground_network(ground_network)
    default_capacity_requirement = CapacityPacking.default_required_fraction(opts)

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

    deferred_by_contact_id = ReturnedAllocation.deferred_by_contact_id(resolution_report)
    selected_by_contact_id = ReturnedAllocation.selected_by_contact_id(resolution_report)

    {allocation_rows, reduced_capacity_pack_groups} =
      contention_contacts
      |> Enum.map(&allocation_row(&1, deferred_by_contact_id, selected_by_contact_id))
      |> Kernel.++(blocked_rows)
      |> Enum.sort_by(&ReturnedAllocation.allocation_sort_key/1)
      |> CapacityPacking.apply(default_capacity_requirement)

    allocation_rows =
      allocation_rows
      |> ApprovalPolicy.apply(approval_policy, @command_contact_directions)
      |> Enum.map(&ReturnedAllocation.put_effective_allocation_status/1)

    allocated_contacts =
      allocation_rows
      |> Enum.filter(&ReturnedAllocation.allocated_contact_row?/1)
      |> Enum.map(&ReturnedAllocation.allocated_contact_from_row(&1, contention_contacts))

    report =
      %{
        "schema_contract" => @schema_contract,
        "model" => "deterministic_station_contact_allocation",
        "source" => source,
        "input_contact_count" => length(contact_inputs),
        "calendar_entry_trust_boundary_status_counts" =>
          Map.get(station_calendar_report, "calendar_entry_trust_boundary_status_counts"),
        "invalid_contact_input_count" => length(invalid_contact_inputs),
        "invalid_contact_input_ids" =>
          Enum.map(invalid_contact_rows(invalid_contact_inputs), & &1["contact_id"]),
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
      |> Map.merge(AllocationSummary.report_fields(allocation_rows, reduced_capacity_pack_groups))
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
    AllocationSummary.build_station_pressure(
      report,
      model_limits(),
      station_pressure_capability_assumptions()
    )
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
    AllocationSummary.build_capacity_pack(
      report,
      model_limits(),
      capacity_pack_capability_assumptions()
    )
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
    AllocationSummary.build_reservation_conflict(
      report,
      opts,
      model_limits(),
      reservation_conflict_capability_assumptions()
    )
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
    AllocationSummary.build_provider_reservation_request(
      report,
      model_limits(),
      provider_reservation_request_capability_assumptions()
    )
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
    AllocationSummary.build(
      report,
      opts,
      model_limits(),
      allocation_summary_capability_assumptions()
    )
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
    AllocationRow.build(
      contact,
      deferred_by_contact_id,
      selected_by_contact_id,
      allocation_row_config()
    )
  end

  defp base_row(contact), do: AllocationRow.base(contact, allocation_row_config())

  defp resource_suppression_context(row), do: AllocationRow.resource_suppression_context(row)

  defp allocation_row_config do
    %{
      station_capacity_policy: station_capacity_policy(),
      provider_result_map_value_keys: @provider_result_map_value_keys,
      contact_directions: @contact_directions
    }
  end

  defp station_allocation_blocked?(contact),
    do: StationCapacityEvidence.station_allocation_blocked?(contact, station_capacity_policy())

  defp station_allocation_blocked_reason(contact),
    do:
      StationCapacityEvidence.station_allocation_blocked_reason(
        contact,
        station_capacity_policy()
      )

  defp status_allocation_blocked?(contact),
    do: ContactValidation.status_allocation_blocked?(contact)

  defp status_allocation_blocked_reason(contact),
    do: ContactValidation.status_allocation_blocked_reason(contact, station_capacity_policy())

  defp contact_candidate?(contact),
    do: ContactValidation.candidate?(contact, contact_validation_policy())

  defp contact_like_input?(contact),
    do: ContactValidation.contact_like_input?(contact, contact_validation_policy())

  defp provider_downlink_contact_input?(contact),
    do: ContactValidation.provider_downlink_contact_input?(contact)

  defp actual_throughput_value(contact) do
    ThroughputEvidence.actual_throughput(contact)
  end

  defp completed_fraction_value(contact), do: ContactValidation.completed_fraction_value(contact)

  defp actual_data_rate_throughput_derivation(contact) do
    ThroughputEvidence.actual_data_rate_derivation(contact)
  end

  defp downlink_completion_context(contact) do
    ThroughputEvidence.downlink_completion_context(contact)
  end

  defp required_capacity_fraction_value(contact),
    do:
      StationCapacityEvidence.required_capacity_fraction_value(contact, station_capacity_policy())

  defp required_capacity_fraction_source(contact),
    do: StationCapacityEvidence.required_capacity_fraction_source(contact)

  defp numeric_or_nil(value), do: StationCapacityEvidence.numeric_or_nil(value)

  defp invalid_contact_input?(contact), do: not contact_candidate?(contact)

  defp invalid_contact_input_reason(contact),
    do: ContactValidation.invalid_reason(contact, contact_validation_policy())

  defp station_capacity_policy do
    %{
      station_blocking_availability: @station_blocking_availability,
      station_availability_severity: @station_availability_severity,
      station_capacity_value_paths: @station_capacity_value_paths,
      station_capacity_percent_paths: @station_capacity_percent_paths,
      required_capacity_value_paths: @required_capacity_value_paths,
      required_capacity_percent_paths: @required_capacity_percent_paths
    }
  end

  defp contact_validation_policy do
    %{
      contact_types: @contact_types,
      contact_directions: @contact_directions,
      contact_stable_identity_fields: @contact_stable_identity_fields,
      station_capacity_policy: station_capacity_policy()
    }
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

  defp contact_id(contact),
    do: OrbitalDynamics.Communications.ContactAllocation.ContactIdentity.contact_id(contact)

  defp contact_id_or_nil(contact),
    do:
      OrbitalDynamics.Communications.ContactAllocation.ContactIdentity.contact_id_or_nil(contact)

  defp invalid_contact_row_id("invalid_contact_shape", index), do: "missing_contact_id:#{index}"
  defp invalid_contact_row_id(reason, index), do: "#{reason}:#{index}"

  defp contact_spacecraft_id(contact) do
    OrbitalDynamics.Communications.ContactAllocation.ContactIdentity.contact_spacecraft_id(
      contact
    )
  end

  defp stable_id_or_nil(value),
    do: OrbitalDynamics.Communications.ContactAllocation.ContactIdentity.stable_id_or_nil(value)

  defp normalize_contact(contact) do
    OrbitalDynamics.Communications.ContactAllocation.ContactNormalization.normalize(
      contact,
      {@unavailable_aliases, @provider_direction_aliases},
      &stringify_keys/1,
      &numeric_or_nil/1
    )
  end

  defp normalize_station_calendar_status_fields(row) do
    OrbitalDynamics.Communications.ContactAllocation.ContactNormalization.normalize_station_calendar_status_fields(
      row,
      @unavailable_aliases
    )
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

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
