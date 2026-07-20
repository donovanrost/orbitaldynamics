defmodule OrbitalDynamics.Communications.StationCalendar do
  @moduledoc """
  Declared station-calendar provider adapter.

  This adapter turns externally supplied station calendar rows into the
  ground-network interval shape already consumed by campaign repair. It does not
  call provider APIs, reserve station time, or mutate schedules.
  """

  @availability_precedence_order [
    "unavailable",
    "maintenance",
    "reserved",
    "reduced_capacity",
    "available"
  ]
  @provider_capacity_fraction_paths [
    ["capacity_pack_capacity_fraction"],
    ["capacity_fraction"],
    ["station_capacity_fraction"],
    ["availability"]
  ]
  @provider_capacity_percent_paths [
    ["capacity_percent"],
    ["station_capacity_percent"]
  ]
  @provider_capacity_value_paths for(
                                   path <- @provider_capacity_fraction_paths,
                                   do: {:fraction, path}
                                 ) ++
                                   for(
                                     path <- @provider_capacity_percent_paths,
                                     do: {:percent, path}
                                   )
  @provider_counteroffer_field_paths %{
    "provider_counteroffer_id" => [
      ["provider_counteroffer_id"],
      ["counteroffer_id"],
      ["offer_id"]
    ],
    "provider_counteroffer_status" => [
      ["provider_counteroffer_status"],
      ["counteroffer_status"],
      ["offer_status"],
      ["negotiation_status"]
    ],
    "provider_counteroffer_negotiation_state" => [
      ["provider_counteroffer_negotiation_state"],
      ["counteroffer_negotiation_state"],
      ["negotiation_state"],
      ["provider_counteroffer_status"],
      ["counteroffer_status"],
      ["offer_status"],
      ["negotiation_status"]
    ],
    "provider_counteroffer_reason_code" => [
      ["provider_counteroffer_reason_code"],
      ["counteroffer_reason_code"],
      ["offer_reason_code"],
      ["provider_reason_code"],
      ["reason_code"]
    ],
    "provider_counteroffer_cost_delta" => [
      ["provider_counteroffer_cost_delta"],
      ["counteroffer_cost_delta"],
      ["cost_delta"],
      ["price_delta"]
    ],
    "provider_counteroffer_lock_deadline_s" => [
      ["provider_counteroffer_lock_deadline_s"],
      ["counteroffer_lock_deadline_s"],
      ["schedule_lock_deadline_s"],
      ["lock_deadline_s"]
    ],
    "provider_counteroffer_starts_at_s" => [
      ["provider_counteroffer_starts_at_s"],
      ["counteroffer_starts_at_s"],
      ["counteroffer_start_s"],
      ["offered_starts_at_s"],
      ["offered_start_s"]
    ],
    "provider_counteroffer_ends_at_s" => [
      ["provider_counteroffer_ends_at_s"],
      ["counteroffer_ends_at_s"],
      ["counteroffer_end_s"],
      ["offered_ends_at_s"],
      ["offered_end_s"]
    ]
  }
  @schema_contract "station_calendar_report.v1"
  @reservation_schema_contract "station_reservation_report.v1"
  @precedence_summary_schema_contract "station_calendar_precedence_summary.v1"
  @reservation_review_summary_schema_contract "station_reservation_review_summary.v1"
  @reservation_hold_summary_schema_contract "station_reservation_hold_summary.v1"
  @reservation_hold_import_readiness_summary_schema_contract "station_reservation_hold_import_readiness_summary.v1"
  @counteroffer_schema_contract "provider_counteroffer_report.v1"
  @counteroffer_review_summary_schema_contract "provider_counteroffer_review_summary.v1"
  @counteroffer_import_readiness_summary_schema_contract "provider_counteroffer_import_readiness_summary.v1"
  @counteroffer_plan_impact_summary_schema_contract "provider_counteroffer_plan_impact_summary.v1"
  @provider_counteroffer_lock_deadline_statuses ~w(missing expired active declared)
  @provider_counteroffer_import_statuses ~w(review_required_before_import not_applicable)
  @provider_counteroffer_import_readiness_statuses ~w(clear review_required)
  @provider_counteroffer_import_classifications ~w(not_applicable review_only)
  @provider_counteroffer_plan_impact_statuses ~w(clear review_required)
  alias OrbitalDynamics.Communications.StationCalendar.ApprovalPolicy
  alias OrbitalDynamics.Communications.StationCalendar.Availability
  alias OrbitalDynamics.Communications.StationCalendar.CalendarInput
  alias OrbitalDynamics.Communications.StationCalendar.ProviderCounteroffer
  alias OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferHandoffSummary
  alias OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferReport
  alias OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferReviewSummary
  alias OrbitalDynamics.Communications.StationCalendar.ProviderContention
  alias OrbitalDynamics.Communications.StationCalendar.ProviderResult
  alias OrbitalDynamics.Communications.StationCalendar.PrecedenceSummary
  alias OrbitalDynamics.Communications.StationCalendar.ReservationSourceEvidence
  alias OrbitalDynamics.Communications.StationCalendar.ReservationReviewSummary
  alias OrbitalDynamics.Communications.StationCalendar.ReservationHoldImportReadinessSummary
  alias OrbitalDynamics.Communications.StationCalendar.ReservationSummaryValues
  alias OrbitalDynamics.Communications.StationCalendar.StationMatching

  @doc """
  Declares the station-calendar provider adapter contract and known limits.
  """
  def capabilities do
    %{
      provider_contract: "station_calendar_provider.v1",
      artifact_contract: @schema_contract,
      reservation_artifact_contract: @reservation_schema_contract,
      precedence_summary_artifact_contract: @precedence_summary_schema_contract,
      reservation_review_summary_artifact_contract: @reservation_review_summary_schema_contract,
      reservation_hold_summary_artifact_contract: @reservation_hold_summary_schema_contract,
      reservation_hold_import_readiness_summary_artifact_contract:
        @reservation_hold_import_readiness_summary_schema_contract,
      counteroffer_artifact_contract: @counteroffer_schema_contract,
      counteroffer_review_summary_artifact_contract: @counteroffer_review_summary_schema_contract,
      counteroffer_import_readiness_summary_artifact_contract:
        @counteroffer_import_readiness_summary_schema_contract,
      counteroffer_plan_impact_summary_artifact_contract:
        @counteroffer_plan_impact_summary_schema_contract,
      model: :declared_station_calendar_adapter,
      validation_level: :artifact_contract,
      inputs: [:declared_provider_calendar_entries],
      outputs: [
        :ground_network_intervals,
        :station_calendar_report,
        :station_reservation_report,
        :station_reservation_review_summary,
        :station_reservation_hold_summary,
        :station_reservation_hold_import_readiness_summary,
        :station_calendar_precedence_summary,
        :provider_counteroffer_report,
        :provider_counteroffer_review_summary,
        :provider_counteroffer_import_readiness_summary,
        :provider_counteroffer_plan_impact_summary
      ],
      public_facades: [
        :station_calendar_report,
        :station_calendar_ground_network,
        :station_reservation_report,
        :station_reservation_review_summary,
        :station_reservation_hold_summary,
        :station_reservation_hold_import_readiness_summary,
        :station_calendar_precedence_summary,
        :provider_counteroffer_report,
        :provider_counteroffer_review_summary,
        :provider_counteroffer_import_readiness_summary,
        :provider_counteroffer_plan_impact_summary
      ],
      handoff_artifacts: [
        "operator_review_package.v1",
        "cadence_import_manifest.v1"
      ],
      availability_values: Availability.values(),
      provider_availability_precedence_order: @availability_precedence_order,
      provider_unavailable_aliases: Availability.unavailable_aliases(),
      provider_reservation_hold_aliases: Availability.reservation_hold_aliases(),
      provider_capacity_fraction_paths: @provider_capacity_fraction_paths,
      provider_capacity_percent_paths: @provider_capacity_percent_paths,
      provider_capacity_value_paths: capacity_value_path_metadata(@provider_capacity_value_paths),
      provider_direction_aliases: StationMatching.provider_direction_aliases(),
      provider_result_map_value_keys: ProviderResult.map_value_keys(),
      command_contact_directions: StationMatching.command_contact_directions(),
      provider_counteroffer_actions: ["none", "review_provider_counteroffer"],
      provider_counteroffer_negotiation_states: ProviderCounteroffer.negotiation_states(),
      provider_counteroffer_lock_deadline_statuses: @provider_counteroffer_lock_deadline_statuses,
      provider_counteroffer_import_statuses: @provider_counteroffer_import_statuses,
      provider_counteroffer_import_readiness_statuses:
        @provider_counteroffer_import_readiness_statuses,
      provider_counteroffer_import_classifications: @provider_counteroffer_import_classifications,
      provider_counteroffer_plan_impact_statuses: @provider_counteroffer_plan_impact_statuses,
      provider_counteroffer_field_paths: @provider_counteroffer_field_paths,
      provider_counteroffer_review_type: "provider_counteroffer_review",
      provider_counteroffer_import_action: "review_provider_counteroffer",
      contention_values: ["reserved_overlap"],
      row_semantics: [
        :direction_scoped_station_calendar,
        :station_calendar_availability_precedence,
        :provider_direction_aliases,
        :provider_result_map_value_keys,
        :command_uplink_direction_compatibility,
        :station_calendar_trust_boundary_status,
        :affected_contact_review,
        :feedback_unit_interval_input_validation,
        :provider_entry_preservation,
        :station_calendar_provider_list_input,
        :provider_calendar_contention_groups,
        :station_reservation_report,
        :station_reservation_review_status,
        :station_reservation_review_count,
        :affected_contact_reservation_count,
        :provider_calendar_contention_group_count,
        :station_reservation_match_status,
        :station_reservation_match_status_counts,
        :station_calendar_trust_boundary_status_id_routing,
        :station_reservation_match_status_id_routing,
        :station_reservation_status_counts,
        :station_reservation_id_sets,
        :station_reservation_routing_id_sets,
        :station_reservation_owner_match,
        :station_reservation_review_summary,
        :station_reservation_expiration_status,
        :station_reservation_review_summary_expiration_routing_id_sets,
        :station_reservation_hold_summary,
        :station_reservation_hold_expiration_routing_id_sets,
        :station_reservation_hold_owner_routing_id_sets,
        :station_reservation_hold_import_readiness_summary,
        :station_reservation_hold_import_readiness_routing_id_sets,
        :station_calendar_precedence_summary,
        :station_calendar_precedence_routing_id_sets,
        :station_calendar_reserved_under_higher_precedence,
        :provider_unavailable_aliases,
        :provider_reservation_hold_aliases,
        :provider_capacity_fraction_paths,
        :provider_capacity_percent_aliases,
        :provider_capacity_value_paths,
        :provider_counteroffer_evidence,
        :provider_counteroffer_field_aliases,
        :provider_counteroffer_negotiation_state,
        :provider_counteroffer_review_summary,
        :provider_counteroffer_review_summary_deadline_routing_id_sets,
        :provider_counteroffer_import_readiness_summary,
        :provider_counteroffer_import_readiness_routing_id_sets,
        :provider_counteroffer_plan_impact_summary,
        :provider_counteroffer_plan_impact_routing_id_sets,
        :provider_counteroffer_lock_deadline_status,
        :provider_counteroffer_status_vocabularies,
        :provider_counteroffer_summary_row_derived_counts
      ],
      known_limits: [
        :declared_data_only,
        :no_network_calls,
        :no_provider_reservation,
        :no_schedule_mutation,
        :no_conflict_resolution
      ]
    }
  end

  defp capacity_value_path_metadata(paths) do
    Enum.map(paths, fn {unit, path} -> %{unit: unit, path: path} end)
  end

  @doc """
  Applies declared station-calendar entries to contact candidates.

  Returns annotated contacts plus a `station_calendar_report.v1`. The report is
  artifact-only: it describes affected contacts and capacity/availability
  overlays without reserving station time or mutating an external schedule.
  """
  def overlay_contacts(contacts, station_calendar, opts \\ [])

  def overlay_contacts(contacts, station_calendar, opts)
      when is_list(contacts) do
    source = opts |> Keyword.get(:source, "station_calendar") |> to_string()
    entries = normalize_calendar(station_calendar)

    {annotated, affected} =
      contacts
      |> Enum.map(&normalize_contact/1)
      |> Enum.map_reduce([], fn contact, affected ->
        case station_calendar_matches(contact, entries) do
          [] ->
            {contact, affected}

          matches ->
            entry = applied_station_calendar_entry(matches)
            annotated = annotate_station_calendar(contact, entry, matches)
            {annotated, [affected_contact(annotated, entry, matches) | affected]}
        end
      end)

    approval_policy = Keyword.get(opts, :approval_policy)

    provider_contention_groups =
      entries
      |> ProviderContention.groups()
      |> Enum.map(&maybe_apply_provider_contention_approval_policy(&1, approval_policy))

    affected =
      affected
      |> Enum.reverse()
      |> disambiguate_affected_contact_ids()
      |> Enum.map(&maybe_apply_approval_policy(&1, approval_policy))

    duplicate_affected_contact_id_groups = duplicate_affected_contact_id_groups(affected)

    {annotated,
     %{
       "schema_contract" => @schema_contract,
       "model" => "campaign_ground_network_interval_overlay",
       "input_contact_count" => Enum.count(annotated, &contact_row?/1),
       "calendar_entry_count" => length(entries),
       "calendar_entry_trust_boundary_status_counts" =>
         calendar_entry_trust_boundary_status_counts(entries),
       "provider_calendar_contention_group_count" => length(provider_contention_groups),
       "provider_calendar_contention_groups" => provider_contention_groups,
       "affected_contact_count" => length(affected),
       "affected_contact_ground_station_counts" => count_by(affected, "ground_station_id"),
       "affected_contact_availability_counts" => count_by(affected, "station_availability"),
       "direction_counts" => count_by(affected, "direction"),
       "station_calendar_status_counts" => count_by(affected, "station_calendar_status"),
       "station_calendar_trust_boundary_status_counts" =>
         station_calendar_trust_boundary_status_counts(affected),
       "affected_contact_ids_by_station_calendar_trust_boundary_status" =>
         affected_contact_ids_by_trust_boundary_status(affected),
       "station_reservation_match_status_counts" =>
         count_by(affected, "station_reservation_match_status"),
       "affected_contact_ids_by_reservation_match_status" =>
         affected_contact_ids_by_field(affected, "station_reservation_match_status"),
       "provider_counteroffer_count" => provider_counteroffer_count(affected),
       "duplicate_affected_contact_id_count" => length(duplicate_affected_contact_id_groups),
       "duplicate_affected_contact_row_count" =>
         duplicate_affected_contact_row_count(duplicate_affected_contact_id_groups),
       "affected_duration_s" => affected_duration_s(affected),
       "affected_contacts" => affected,
       "model_limits" => model_limits(),
       "assumptions" => %{
         "source" => source,
         "resolution" => "report_and_annotate_only_no_candidate_suppression",
         "matching" => "ground_station_id_and_time_interval_overlap",
         "duplicate_affected_contact_identity" =>
           "duplicate affected-contact row IDs are suffixed deterministically while preserving contact_id",
         "execution_boundary" => "artifact_only_no_provider_reservation"
       }
     }}
  end

  def overlay_contacts(_contacts, _station_calendar, _opts),
    do: raise(ArgumentError, "contacts must be a list")

  @doc """
  Builds a `station_calendar_report.v1` without returning annotated contacts.
  """
  def report(station_calendar_report)

  def report(%{"schema_contract" => @schema_contract} = report) do
    report
  end

  def report(%{schema_contract: @schema_contract} = report) do
    stringify_keys(report)
  end

  def report(_station_calendar_report),
    do: raise(ArgumentError, "station calendar report must be a station_calendar_report.v1 map")

  def report(contacts, station_calendar, opts \\ []) do
    {_contacts, report} = overlay_contacts(contacts, station_calendar, opts)
    report
  end

  @doc """
  Builds a compact artifact-only station-calendar precedence summary.

  The summary is derived from `station_calendar_report.v1` affected rows and
  exposes applied/overlap availability routing for reserved, unavailable,
  maintenance, and reduced-capacity overlays without mutating schedules or
  claiming provider reservation authority.
  """
  def precedence_summary(station_calendar_report)

  def precedence_summary(%{"schema_contract" => @precedence_summary_schema_contract} = summary),
    do: summary

  def precedence_summary(%{"schema_contract" => @schema_contract} = report) do
    PrecedenceSummary.build(report,
      schema_contract: @precedence_summary_schema_contract,
      source_artifact_type: @schema_contract,
      model_limits: model_limits()
    )
  end

  def precedence_summary(%{schema_contract: @precedence_summary_schema_contract} = summary) do
    stringify_keys(summary)
  end

  def precedence_summary(%{schema_contract: @schema_contract} = report) do
    report
    |> stringify_keys()
    |> precedence_summary()
  end

  def precedence_summary(_station_calendar_report),
    do: raise(ArgumentError, "station calendar report is required")

  def precedence_summary(contacts, station_calendar, opts) when is_list(contacts) do
    contacts
    |> report(station_calendar, opts)
    |> precedence_summary()
  end

  def precedence_summary(_contacts, _station_calendar, _opts),
    do: raise(ArgumentError, "contacts must be a list")

  @doc """
  Builds a compact artifact-only station reservation review summary.

  The summary can be derived from an existing `station_reservation_report.v1`,
  an existing `station_calendar_report.v1`, or from contacts plus declared
  station-calendar entries. It only re-exposes reservation overlap and
  provider-contention evidence already present in the source artifact; it does
  not reserve provider time or mutate schedules.
  """
  def reservation_report(station_calendar_report, opts \\ [])

  def reservation_report(%{"schema_contract" => @reservation_schema_contract} = report, _opts),
    do: report

  def reservation_report(%{schema_contract: @reservation_schema_contract} = report, opts) do
    report
    |> stringify_keys()
    |> reservation_report(opts)
  end

  def reservation_report(%{"schema_contract" => "station_calendar_report.v1"} = report, opts) do
    source =
      opts |> Keyword.get(:source, "station_calendar_report.reservation_evidence") |> to_string()

    reservation_summary(report, source)
  end

  def reservation_report(%{schema_contract: "station_calendar_report.v1"} = report, opts) do
    report
    |> stringify_keys()
    |> reservation_report(opts)
  end

  def reservation_report(_station_calendar_report, _opts),
    do: raise(ArgumentError, "station calendar report is required")

  def reservation_report(contacts, station_calendar, opts) when is_list(contacts) do
    contacts
    |> report(station_calendar, opts)
    |> reservation_report(opts)
  end

  def reservation_report(_contacts, _station_calendar, _opts),
    do: raise(ArgumentError, "contacts must be a list")

  @doc """
  Builds a compact artifact-only reservation review summary.

  The summary can be derived from an existing `station_reservation_report.v1`,
  a `station_calendar_report.v1`, or the contacts plus declared station-calendar
  entries accepted by `reservation_report/3`. When `:now_s` is supplied,
  reservation hold expiration seconds are classified as active or expired;
  otherwise expiration state is preserved as declared/missing evidence. This
  does not reserve provider time, call provider APIs, or mutate schedules.
  """
  def reservation_review_summary(source, opts \\ [])

  def reservation_review_summary(
        %{"schema_contract" => @reservation_review_summary_schema_contract} = summary,
        _opts
      ),
      do: summary

  def reservation_review_summary(
        %{"schema_contract" => @reservation_schema_contract} = report,
        opts
      ) do
    report
    |> stringify_keys()
    |> reservation_review_summary_from_report(opts)
  end

  def reservation_review_summary(
        %{schema_contract: @reservation_review_summary_schema_contract} = summary,
        opts
      ) do
    summary
    |> stringify_keys()
    |> reservation_review_summary(opts)
  end

  def reservation_review_summary(
        %{schema_contract: @reservation_schema_contract} = report,
        opts
      ) do
    report
    |> stringify_keys()
    |> reservation_review_summary(opts)
  end

  def reservation_review_summary(source, opts) do
    source
    |> reservation_report(opts)
    |> reservation_review_summary_from_report(opts)
  end

  def reservation_review_summary(contacts, station_calendar, opts) when is_list(contacts) do
    contacts
    |> reservation_report(station_calendar, opts)
    |> reservation_review_summary_from_report(opts)
  end

  def reservation_review_summary(_contacts, _station_calendar, _opts),
    do: raise(ArgumentError, "contacts must be a list")

  @doc """
  Builds a compact artifact-only reservation-hold summary.

  The summary is derived from `station_reservation_report.v1` review rows and
  keeps hold IDs, owners, statuses, and expiration routing explicit without
  reserving provider time, calling provider APIs, or mutating schedules.
  """
  def reservation_hold_summary(source, opts \\ [])

  def reservation_hold_summary(
        %{"schema_contract" => @reservation_hold_summary_schema_contract} = summary,
        _opts
      ),
      do: summary

  def reservation_hold_summary(
        %{schema_contract: @reservation_hold_summary_schema_contract} = summary,
        opts
      ) do
    summary
    |> stringify_keys()
    |> reservation_hold_summary(opts)
  end

  def reservation_hold_summary(source, opts) do
    source
    |> reservation_review_summary(opts)
    |> reservation_hold_summary_from_review_summary(opts)
  end

  def reservation_hold_summary(contacts, station_calendar, opts) when is_list(contacts) do
    contacts
    |> reservation_review_summary(station_calendar, opts)
    |> reservation_hold_summary_from_review_summary(opts)
  end

  def reservation_hold_summary(_contacts, _station_calendar, _opts),
    do: raise(ArgumentError, "contacts must be a list")

  @doc """
  Builds a compact artifact-only reservation-hold import-readiness summary.

  Reservation holds are review-only handoffs. This summary derives hold routing
  from station-reservation evidence without claiming provider reservation
  authority, writing Cadence, accepting holds, or mutating schedules.
  """
  def reservation_hold_import_readiness_summary(source, opts \\ [])

  def reservation_hold_import_readiness_summary(
        %{"schema_contract" => @reservation_hold_import_readiness_summary_schema_contract} =
          summary,
        _opts
      ),
      do: summary

  def reservation_hold_import_readiness_summary(
        %{schema_contract: @reservation_hold_import_readiness_summary_schema_contract} = summary,
        opts
      ) do
    summary
    |> stringify_keys()
    |> reservation_hold_import_readiness_summary(opts)
  end

  def reservation_hold_import_readiness_summary(source, opts) do
    source
    |> reservation_hold_summary(opts)
    |> reservation_hold_import_readiness_summary_from_hold_summary()
  end

  def reservation_hold_import_readiness_summary(contacts, station_calendar, opts)
      when is_list(contacts) do
    contacts
    |> reservation_hold_summary(station_calendar, opts)
    |> reservation_hold_import_readiness_summary_from_hold_summary()
  end

  def reservation_hold_import_readiness_summary(_contacts, _station_calendar, _opts),
    do: raise(ArgumentError, "contacts must be a list")

  @doc """
  Builds a standalone `provider_counteroffer_report.v1`.

  The report can be derived from a `station_calendar_report.v1`, a
  `station_calendar_provider.v1`, or raw station-calendar entries. It preserves
  declared counteroffer evidence for operator review without accepting offers,
  reserving station time, or mutating schedules.
  """
  def provider_counteroffer_report(source, opts \\ [])

  def provider_counteroffer_report(
        %{"schema_contract" => @counteroffer_schema_contract} = report,
        _opts
      ),
      do: report

  def provider_counteroffer_report(
        %{schema_contract: @counteroffer_schema_contract} = report,
        opts
      ) do
    report
    |> stringify_keys()
    |> provider_counteroffer_report(opts)
  end

  def provider_counteroffer_report(
        %{"schema_contract" => "station_calendar_report.v1"} = report,
        opts
      ) do
    source_label =
      opts |> Keyword.get(:source, "station_calendar_report.affected_contacts") |> to_string()

    source_artifact_id =
      Map.get(report, "id") || Map.get(report, "source") || "station_calendar_report"

    report
    |> Map.get("affected_contacts", [])
    |> build_provider_counteroffer_report(
      source_label,
      source_artifact_id,
      "station_calendar_report.v1"
    )
  end

  def provider_counteroffer_report(
        %{schema_contract: "station_calendar_report.v1"} = report,
        opts
      ) do
    report
    |> stringify_keys()
    |> provider_counteroffer_report(opts)
  end

  def provider_counteroffer_report(station_calendar, opts) do
    source_label =
      opts |> Keyword.get(:source, "station_calendar_provider.entries") |> to_string()

    source_artifact_id = Keyword.get(opts, :source_artifact_id, source_label) |> to_string()

    station_calendar
    |> normalize_calendar()
    |> build_provider_counteroffer_report(
      source_label,
      source_artifact_id,
      "station_calendar_provider.v1"
    )
  end

  @doc """
  Builds a compact artifact-only review summary for provider counteroffers.

  The summary can be derived from an existing `provider_counteroffer_report.v1`
  or from the same provider/calendar inputs accepted by
  `provider_counteroffer_report/2`. When `:now_s` is supplied, lock deadlines
  are classified as active or expired; otherwise deadline state is preserved as
  declared/missing evidence. This does not accept offers, reserve station time,
  call provider APIs, or mutate schedules.
  """
  def provider_counteroffer_review_summary(source, opts \\ [])

  def provider_counteroffer_review_summary(
        %{"schema_contract" => @counteroffer_review_summary_schema_contract} = summary,
        _opts
      ),
      do: summary

  def provider_counteroffer_review_summary(
        %{schema_contract: @counteroffer_review_summary_schema_contract} = summary,
        opts
      ) do
    summary
    |> stringify_keys()
    |> provider_counteroffer_review_summary(opts)
  end

  def provider_counteroffer_review_summary(source, opts) do
    source
    |> provider_counteroffer_report(opts)
    |> provider_counteroffer_review_summary_from_report(opts)
  end

  @doc """
  Builds a compact artifact-only import-readiness summary for counteroffers.

  Provider counteroffers are review-only handoffs: this summary exposes which
  counteroffers require adapter review before any import preparation and keeps
  provider writes, Cadence writes, offer acceptance, and schedule mutation out
  of scope.
  """
  def provider_counteroffer_import_readiness_summary(source, opts \\ [])

  def provider_counteroffer_import_readiness_summary(
        %{"schema_contract" => @counteroffer_import_readiness_summary_schema_contract} = summary,
        _opts
      ),
      do: summary

  def provider_counteroffer_import_readiness_summary(
        %{schema_contract: @counteroffer_import_readiness_summary_schema_contract} = summary,
        opts
      ) do
    summary
    |> stringify_keys()
    |> provider_counteroffer_import_readiness_summary(opts)
  end

  def provider_counteroffer_import_readiness_summary(source, opts) do
    source
    |> provider_counteroffer_report(opts)
    |> provider_counteroffer_import_readiness_summary_from_report(opts)
  end

  @doc """
  Builds a compact artifact-only summary of provider-counteroffer plan impact.

  The summary derives timing and cost deltas from provider counteroffer evidence
  without accepting offers, writing provider state, or mutating schedules.
  """
  def provider_counteroffer_plan_impact_summary(source, opts \\ [])

  def provider_counteroffer_plan_impact_summary(
        %{"schema_contract" => @counteroffer_plan_impact_summary_schema_contract} = summary,
        _opts
      ),
      do: summary

  def provider_counteroffer_plan_impact_summary(
        %{schema_contract: @counteroffer_plan_impact_summary_schema_contract} = summary,
        opts
      ) do
    summary
    |> stringify_keys()
    |> provider_counteroffer_plan_impact_summary(opts)
  end

  def provider_counteroffer_plan_impact_summary(source, opts) do
    source
    |> provider_counteroffer_report(opts)
    |> provider_counteroffer_plan_impact_summary_from_report(opts)
  end

  defp reservation_summary(report, source) do
    affected_reservations =
      report
      |> Map.get("affected_contacts", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&normalize_reservation_affected_contact/1)
      |> Enum.filter(&reservation_affected_contact?/1)
      |> Enum.map(&reservation_affected_contact_summary/1)

    provider_contention_groups =
      report
      |> Map.get("provider_calendar_contention_groups", [])
      |> Enum.filter(&reservation_provider_contention_group?/1)
      |> Enum.map(&reservation_provider_contention_summary/1)

    %{
      "model" => "artifact_only_station_reservation_summary",
      "schema_contract" => @reservation_schema_contract,
      "schema_version" => 1,
      "source" => source,
      "affected_contact_reservation_count" => length(affected_reservations),
      "provider_calendar_contention_group_count" => length(provider_contention_groups),
      "reservation_review_count" =>
        length(affected_reservations) + length(provider_contention_groups),
      "reservation_review_status" =>
        if(affected_reservations == [] and provider_contention_groups == [],
          do: "clear",
          else: "review_required"
        ),
      "station_reservation_match_status_counts" =>
        count_by(affected_reservations, "station_reservation_match_status"),
      "reservation_status_counts" =>
        reservation_status_counts(affected_reservations, provider_contention_groups),
      "reservation_ids" => reservation_ids(affected_reservations, provider_contention_groups),
      "reservation_ids_by_status" =>
        reservation_ids_by_status(affected_reservations, provider_contention_groups),
      "reservation_ids_by_match_status" => reservation_ids_by_match_status(affected_reservations),
      "affected_contacts" => affected_reservations,
      "provider_calendar_contention_groups" => provider_contention_groups,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "scope" => "station_reservation_overlap_and_provider_contention_review",
        "source" => source
      }
    }
  end

  defp reservation_review_summary_from_report(report, opts) do
    ReservationReviewSummary.build(report, opts, model_limits())
  end

  defp reservation_hold_summary_from_review_summary(summary, _opts) do
    summary = stringify_keys(summary)

    hold_rows =
      summary
      |> Map.get("review_rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.filter(&reservation_hold_review_row?/1)

    %{
      "schema_contract" => @reservation_hold_summary_schema_contract,
      "model" => "artifact_only_station_reservation_hold_summary",
      "source_artifact_type" =>
        Map.get(summary, "source_artifact_type", @reservation_schema_contract),
      "source" => summary["source"],
      "model_limits" => model_limits(),
      "reservation_hold_count" => length(hold_rows),
      "affected_contact_reservation_hold_count" =>
        Enum.count(hold_rows, &(&1["reservation_review_row_type"] == "affected_contact")),
      "provider_calendar_contention_hold_count" =>
        Enum.count(
          hold_rows,
          &(&1["reservation_review_row_type"] == "provider_calendar_contention_group")
        ),
      "reservation_hold_review_status" =>
        if(hold_rows == [], do: "clear", else: "review_required"),
      "reservation_hold_expiration_count" => reservation_expiration_count(hold_rows),
      "earliest_reservation_hold_expires_at_s" => earliest_reservation_expires_at_s(hold_rows),
      "reservation_hold_expiration_status_counts" =>
        count_by(hold_rows, "station_reservation_expiration_status"),
      "reservation_hold_status_counts" => reservation_status_counts_for_rows(hold_rows),
      "reservation_hold_ids" => reservation_row_ids(hold_rows),
      "reservation_hold_ids_by_expiration_status" =>
        reservation_ids_by(hold_rows, "station_reservation_expiration_status"),
      "reservation_hold_ids_by_status" =>
        reservation_ids_by_row_values(hold_rows, "reservation_statuses"),
      "reservation_hold_ids_by_reserved_by" =>
        reservation_ids_by_row_values(hold_rows, "reserved_by"),
      "reservation_hold_ids_by_row_type" =>
        reservation_ids_by(hold_rows, "reservation_review_row_type"),
      "reservation_hold_contact_ids_by_expiration_status" =>
        reservation_contact_ids_by(hold_rows, "station_reservation_expiration_status"),
      "review_contact_ids" => reservation_contact_ids(hold_rows),
      "review_rows" => hold_rows,
      "assumptions" =>
        %{
          "execution_boundary" => "artifact_only_no_provider_reservation",
          "source" => "station_reservation_report.v1",
          "operator_authority" => "not_granted_by_summary",
          "deadline_evaluation" =>
            get_in(summary, ["assumptions", "deadline_evaluation"]) || "not_evaluated"
        }
        |> maybe_put("now_s", get_in(summary, ["assumptions", "now_s"]))
    }
    |> compact_map()
  end

  defp reservation_hold_import_readiness_summary_from_hold_summary(summary) do
    ReservationHoldImportReadinessSummary.build(summary, model_limits())
  end

  defp reservation_affected_contact?(row),
    do: ReservationSourceEvidence.affected_contact?(row)

  defp reservation_provider_contention_group?(row),
    do: ReservationSourceEvidence.provider_contention_group?(row)

  defp normalize_reservation_affected_contact(row),
    do: ReservationSourceEvidence.normalize_affected_contact(row)

  defp reservation_affected_contact_summary(row) do
    Map.take(row, [
      "id",
      "contact_id",
      "ground_station_id",
      "starts_at_s",
      "ends_at_s",
      "overlap_starts_at_s",
      "overlap_ends_at_s",
      "overlap_duration_s",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id",
      "station_calendar_entry_ambiguous",
      "station_calendar_ambiguous_entry_count",
      "station_calendar_ambiguous_entry_ids",
      "station_contention_status",
      "station_reservation_match_status",
      "station_reservation_id",
      "station_reserved_by",
      "station_reservation_status",
      "station_reservation_expires_at_s",
      "station_calendar_reservation_overlap_count",
      "station_calendar_reservation_ids",
      "station_calendar_reserved_by",
      "station_calendar_reservation_statuses",
      "station_calendar_reservation_expires_at_s",
      "required_operator_action",
      "operator_action_reason",
      "approval_status",
      "approval_requirements",
      "approval_rule_matches",
      "policy_decision"
    ])
  end

  defp reservation_provider_contention_summary(row) do
    Map.take(row, [
      "id",
      "provider_calendar_contention_status",
      "required_operator_action",
      "approval_status",
      "operator_action_reason",
      "ground_station_id",
      "starts_at_s",
      "ends_at_s",
      "overlap_duration_s",
      "entry_count",
      "entry_ids",
      "provider_ids",
      "provider_entry_ids",
      "availabilities",
      "directions",
      "reservation_ids",
      "reserved_by",
      "reservation_statuses",
      "reservation_expires_at_s",
      "approval_requirements",
      "approval_rule_matches",
      "policy_decision"
    ])
  end

  defp reservation_status_counts(affected_reservations, provider_contention_groups),
    do: ReservationSummaryValues.status_counts(affected_reservations, provider_contention_groups)

  defp reservation_ids(affected_reservations, provider_contention_groups),
    do: ReservationSummaryValues.ids(affected_reservations, provider_contention_groups)

  defp reservation_ids_by_status(affected_reservations, provider_contention_groups),
    do: ReservationSummaryValues.ids_by_status(affected_reservations, provider_contention_groups)

  defp reservation_ids_by_match_status(affected_reservations),
    do: ReservationSummaryValues.ids_by_match_status(affected_reservations)

  defp reservation_hold_review_row?(row), do: ReservationSummaryValues.hold_review_row?(row)

  defp reservation_expiration_count(rows), do: ReservationSummaryValues.expiration_count(rows)

  defp earliest_reservation_expires_at_s(rows),
    do: ReservationSummaryValues.earliest_expiration(rows)

  defp reservation_row_ids(rows), do: ReservationSummaryValues.row_ids(rows)

  defp reservation_ids_by(rows, field), do: ReservationSummaryValues.ids_by(rows, field)

  defp reservation_ids_by_row_values(rows, field),
    do: ReservationSummaryValues.ids_by_row_values(rows, field)

  defp reservation_status_counts_for_rows(rows) do
    rows
    |> Enum.flat_map(&Map.get(&1, "reservation_statuses", []))
    |> Enum.frequencies()
  end

  defp reservation_contact_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "contact_id"))
    |> sorted_id_map()
  end

  defp reservation_contact_ids(rows) do
    rows
    |> Enum.map(& &1["contact_id"])
    |> sorted_values()
  end

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  @doc """
  Converts declared provider calendar artifacts into ground-network intervals.
  """
  def to_ground_network(provider), do: CalendarInput.to_ground_network(provider)

  defp normalize_calendar(station_calendar), do: CalendarInput.normalize(station_calendar)

  defp normalize_contact(contact), do: StationMatching.normalize_contact(contact)
  defp station_calendar_matches(contact, entries), do: StationMatching.matches(contact, entries)

  defp applied_station_calendar_entry(matches), do: StationMatching.applied_entry(matches)
  defp contact_row?(contact), do: StationMatching.contact_row?(contact)
  defp contact_direction(contact), do: StationMatching.contact_direction(contact)
  defp station_calendar_priority(entry), do: StationMatching.priority(entry)

  defp annotate_station_calendar(contact, entry, matches) do
    contact
    |> Map.put("station_availability", entry["availability"])
    |> Map.put("station_calendar_entry_id", entry["id"])
    |> Map.put("station_calendar_precedence_rank", station_calendar_priority(entry))
    |> Map.put("station_calendar_precedence_availability", entry["availability"])
    |> maybe_put("station_calendar_provider_id", station_calendar_provider_id(entry))
    |> maybe_put("station_calendar_provider_entry_id", station_calendar_provider_entry_id(entry))
    |> Map.put("station_calendar_status", entry["status"])
    |> maybe_put("station_calendar_directions", entry["directions"])
    |> put_station_calendar_overlap(matches)
    |> put_station_calendar_ambiguity(entry)
    |> put_provider_counteroffer(entry)
    |> put_station_calendar_trust(entry, matches)
    |> put_station_reservation(entry, matches)
    |> put_station_capacity(entry["capacity_fraction"])
  end

  defp put_station_calendar_trust(contact, entry, matches) do
    contact
    |> Map.put(
      "station_calendar_trust_boundary_status",
      station_calendar_trust_boundary_status(entry)
    )
    |> maybe_put(
      "trust_boundary",
      Map.get(entry, "trust_boundary") || get_in(entry, ["provenance", "trust_boundary"])
    )
    |> maybe_put("provenance", entry["provenance"])
    |> Map.put("source_station_calendar_entry", entry)
    |> Map.put("source_station_calendar_overlaps", matches)
  end

  defp station_calendar_provider_id(entry) do
    entry["provider_id"] || get_in(entry, ["provenance", "provider_id"])
  end

  defp station_calendar_provider_entry_id(entry) do
    entry["provider_entry_id"] || entry["id"]
  end

  defp put_station_calendar_ambiguity(
         contact,
         %{"station_calendar_entry_ambiguous" => true} = entry
       ) do
    contact
    |> Map.put("station_calendar_entry_ambiguous", true)
    |> Map.put(
      "station_calendar_ambiguous_entry_count",
      entry["station_calendar_ambiguous_entry_count"]
    )
    |> Map.put(
      "station_calendar_ambiguous_entry_ids",
      entry["station_calendar_ambiguous_entry_ids"]
    )
  end

  defp put_station_calendar_ambiguity(contact, _entry), do: contact

  defp put_provider_counteroffer(contact, entry) do
    contact =
      contact
      |> maybe_put("provider_counteroffer_id", entry["provider_counteroffer_id"])
      |> maybe_put("provider_counteroffer_status", entry["provider_counteroffer_status"])
      |> maybe_put(
        "provider_counteroffer_negotiation_state",
        entry["provider_counteroffer_negotiation_state"]
      )
      |> maybe_put(
        "provider_counteroffer_reason_code",
        entry["provider_counteroffer_reason_code"]
      )
      |> maybe_put("provider_counteroffer_cost_delta", entry["provider_counteroffer_cost_delta"])
      |> maybe_put(
        "provider_counteroffer_lock_deadline_s",
        entry["provider_counteroffer_lock_deadline_s"]
      )
      |> maybe_put(
        "provider_counteroffer_starts_at_s",
        entry["provider_counteroffer_starts_at_s"]
      )
      |> maybe_put("provider_counteroffer_ends_at_s", entry["provider_counteroffer_ends_at_s"])

    contact
    |> maybe_put(
      "provider_counteroffer_start_delta_s",
      numeric_delta(contact["provider_counteroffer_starts_at_s"], contact["starts_at_s"])
    )
    |> maybe_put(
      "provider_counteroffer_end_delta_s",
      numeric_delta(contact["provider_counteroffer_ends_at_s"], contact["ends_at_s"])
    )
    |> maybe_put(
      "provider_counteroffer_duration_delta_s",
      provider_counteroffer_duration_delta(contact)
    )
  end

  defp put_station_calendar_overlap(contact, matches) do
    contact
    |> Map.put("station_calendar_overlap_count", length(matches))
    |> Map.put("station_calendar_overlap_entry_ids", Enum.map(matches, & &1["id"]))
    |> Map.put(
      "station_calendar_overlap_availabilities",
      matches |> Enum.map(& &1["availability"]) |> Enum.uniq()
    )
  end

  defp put_station_reservation(contact, %{"availability" => "reserved"} = entry, matches) do
    if entry["station_calendar_entry_ambiguous"] do
      contact
      |> Map.put("station_contention_status", "reserved_overlap")
      |> Map.put(
        "station_reservation_match_status",
        contact["station_reservation_match_status"] || "ambiguous"
      )
      |> put_station_reservation_overlap_lists(matches)
    else
      contact
      |> Map.put("station_contention_status", "reserved_overlap")
      |> Map.put(
        "station_reservation_match_status",
        contact["station_reservation_match_status"] || reservation_match_status(contact, [entry])
      )
      |> Map.put("station_reservation_id", entry["reservation_id"] || entry["id"])
      |> maybe_put("station_reservation_expires_at_s", entry["reservation_expires_at_s"])
      |> maybe_put("station_reserved_by", entry["reserved_by"])
      |> maybe_put("station_reservation_status", entry["reservation_status"] || "reserved")
      |> put_station_reservation_overlap(matches)
    end
  end

  defp put_station_reservation(contact, _entry, matches),
    do: put_station_reservation_overlap(contact, matches)

  defp put_station_reservation_overlap(contact, matches) do
    reservations = Enum.filter(matches, &(&1["availability"] == "reserved"))

    case reservations do
      [] ->
        contact

      [first | _rest] ->
        contact
        |> Map.put("station_contention_status", "reserved_overlap")
        |> Map.put_new(
          "station_reservation_match_status",
          reservation_match_status(contact, reservations)
        )
        |> Map.put(
          "station_reservation_id",
          contact["station_reservation_id"] || reservation_id(first)
        )
        |> maybe_put(
          "station_reservation_expires_at_s",
          contact["station_reservation_expires_at_s"] || first["reservation_expires_at_s"]
        )
        |> maybe_put(
          "station_reserved_by",
          contact["station_reserved_by"] || first["reserved_by"]
        )
        |> maybe_put(
          "station_reservation_status",
          contact["station_reservation_status"] || first["reservation_status"] || "reserved"
        )
        |> put_station_reservation_overlap_lists(matches)
    end
  end

  defp put_station_reservation_overlap_lists(contact, matches) do
    reservations = Enum.filter(matches, &(&1["availability"] == "reserved"))

    case reservations do
      [] ->
        contact

      reservations ->
        contact
        |> Map.put("station_calendar_reservation_overlap_count", length(reservations))
        |> Map.put("station_calendar_reservation_ids", Enum.map(reservations, &reservation_id/1))
        |> maybe_put_list(
          "station_calendar_reserved_by",
          Enum.map(reservations, & &1["reserved_by"])
        )
        |> maybe_put_list(
          "station_calendar_reservation_statuses",
          Enum.map(reservations, &(&1["reservation_status"] || "reserved"))
        )
        |> maybe_put_list(
          "station_calendar_reservation_expires_at_s",
          Enum.map(reservations, & &1["reservation_expires_at_s"])
        )
    end
  end

  defp reservation_id(entry), do: entry["reservation_id"] || entry["id"]

  defp reservation_match_status(contact, reservations) do
    contact_reservation_id = contact_reservation_id(contact)
    reservation_ids = Enum.map(reservations, &reservation_id/1)
    contact_reserved_by = contact_reserved_by(contact)

    reservation_owner_match_count =
      reservation_owner_match_count(contact_reserved_by, reservations)

    cond do
      contact["station_contention_status"] == "reserved_overlap" -> "overlap"
      contact_reservation_id in reservation_ids and length(reservation_ids) == 1 -> "matched"
      contact_reservation_id in reservation_ids -> "matched_ambiguous"
      reservation_owner_match_count == 1 -> "owner_matched"
      reservation_owner_match_count > 1 -> "owner_matched_ambiguous"
      true -> "overlap"
    end
  end

  defp contact_reservation_id(contact) do
    contact["station_reservation_id"] || contact["reservation_id"]
  end

  defp contact_reserved_by(contact) do
    contact["station_reserved_by"] || contact["reserved_by"]
  end

  defp reservation_owner_match_count(nil, _reservations), do: 0
  defp reservation_owner_match_count("", _reservations), do: 0

  defp reservation_owner_match_count(owner, reservations) do
    owner = to_string(owner)

    Enum.count(reservations, fn reservation ->
      reservation["reserved_by"] && to_string(reservation["reserved_by"]) == owner
    end)
  end

  defp put_station_capacity(contact, capacity_fraction) when not is_number(capacity_fraction),
    do: contact

  defp put_station_capacity(contact, 1.0), do: contact

  defp put_station_capacity(contact, capacity_fraction) do
    contact
    |> Map.put("station_capacity_fraction", capacity_fraction)
    |> Map.update(
      "throughput_model",
      %{"station_capacity_fraction" => capacity_fraction},
      fn model ->
        Map.put(model, "station_capacity_fraction", capacity_fraction)
      end
    )
  end

  defp affected_contact(contact, entry, matches) do
    contact_id = required_contact_id!(contact)
    overlap = overlap_window(contact, entry)
    feedback_factor_issue = contact_feedback_factor_issue(contact)

    row_id =
      ["station_calendar", contact_id, entry["id"]]
      |> Enum.map(&encode_value/1)
      |> Enum.join(":")

    %{
      "id" => row_id,
      "contact_id" => contact_id,
      "scenario_id" => Map.get(contact, "scenario_id"),
      "ground_station_id" => contact["ground_station_id"],
      "starts_at_s" => contact["starts_at_s"] || contact["start_s"],
      "ends_at_s" => contact["ends_at_s"] || contact["end_s"],
      "station_calendar_entry_id" => entry["id"],
      "station_calendar_provider_id" => station_calendar_provider_id(entry),
      "station_calendar_provider_entry_id" => station_calendar_provider_entry_id(entry),
      "station_calendar_directions" => entry["directions"],
      "contact_type" => contact["type"] || contact["activity_type"] || "planned_contact",
      "direction" => contact_direction(contact),
      "contact_success" => contact["contact_success"],
      "contact_result" => ProviderResult.artifact_value(contact["contact_result"]),
      "contact_success_factor" => unit_interval_factor(contact, "contact_success_factor"),
      "contact_success_factor_source" =>
        unit_interval_factor_source(
          contact,
          "contact_success_factor",
          "contact_success_factor_source"
        ),
      "command_success" => contact["command_success"],
      "command_result" => ProviderResult.artifact_value(contact["command_result"]),
      "command_success_factor" => unit_interval_factor(contact, "command_success_factor"),
      "command_success_factor_source" =>
        unit_interval_factor_source(
          contact,
          "command_success_factor",
          "command_success_factor_source"
        ),
      "invalid_feedback_confidence" => if(feedback_factor_issue, do: true),
      "invalid_feedback_confidence_reason" => feedback_factor_issue,
      "source_contact_candidate" => if(feedback_factor_issue, do: contact),
      "status" => entry["status"],
      "station_calendar_status" => entry["status"],
      "station_availability" => entry["availability"],
      "station_calendar_precedence_rank" => station_calendar_priority(entry),
      "station_calendar_precedence_availability" => entry["availability"],
      "overlap_starts_at_s" => overlap["starts_at_s"],
      "overlap_ends_at_s" => overlap["ends_at_s"],
      "overlap_duration_s" => overlap["duration_s"],
      "capacity_fraction" => entry["capacity_fraction"],
      "station_calendar_overlap_count" => length(matches),
      "station_calendar_overlap_entry_ids" => Enum.map(matches, & &1["id"]),
      "station_calendar_overlap_availabilities" =>
        matches |> Enum.map(& &1["availability"]) |> Enum.uniq(),
      "station_calendar_entry_ambiguous" => contact["station_calendar_entry_ambiguous"],
      "station_calendar_ambiguous_entry_count" =>
        contact["station_calendar_ambiguous_entry_count"],
      "station_calendar_ambiguous_entry_ids" => contact["station_calendar_ambiguous_entry_ids"],
      "station_calendar_reservation_overlap_count" =>
        contact["station_calendar_reservation_overlap_count"],
      "station_calendar_reservation_ids" => contact["station_calendar_reservation_ids"],
      "station_calendar_reserved_by" => contact["station_calendar_reserved_by"],
      "station_calendar_reservation_statuses" => contact["station_calendar_reservation_statuses"],
      "station_calendar_reservation_expires_at_s" =>
        contact["station_calendar_reservation_expires_at_s"],
      "station_calendar_trust_boundary_status" => station_calendar_trust_boundary_status(entry),
      "provider_counteroffer_id" => contact["provider_counteroffer_id"],
      "provider_counteroffer_status" => contact["provider_counteroffer_status"],
      "provider_counteroffer_negotiation_state" =>
        contact["provider_counteroffer_negotiation_state"],
      "provider_counteroffer_reason_code" => contact["provider_counteroffer_reason_code"],
      "provider_counteroffer_cost_delta" => contact["provider_counteroffer_cost_delta"],
      "provider_counteroffer_lock_deadline_s" => contact["provider_counteroffer_lock_deadline_s"],
      "provider_counteroffer_starts_at_s" => contact["provider_counteroffer_starts_at_s"],
      "provider_counteroffer_ends_at_s" => contact["provider_counteroffer_ends_at_s"],
      "provider_counteroffer_start_delta_s" =>
        numeric_delta(contact["provider_counteroffer_starts_at_s"], contact["starts_at_s"]),
      "provider_counteroffer_end_delta_s" =>
        numeric_delta(contact["provider_counteroffer_ends_at_s"], contact["ends_at_s"]),
      "provider_counteroffer_duration_delta_s" => provider_counteroffer_duration_delta(contact),
      "station_contention_status" => contact["station_contention_status"],
      "station_reservation_match_status" => contact["station_reservation_match_status"],
      "station_reservation_id" => contact["station_reservation_id"],
      "station_reservation_expires_at_s" => contact["station_reservation_expires_at_s"],
      "station_reserved_by" => contact["station_reserved_by"],
      "station_reservation_status" => contact["station_reservation_status"],
      "trust_boundary" =>
        Map.get(entry, "trust_boundary") || get_in(entry, ["provenance", "trust_boundary"]),
      "provenance" => entry["provenance"],
      "source_station_calendar_entry" => entry,
      "source_station_calendar_overlaps" => matches,
      "required_operator_action" => station_calendar_action(contact),
      "operator_action_reason" => station_calendar_reason(contact)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp disambiguate_affected_contact_ids(affected) do
    duplicates = duplicate_affected_contact_id_groups(affected)
    duplicate_ids = duplicates |> Enum.map(fn {id, _rows} -> id end) |> MapSet.new()
    duplicate_counts = Map.new(duplicates, fn {id, rows} -> {id, length(rows)} end)

    {rows, _indexes} =
      Enum.map_reduce(affected, %{}, fn row, indexes ->
        row_id = row["id"]
        index = Map.get(indexes, row_id, 0) + 1
        indexes = Map.put(indexes, row_id, index)

        row =
          if MapSet.member?(duplicate_ids, row_id) do
            row
            |> Map.put("id", "#{row_id}:#{index}")
            |> Map.put("base_station_calendar_row_id", row_id)
            |> Map.put("duplicate_station_calendar_row_id_collision", true)
            |> Map.put("duplicate_station_calendar_row_index", index)
            |> Map.put(
              "duplicate_station_calendar_row_count",
              Map.fetch!(duplicate_counts, row_id)
            )
          else
            row
          end

        {row, indexes}
      end)

    rows
  end

  defp duplicate_affected_contact_id_groups(affected) do
    affected
    |> Enum.group_by(&Map.get(&1, "base_station_calendar_row_id", Map.get(&1, "id")))
    |> Enum.filter(fn {_row_id, rows} -> length(rows) > 1 end)
    |> Enum.sort_by(fn {row_id, _rows} -> row_id end)
  end

  defp duplicate_affected_contact_row_count(duplicate_groups) do
    duplicate_groups
    |> Enum.map(fn {_row_id, rows} -> length(rows) end)
    |> Enum.sum()
  end

  defp maybe_apply_approval_policy(row, approval_policy),
    do: ApprovalPolicy.apply_to_row(row, approval_policy)

  defp maybe_apply_provider_contention_approval_policy(group, approval_policy),
    do: ApprovalPolicy.apply_to_provider_contention(group, approval_policy)

  defp station_calendar_action(%{"provider_counteroffer_id" => id}) when is_binary(id),
    do: "review_provider_counteroffer"

  defp station_calendar_action(%{"provider_counteroffer_status" => status})
       when is_binary(status),
       do: "review_provider_counteroffer"

  defp station_calendar_action(%{"station_contention_status" => "reserved_overlap"}),
    do: "review_station_reservation_overlap"

  defp station_calendar_action(%{"station_calendar_reservation_overlap_count" => count})
       when is_number(count) and count > 0,
       do: "review_station_reservation_overlap"

  defp station_calendar_action(%{"station_availability" => "reserved"}),
    do: "review_station_reservation_overlap"

  defp station_calendar_action(%{"station_availability" => "reduced_capacity"}),
    do: "review_reduced_station_capacity"

  defp station_calendar_action(_row), do: "review_station_availability"

  defp station_calendar_reason(%{
         "provider_counteroffer_id" => counteroffer_id,
         "ground_station_id" => station
       })
       when is_binary(counteroffer_id) and is_binary(station) do
    "station #{station} provider counteroffer #{counteroffer_id} requires operator review"
  end

  defp station_calendar_reason(%{"provider_counteroffer_id" => counteroffer_id})
       when is_binary(counteroffer_id),
       do: "provider counteroffer #{counteroffer_id} requires operator review"

  defp station_calendar_reason(%{
         "station_availability" => availability,
         "ground_station_id" => station
       })
       when is_binary(availability) and is_binary(station) do
    "station #{station} calendar reports #{availability}"
  end

  defp station_calendar_reason(%{"station_availability" => availability})
       when is_binary(availability),
       do: "station calendar reports #{availability}"

  defp station_calendar_reason(_row), do: "station calendar row requires operator review"

  defp affected_duration_s(affected) do
    affected
    |> Enum.map(&Map.get(&1, "overlap_duration_s"))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp provider_counteroffer_count(rows) do
    Enum.count(rows, fn row ->
      value_present?(row["provider_counteroffer_id"]) or
        value_present?(row["provider_counteroffer_status"])
    end)
  end

  defp build_provider_counteroffer_report(rows, source, source_artifact_id, source_artifact_type) do
    ProviderCounterofferReport.build(rows, source, source_artifact_id, source_artifact_type)
  end

  defp provider_counteroffer_review_summary_from_report(report, opts) do
    ProviderCounterofferReviewSummary.build(report, opts)
  end

  defp provider_counteroffer_import_readiness_summary_from_report(report, opts),
    do: ProviderCounterofferHandoffSummary.import_readiness_summary(report, opts)

  defp provider_counteroffer_plan_impact_summary_from_report(report, opts),
    do: ProviderCounterofferHandoffSummary.plan_impact_summary(report, opts)

  defp provider_counteroffer_duration_delta(row),
    do: ProviderCounterofferHandoffSummary.duration_delta(row)

  defp numeric_delta(left, right),
    do: ProviderCounterofferHandoffSummary.numeric_delta(left, right)

  defp station_calendar_trust_boundary_status_counts(affected) do
    affected
    |> Enum.map(&Map.get(&1, "station_calendar_trust_boundary_status", "missing"))
    |> Enum.frequencies()
  end

  defp affected_contact_ids_by_trust_boundary_status(affected) do
    affected
    |> Enum.group_by(
      &Map.get(&1, "station_calendar_trust_boundary_status", "missing"),
      &Map.get(&1, "contact_id")
    )
    |> sorted_id_map()
  end

  defp affected_contact_ids_by_field(affected, field) do
    affected
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "contact_id"))
    |> sorted_id_map()
  end

  defp sorted_id_map(groups) do
    groups
    |> Enum.reject(fn {key, ids} -> is_nil(key) or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, sorted_values(ids)} end)
  end

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp sorted_values(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp calendar_entry_trust_boundary_status_counts(entries) do
    entries
    |> Enum.map(&station_calendar_trust_boundary_status/1)
    |> Enum.frequencies()
  end

  defp station_calendar_trust_boundary_status(entry) do
    case Map.get(entry, "trust_boundary") || get_in(entry, ["provenance", "trust_boundary"]) do
      value when is_binary(value) and value != "" -> "declared"
      _value -> "missing"
    end
  end

  defp overlap_window(contact, entry) do
    contact_start = contact["starts_at_s"] || contact["start_s"]
    contact_end = contact["ends_at_s"] || contact["end_s"]
    entry_start = entry["starts_at_s"]
    entry_end = entry["ends_at_s"]

    starts_at_s = max_present(contact_start, entry_start)
    ends_at_s = min_present(contact_end, entry_end)

    if is_number(starts_at_s) and is_number(ends_at_s) and ends_at_s > starts_at_s do
      %{
        "starts_at_s" => starts_at_s,
        "ends_at_s" => ends_at_s,
        "duration_s" => ends_at_s - starts_at_s
      }
    else
      %{}
    end
  end

  defp max_present(nil, value), do: value
  defp max_present(value, nil), do: value
  defp max_present(left, right) when is_number(left) and is_number(right), do: max(left, right)
  defp max_present(_left, _right), do: nil

  defp min_present(nil, value), do: value
  defp min_present(value, nil), do: value
  defp min_present(left, right) when is_number(left) and is_number(right), do: min(left, right)
  defp min_present(_left, _right), do: nil

  defp value_present?(value), do: value not in [nil, ""]

  defp required_contact_id!(contact) do
    case Map.get(contact, "id") || Map.get(contact, "contact_id") ||
           Map.get(contact, "activity_id") do
      value when is_binary(value) and value != "" -> value
      value when is_atom(value) -> Atom.to_string(value)
      _value -> raise ArgumentError, "contact id is required"
    end
  end

  defp numeric_or_nil(value), do: Availability.numeric_or_nil(value)

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

  defp unit_interval_factor(row, field) do
    case Map.get(row, field) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 ->
        value

      value when is_binary(value) ->
        unit_interval_factor(%{field => numeric_or_nil(value)}, field)

      _value ->
        nil
    end
  end

  defp unit_interval_factor_source(row, factor_field, source_field) do
    if is_nil(feedback_factor_issue(row, factor_field)) do
      Map.get(row, source_field)
    end
  end

  defp contact_feedback_factor_issue(contact) do
    Enum.find_value(["contact_success_factor", "command_success_factor"], fn field ->
      feedback_factor_issue(contact, field)
    end)
  end

  defp feedback_factor_issue(row, field) do
    case Map.get(row, field) do
      nil ->
        nil

      value ->
        case numeric_or_nil(value) do
          number when is_number(number) ->
            if number >= 0.0 and number <= 1.0, do: nil, else: "invalid_#{field}"

          _value ->
            "invalid_#{field}"
        end
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_list(map, key, values) do
    values =
      values
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()

    case values do
      [] -> map
      values -> Map.put(map, key, values)
    end
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key

  defp encode_value(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 6)
  defp encode_value(value), do: to_string(value)
end
