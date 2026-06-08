defmodule OrbitalDynamics.Communications.CommandWindow do
  @moduledoc """
  Builds artifact-only command-window reports from planned activities.

  Command windows are review/import rows for command, tracking, health-check,
  and uplink contact activity boundaries. They do not schedule contacts,
  reserve providers, mutate plans, or execute commands.
  """

  alias OrbitalDynamics.Communications.StationCalendar
  alias OrbitalDynamics.Policy
  alias OrbitalDynamics.Timeline

  @schema_contract "command_window_report.v1"
  @window_directions ~w(command tracking uplink health_check)
  @window_activity_types ~w(command tracking health_check)
  @unavailable_aliases ["outage", "down", "offline"]
  @station_availability_severity %{
    "unavailable" => 5,
    "maintenance" => 5,
    "reserved" => 4,
    "reduced_capacity" => 3,
    "available" => 1
  }
  @station_capacity_local_fraction_paths [
    ["capacity_pack_capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_fraction"],
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"]
  ]
  @station_capacity_local_percent_paths [
    ["station_capacity_percent"],
    ["capacity_percent"],
    ["throughput_model", "station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["activity_context", "station_capacity_percent"],
    ["activity_context", "capacity_percent"]
  ]
  @station_capacity_fraction_paths [
    ["capacity_pack_capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_fraction"],
    ["source_activity", "capacity_pack_capacity_fraction"],
    ["source_activity", "station_capacity_fraction"],
    ["source_activity", "capacity_fraction"],
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"]
  ]
  @station_capacity_percent_paths [
    ["station_capacity_percent"],
    ["capacity_percent"],
    ["source_activity", "station_capacity_percent"],
    ["source_activity", "capacity_percent"],
    ["throughput_model", "station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["activity_context", "station_capacity_percent"],
    ["activity_context", "capacity_percent"]
  ]
  @source_station_capacity_roots [
    ["source_station_calendar_entry"],
    ["source_station_calendar_overlaps"],
    ["source_activity", "source_station_calendar_entry"],
    ["source_activity", "source_station_calendar_overlaps"],
    ["activity_context", "source_station_calendar_entry"],
    ["activity_context", "source_station_calendar_overlaps"]
  ]
  @source_station_capacity_fraction_paths for root <- @source_station_capacity_roots,
                                              path <- @station_capacity_local_fraction_paths,
                                              do: root ++ path
  @source_station_capacity_percent_paths for root <- @source_station_capacity_roots,
                                             path <- @station_capacity_local_percent_paths,
                                             do: root ++ path
  @station_capacity_value_paths for(
                                  path <- @station_capacity_fraction_paths,
                                  do: {:fraction, path}
                                ) ++
                                  for(
                                    path <- @station_capacity_percent_paths,
                                    do: {:percent, path}
                                  )
  @source_station_capacity_value_paths for(
                                         path <- @source_station_capacity_fraction_paths,
                                         do: {:fraction, path}
                                       ) ++
                                         for(
                                           path <- @source_station_capacity_percent_paths,
                                           do: {:percent, path}
                                         )
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
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  @station_reservation_expiration_fields [
    "station_reservation_expires_at_s",
    "reservation_expires_at_s",
    "reservation_hold_expires_at_s",
    "hold_expires_at_s",
    "expires_at_s",
    "expires_at"
  ]
  @station_calendar_reservation_expiration_fields [
    "station_calendar_reservation_expires_at_s"
    | @station_reservation_expiration_fields
  ]

  @doc """
  Declares the command-window report model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      model: :artifact_only_command_window_report,
      validation_level: :artifact_contract,
      source_activity_types: ["command", "tracking", "health_check", "planned_contact"],
      command_window_activity_types: @window_activity_types,
      source_directions: @window_directions,
      station_unavailable_aliases: @unavailable_aliases,
      station_availability_precedence: @station_availability_severity,
      station_capacity_fraction_paths: @station_capacity_fraction_paths,
      station_capacity_percent_paths: @station_capacity_percent_paths,
      station_capacity_value_paths: capacity_value_path_metadata(@station_capacity_value_paths),
      source_station_capacity_fraction_paths: @source_station_capacity_fraction_paths,
      source_station_capacity_percent_paths: @source_station_capacity_percent_paths,
      source_station_capacity_value_paths:
        capacity_value_path_metadata(@source_station_capacity_value_paths),
      station_reservation_expiration_fields: @station_reservation_expiration_fields,
      station_calendar_reservation_expiration_fields:
        @station_calendar_reservation_expiration_fields,
      provider_direction_aliases: @provider_direction_aliases,
      provider_result_map_value_keys: @provider_result_map_value_keys,
      row_semantics: [
        :window_type,
        :command_window_activity_types,
        :required_operator_action,
        :operator_action_reason,
        :cadence_import_status,
        :execution_boundary,
        :timeline_identity,
        :timeline_integrity_review,
        :invalid_activity_input_review,
        :declared_station_calendar_overlay,
        :station_reservation_context,
        :station_reservation_alias_normalization,
        :station_reservation_source_evidence_normalization,
        :station_calendar_reservation_overlap_handoff,
        :station_calendar_reservation_expiration_context,
        :station_reservation_expiration_aliases,
        :station_calendar_reservation_expiration_aliases,
        :station_calendar_provider_context,
        :station_calendar_provider_list_input,
        :station_calendar_review_precedence,
        :station_calendar_availability_status_normalization,
        :station_calendar_capacity_percent_aliases,
        :station_capacity_value_paths,
        :source_station_capacity_value_paths,
        :station_calendar_direction_context,
        :provider_direction_aliases,
        :provider_result_map_value_keys,
        :command_window_activity_id_routing,
        :command_window_review_action_id_routing
      ],
      known_limits: [
        :no_schedule_mutation,
        :no_provider_reservation,
        :no_command_execution,
        :no_link_budget_model
      ]
    }
  end

  defp capacity_value_path_metadata(paths) do
    Enum.map(paths, fn {unit, path} -> %{unit: unit, path: path} end)
  end

  @doc """
  Builds a `command_window_report.v1` from planned activities.
  """
  def report(command_window_report)

  def report(%{"schema_contract" => @schema_contract} = report) do
    report
  end

  def report(%{schema_contract: @schema_contract} = report) do
    stringify_keys(report)
  end

  def report(activities) when is_list(activities) do
    report(activities, [])
  end

  def report(_command_window_report),
    do:
      raise(
        ArgumentError,
        "command window report must be a command_window_report.v1 map or activities must be a list"
      )

  def report(activities, opts) when is_list(activities) do
    source = opts |> Keyword.get(:source, "activities") |> to_string()
    source_assumption = Keyword.get(opts, :source_assumption, source)

    command_window_rows =
      activities
      |> Enum.map(&normalize_source_activity/1)
      |> Timeline.normalize_activities(
        validate_missing_dependencies?: Keyword.get(opts, :validate_missing_dependencies?, false)
      )
      |> Enum.filter(&command_window_row?/1)

    {command_window_rows, station_calendar_report} =
      apply_station_calendar_overlay(command_window_rows, opts, source)

    rows =
      command_window_rows
      |> Enum.with_index(1)
      |> Enum.map(fn {row, rank} ->
        command_window_row(row, rank, Keyword.get(opts, :approval_policy))
      end)

    %{
      "schema_contract" => @schema_contract,
      "model" => "artifact_only_command_window_report",
      "source" => source,
      "window_count" => length(rows),
      "command_count" => Enum.count(rows, &(&1["window_type"] == "command_window")),
      "tracking_count" => Enum.count(rows, &(&1["window_type"] == "tracking_window")),
      "uplink_count" => Enum.count(rows, &(&1["window_type"] == "uplink_window")),
      "health_check_count" => Enum.count(rows, &(&1["window_type"] == "health_check_window")),
      "activity_ids_by_window_type" => activity_ids_by_field(rows, "window_type"),
      "invalid_activity_input_count" => Enum.count(rows, &(&1["invalid_activity_input"] == true)),
      "invalid_activity_input_ids" =>
        rows
        |> Enum.filter(&(&1["invalid_activity_input"] == true))
        |> Enum.map(& &1["activity_id"]),
      "review_required_count" =>
        Enum.count(rows, &(&1["required_operator_action"] not in no_review_actions())),
      "review_activity_ids_by_required_operator_action" =>
        rows
        |> Enum.filter(&(&1["required_operator_action"] not in no_review_actions()))
        |> activity_ids_by_field("required_operator_action"),
      "source_window_lineage_count" => Enum.count(rows, & &1["has_source_window"]),
      "model_limits" => model_limits(),
      "rows" => rows,
      "station_calendar_report" => station_calendar_report,
      "assumptions" => %{
        "boundary" => "artifact_only_no_schedule_mutation_or_command_execution",
        "source" => source_assumption,
        "timeline_identity" => "derived_when_activity_has_no_persistent_timeline_id",
        "dependency_model" =>
          "dependencies and exclusivity are checked inside the artifact when referenced rows are present; missing dependency checks are opt-in and schedules are not mutated",
        "missing_dependency_validation" =>
          if(Keyword.get(opts, :validate_missing_dependencies?, false),
            do: "enabled",
            else: "disabled"
          )
      }
    }
    |> compact_map()
  end

  def report(_activities, _opts),
    do: raise(ArgumentError, "activities must be a list")

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp command_window_row?(row) do
    row["activity_type"] in @window_activity_types or row["direction"] in @window_directions or
      invalid_command_window_input?(row)
  end

  defp apply_station_calendar_overlay(rows, opts, source) do
    case Keyword.get(opts, :station_calendar) || Keyword.get(opts, :ground_network) do
      nil ->
        {rows, nil}

      [] ->
        {rows, nil}

      station_calendar ->
        StationCalendar.overlay_contacts(rows, station_calendar,
          source: "#{source}.station_calendar",
          approval_policy: Keyword.get(opts, :approval_policy)
        )
    end
  end

  defp command_window_row(row, rank, approval_policy) do
    row =
      row
      |> put_derived_station_availability()
      |> put_derived_station_calendar_status()
      |> put_derived_station_reservation_context()
      |> put_derived_station_calendar_reservation_context()

    command_window_id = "command_window:#{row["activity_id"]}"
    command_window_type = window_type(row)
    required_operator_action = command_window_required_operator_action(row)
    operator_action_reason = command_window_operator_action_reason(row)

    superseded_required_operator_action =
      command_window_superseded_required_operator_action(row, required_operator_action)

    superseded_operator_action_reason =
      command_window_superseded_operator_action_reason(
        row,
        required_operator_action,
        operator_action_reason
      )

    %{
      "id" => command_window_id,
      "rank" => rank,
      "activity_id" => row["activity_id"],
      "timeline_id" => row["timeline_id"],
      "scenario_id" => row["scenario_id"],
      "activity_type" => row["activity_type"],
      "window_type" => command_window_type,
      "direction" => window_value(row, "direction"),
      "ground_station_id" => window_value(row, "ground_station_id"),
      "starts_at_s" => window_value(row, "starts_at_s"),
      "ends_at_s" => window_value(row, "ends_at_s"),
      "status" => row["status"],
      "approval_status" => row["approval_status"],
      "locked" => row["locked"],
      "contact_success" => context_value(row, "contact_success"),
      "contact_result" => provider_result_artifact_value(context_value(row, "contact_result")),
      "command_success" => context_value(row, "command_success"),
      "command_result" => provider_result_artifact_value(context_value(row, "command_result")),
      "command_success_factor" => context_value(row, "command_success_factor"),
      "command_success_factor_source" => context_value(row, "command_success_factor_source"),
      "station_availability" => row["station_availability"],
      "capacity_fraction" => command_window_capacity_fraction(row),
      "station_contention_status" => row["station_contention_status"],
      "station_calendar_entry_id" => row_context_value(row, "station_calendar_entry_id"),
      "station_calendar_provider_id" => row_context_value(row, "station_calendar_provider_id"),
      "station_calendar_provider_entry_id" =>
        row_context_value(row, "station_calendar_provider_entry_id"),
      "station_calendar_directions" => row_context_value(row, "station_calendar_directions"),
      "station_calendar_status" => row_context_value(row, "station_calendar_status"),
      "station_calendar_trust_boundary_status" =>
        row_context_value(row, "station_calendar_trust_boundary_status"),
      "trust_boundary" => row_context_value(row, "trust_boundary"),
      "provenance" => row_context_value(row, "provenance"),
      "source_station_calendar_entry" => row_context_value(row, "source_station_calendar_entry"),
      "source_station_calendar_overlaps" =>
        row_context_value(row, "source_station_calendar_overlaps"),
      "station_calendar_reservation_overlap_count" =>
        row["station_calendar_reservation_overlap_count"],
      "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
      "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
      "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
      "station_calendar_reservation_expires_at_s" =>
        row["station_calendar_reservation_expires_at_s"],
      "station_reservation_id" => row["station_reservation_id"],
      "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
      "station_reserved_by" => row["station_reserved_by"],
      "station_reservation_status" => row["station_reservation_status"],
      "station_reservation_match_status" => row["station_reservation_match_status"],
      "required_operator_action" => required_operator_action,
      "operator_action_reason" => operator_action_reason,
      "superseded_required_operator_action" => superseded_required_operator_action,
      "superseded_operator_action_reason" => superseded_operator_action_reason,
      "timeline_integrity_status" => row["timeline_integrity_status"],
      "timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
      "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
      "timeline_integrity_issues" => row["timeline_integrity_issues"],
      "missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
      "missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
      "dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
      "dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
      "dependency_order_violation_activity_ids" => row["dependency_order_violation_activity_ids"],
      "dependency_order_violation_timeline_ids" => row["dependency_order_violation_timeline_ids"],
      "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
      "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
      "exclusivity_violation_group" => row["exclusivity_violation_group"],
      "execution_boundary" => row["execution_boundary"],
      "cadence_import_status" => row["cadence_import_status"],
      "cadence_import_type" => row["cadence_import_type"],
      "dependency_activity_ids" => row_context_value(row, "dependency_activity_ids"),
      "dependency_timeline_ids" => row_context_value(row, "dependency_timeline_ids"),
      "exclusive_with_activity_ids" => row_context_value(row, "exclusive_with_activity_ids"),
      "exclusive_with_timeline_ids" => row_context_value(row, "exclusive_with_timeline_ids"),
      "source_window_id" => row["source_window_id"],
      "source_window_type" => row["source_window_type"],
      "has_source_window" => row["has_source_window"],
      "has_cadence_import" => row["has_cadence_import"],
      "timeline_identity" => row["timeline_identity"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "source_activity" => row["source_activity"],
      "activity_context" =>
        command_window_activity_context(row, command_window_id, command_window_type)
    }
    |> compact_map()
    |> maybe_apply_approval_policy(approval_policy)
  end

  defp command_window_required_operator_action(%{"required_operator_action" => action} = row) do
    if action in station_calendar_review_supersedable_actions() and
         station_calendar_review_required?(row) do
      "review_command_window_station_calendar"
    else
      action
    end
  end

  defp command_window_required_operator_action(row), do: row["required_operator_action"]

  defp command_window_superseded_required_operator_action(row, required_operator_action) do
    original_action = row["required_operator_action"]

    cond do
      row["superseded_required_operator_action"] ->
        row["superseded_required_operator_action"]

      required_operator_action == "review_command_window_station_calendar" and
        original_action not in [nil, required_operator_action] and
          original_action not in no_review_actions() ->
        original_action

      true ->
        nil
    end
  end

  defp command_window_superseded_operator_action_reason(
         row,
         required_operator_action,
         operator_action_reason
       ) do
    original_reason = row["operator_action_reason"]

    cond do
      row["superseded_operator_action_reason"] ->
        row["superseded_operator_action_reason"]

      required_operator_action == "review_command_window_station_calendar" and
        original_reason not in [nil, operator_action_reason] and
          row["required_operator_action"] not in no_review_actions() ->
        original_reason

      true ->
        nil
    end
  end

  defp command_window_operator_action_reason(row) do
    if command_window_required_operator_action(row) == "review_command_window_station_calendar" do
      "station_calendar_#{row["station_availability"]}_command_window"
    else
      row["operator_action_reason"]
    end
  end

  defp station_calendar_review_required?(%{"station_availability" => availability})
       when availability in ["unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp station_calendar_review_required?(_row), do: false

  defp put_derived_station_availability(row) do
    case station_availability(row) do
      nil -> row
      availability -> Map.put(row, "station_availability", availability)
    end
  end

  defp put_derived_station_calendar_status(row) do
    case station_calendar_status(row) do
      nil -> row
      status -> Map.put(row, "station_calendar_status", status)
    end
  end

  defp station_availability(row) do
    row
    |> station_availability_candidates()
    |> Enum.filter(&station_availability_value?/1)
    |> highest_station_availability()
    |> canonical_station_availability()
  end

  defp station_calendar_status(row) do
    row
    |> station_calendar_status_candidates()
    |> Enum.filter(&station_availability_value?/1)
    |> highest_station_availability()
    |> canonical_station_availability()
  end

  defp station_availability_candidates(row) do
    [
      row["station_availability"],
      row["availability"],
      row["station_calendar_status"]
    ] ++
      source_station_calendar_availability_candidates(row["source_station_calendar_entry"]) ++
      source_station_calendar_availability_candidates(row["source_station_calendar_overlaps"]) ++
      source_station_calendar_availability_candidates(
        context_value(row, "source_station_calendar_entry")
      ) ++
      source_station_calendar_availability_candidates(
        context_value(row, "source_station_calendar_overlaps")
      )
  end

  defp station_calendar_status_candidates(row) do
    [
      row["station_calendar_status"],
      row["availability"]
    ] ++
      source_station_calendar_status_candidates(row["source_station_calendar_entry"]) ++
      source_station_calendar_status_candidates(row["source_station_calendar_overlaps"]) ++
      source_station_calendar_status_candidates(
        context_value(row, "source_station_calendar_entry")
      ) ++
      source_station_calendar_status_candidates(
        context_value(row, "source_station_calendar_overlaps")
      )
  end

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

  defp source_station_calendar_status_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_status_candidates/1)

  defp source_station_calendar_status_candidates(%{} = source) do
    [
      source["station_calendar_status"],
      source["status"],
      source["availability"]
    ]
  end

  defp source_station_calendar_status_candidates(_source), do: []

  defp highest_station_availability([]), do: nil

  defp highest_station_availability(values),
    do: Enum.max_by(values, &station_availability_severity/1)

  defp station_availability_value?(value)
       when value in ["available", "unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp station_availability_value?(value) when value in @unavailable_aliases, do: true
  defp station_availability_value?(_value), do: false

  defp station_availability_severity(value) when value in @unavailable_aliases,
    do: @station_availability_severity["unavailable"]

  defp station_availability_severity(value), do: Map.get(@station_availability_severity, value, 0)

  defp canonical_station_availability(value)
       when value in ["unavailable", "maintenance" | @unavailable_aliases],
       do: "unavailable"

  defp canonical_station_availability(value), do: value

  defp put_derived_station_reservation_context(row) do
    match_status = station_reservation_match_status(row)

    row
    |> put_derived_station_reservation_field(
      "station_reservation_id",
      station_reservation_id(row)
    )
    |> put_derived_station_reservation_field("station_reserved_by", station_reserved_by(row))
    |> put_derived_station_reservation_field(
      "station_reservation_status",
      station_reservation_status(row)
    )
    |> put_derived_station_reservation_field(
      "station_reservation_expires_at_s",
      station_reservation_expires_at_s(row)
    )
    |> put_derived_station_reservation_field(
      "station_reservation_match_status",
      match_status
    )
  end

  defp put_derived_station_reservation_field(row, _field, nil), do: row

  defp put_derived_station_reservation_field(row, field, value),
    do: Map.put_new(row, field, value)

  defp station_reservation_id(row) do
    row
    |> station_reservation_id_candidates()
    |> first_present_value()
  end

  defp station_reserved_by(row) do
    row
    |> station_reserved_by_candidates()
    |> first_present_value()
  end

  defp station_reservation_status(row) do
    row
    |> station_reservation_status_candidates()
    |> first_present_value()
  end

  defp station_reservation_match_status(row) do
    row
    |> station_reservation_match_status_candidates()
    |> first_present_value()
    |> case do
      nil -> derived_station_reservation_match_status(row)
      value -> value
    end
  end

  defp station_reservation_id_candidates(row) do
    [row["station_reservation_id"], row["reservation_id"]] ++
      source_station_reservation_id_candidates(row["source_station_calendar_entry"]) ++
      source_station_reservation_id_candidates(
        context_value(row, "source_station_calendar_entry")
      )
  end

  defp station_reserved_by_candidates(row) do
    [row["station_reserved_by"], row["reserved_by"]] ++
      source_station_reserved_by_candidates(row["source_station_calendar_entry"]) ++
      source_station_reserved_by_candidates(context_value(row, "source_station_calendar_entry"))
  end

  defp station_reservation_status_candidates(row) do
    [row["station_reservation_status"], row["reservation_status"]] ++
      source_station_reservation_status_candidates(row["source_station_calendar_entry"]) ++
      source_station_reservation_status_candidates(
        context_value(row, "source_station_calendar_entry")
      )
  end

  defp station_reservation_match_status_candidates(row) do
    [row["station_reservation_match_status"], row["reservation_match_status"]] ++
      source_station_reservation_match_status_candidates(row["source_station_calendar_entry"]) ++
      source_station_reservation_match_status_candidates(
        context_value(row, "source_station_calendar_entry")
      )
  end

  defp derived_station_reservation_match_status(row) do
    explicit_reservation_id = row["station_reservation_id"] || row["reservation_id"]

    source_reservation_ids =
      source_station_reservation_id_candidates(row["source_station_calendar_entry"]) ++
        source_station_reservation_id_candidates(
          context_value(row, "source_station_calendar_entry")
        )

    cond do
      explicit_reservation_id in [nil, ""] and
          first_present_value(source_reservation_ids) not in [nil, ""] ->
        "overlap"

      explicit_reservation_id not in [nil, ""] and
          explicit_reservation_id in source_reservation_ids ->
        "matched"

      true ->
        nil
    end
  end

  defp source_station_reservation_id_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_reservation_id_candidates/1)

  defp source_station_reservation_id_candidates(%{} = source) do
    [
      source["station_reservation_id"],
      source["reservation_id"],
      reserved_source_entry_id(source)
    ]
  end

  defp source_station_reservation_id_candidates(_source), do: []

  defp source_station_reserved_by_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_reserved_by_candidates/1)

  defp source_station_reserved_by_candidates(%{} = source) do
    [source["station_reserved_by"], source["reserved_by"]]
  end

  defp source_station_reserved_by_candidates(_source), do: []

  defp source_station_reservation_status_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_reservation_status_candidates/1)

  defp source_station_reservation_status_candidates(%{} = source) do
    [
      source["station_reservation_status"],
      source["reservation_status"],
      reserved_source_status(source)
    ]
  end

  defp source_station_reservation_status_candidates(_source), do: []

  defp source_station_reservation_match_status_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_reservation_match_status_candidates/1)

  defp source_station_reservation_match_status_candidates(%{} = source) do
    [source["station_reservation_match_status"], source["reservation_match_status"]]
  end

  defp source_station_reservation_match_status_candidates(_source), do: []

  defp reserved_source_entry_id(%{} = source) do
    if reserved_source?(source), do: source["id"]
  end

  defp reserved_source_status(%{} = source) do
    if reserved_source?(source), do: source["reservation_status"] || "reserved"
  end

  defp reserved_source?(%{} = source) do
    source["availability"] == "reserved" or source["status"] == "reserved" or
      source["station_availability"] == "reserved" or
      source["station_calendar_status"] == "reserved" or
      source["reservation_status"] not in [nil, ""]
  end

  defp first_present_value(values) do
    Enum.find(values, &(&1 not in [nil, ""]))
  end

  defp put_derived_station_calendar_reservation_context(row) do
    reservation_ids = station_calendar_reservation_ids(row)

    row
    |> put_derived_station_reservation_field(
      "station_calendar_reservation_overlap_count",
      station_calendar_reservation_overlap_count(row, reservation_ids)
    )
    |> put_derived_station_reservation_field(
      "station_calendar_reservation_ids",
      reservation_ids
    )
    |> put_derived_station_reservation_field(
      "station_calendar_reserved_by",
      station_calendar_reserved_by(row)
    )
    |> put_derived_station_reservation_field(
      "station_calendar_reservation_statuses",
      station_calendar_reservation_statuses(row)
    )
    |> put_derived_station_reservation_field(
      "station_calendar_reservation_expires_at_s",
      station_calendar_reservation_expires_at_s(row)
    )
  end

  defp station_calendar_reservation_overlap_count(row, reservation_ids) do
    cond do
      row["station_calendar_reservation_overlap_count"] not in [nil, ""] ->
        row["station_calendar_reservation_overlap_count"]

      reservation_ids not in [nil, []] ->
        length(reservation_ids)

      true ->
        nil
    end
  end

  defp station_calendar_reservation_ids(row) do
    row
    |> Map.get("station_calendar_reservation_ids")
    |> normalized_list_or_nil()
    |> case do
      nil ->
        row
        |> station_calendar_reservation_sources()
        |> Enum.map(&source_station_calendar_reservation_id/1)
        |> normalized_list_or_nil()

      ids ->
        ids
    end
  end

  defp source_station_calendar_reservation_id(%{} = source) do
    source["station_reservation_id"] || source["reservation_id"] ||
      reserved_source_entry_id(source)
  end

  defp source_station_calendar_reservation_id(_source), do: nil

  defp station_calendar_reserved_by(row) do
    row
    |> Map.get("station_calendar_reserved_by")
    |> normalized_list_or_nil()
    |> case do
      nil ->
        row
        |> station_calendar_reservation_sources()
        |> Enum.flat_map(&source_station_reserved_by_candidates/1)
        |> normalized_list_or_nil()

      owners ->
        owners
    end
  end

  defp station_calendar_reservation_statuses(row) do
    row
    |> Map.get("station_calendar_reservation_statuses")
    |> normalized_list_or_nil()
    |> case do
      nil ->
        row
        |> station_calendar_reservation_sources()
        |> Enum.flat_map(&source_station_reservation_status_candidates/1)
        |> normalized_list_or_nil()

      statuses ->
        statuses
    end
  end

  defp station_reservation_expires_at_s(row) do
    row
    |> station_reservation_expires_at_candidates()
    |> Enum.find_value(&numeric_value/1)
  end

  defp station_reservation_expires_at_candidates(row) do
    [
      row["station_reservation_expires_at_s"],
      row["reservation_expires_at_s"],
      row["reservation_hold_expires_at_s"],
      row["hold_expires_at_s"],
      row["expires_at_s"],
      row["expires_at"]
    ] ++
      source_station_reservation_expires_at_candidates(row["source_station_calendar_entry"]) ++
      source_station_reservation_expires_at_candidates(
        context_value(row, "source_station_calendar_entry")
      )
  end

  defp station_calendar_reservation_expires_at_s(row) do
    ([
       row["station_calendar_reservation_expires_at_s"],
       row["station_reservation_expires_at_s"],
       row["reservation_expires_at_s"],
       row["reservation_hold_expires_at_s"],
       row["hold_expires_at_s"],
       row["expires_at_s"],
       row["expires_at"]
     ] ++
       source_station_reservation_expires_at_candidates(row["source_station_calendar_entry"]) ++
       source_station_reservation_expires_at_candidates(
         context_value(row, "source_station_calendar_entry")
       ) ++
       (row
        |> station_calendar_reservation_sources()
        |> Enum.flat_map(&source_station_reservation_expires_at_candidates/1)))
    |> normalized_number_list_or_nil()
  end

  defp source_station_reservation_expires_at_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_reservation_expires_at_candidates/1)

  defp source_station_reservation_expires_at_candidates(%{} = source) do
    [
      source["station_calendar_reservation_expires_at_s"],
      source["station_reservation_expires_at_s"],
      source["reservation_expires_at_s"],
      source["reservation_hold_expires_at_s"],
      source["hold_expires_at_s"],
      source["expires_at_s"],
      source["expires_at"]
    ]
  end

  defp source_station_reservation_expires_at_candidates(_source), do: []

  defp station_calendar_reservation_sources(row) do
    source_station_calendar_sources(row["source_station_calendar_overlaps"]) ++
      source_station_calendar_sources(context_value(row, "source_station_calendar_overlaps"))
  end

  defp source_station_calendar_sources(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_sources/1)

  defp source_station_calendar_sources(%{} = source) do
    if reserved_source?(source), do: [source], else: []
  end

  defp source_station_calendar_sources(_source), do: []

  defp normalized_list_or_nil(nil), do: nil
  defp normalized_list_or_nil(value) when value in ["", []], do: nil

  defp normalized_list_or_nil(values) when is_list(values) do
    values =
      values
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()
      |> Enum.sort()

    if values == [], do: nil, else: values
  end

  defp normalized_list_or_nil(value), do: normalized_list_or_nil([value])

  defp normalized_number_list_or_nil(values) do
    values =
      values
      |> List.flatten()
      |> Enum.map(&numeric_value/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    if values == [], do: nil, else: values
  end

  defp command_window_capacity_fraction(row) do
    [
      row["capacity_pack_capacity_fraction"],
      row["station_capacity_fraction"],
      row["capacity_fraction"],
      capacity_percent_fraction(row),
      source_activity_value(row, "capacity_pack_capacity_fraction"),
      source_activity_value(row, "station_capacity_fraction"),
      source_activity_value(row, "capacity_fraction"),
      capacity_percent_fraction(row["source_activity"]),
      get_in(row, ["throughput_model", "station_capacity_fraction"]),
      get_in(row, ["throughput_model", "capacity_fraction"]),
      capacity_percent_fraction(row["throughput_model"]),
      get_in(row, ["capacity_model", "station_capacity_fraction"]),
      get_in(row, ["capacity_model", "capacity_fraction"]),
      capacity_percent_fraction(row["capacity_model"]),
      context_value(row, "capacity_pack_capacity_fraction"),
      context_value(row, "station_capacity_fraction"),
      context_value(row, "capacity_fraction"),
      capacity_percent_fraction(row["activity_context"]),
      source_station_capacity_fraction(
        source_activity_value(row, "source_station_calendar_entry")
      ),
      source_station_capacity_fraction(
        source_activity_value(row, "source_station_calendar_overlaps")
      ),
      source_station_capacity_fraction(row["source_station_calendar_entry"]),
      source_station_capacity_fraction(row["source_station_calendar_overlaps"]),
      source_station_capacity_fraction(context_value(row, "source_station_calendar_entry")),
      source_station_capacity_fraction(context_value(row, "source_station_calendar_overlaps"))
    ]
    |> Enum.find_value(&numeric_value/1)
  end

  defp source_station_capacity_fraction(sources) when is_list(sources),
    do: Enum.find_value(sources, &source_station_capacity_fraction/1)

  defp source_station_capacity_fraction(%{} = source) do
    [
      source["station_capacity_fraction"],
      source["capacity_pack_capacity_fraction"],
      source["capacity_fraction"],
      capacity_percent_fraction(source),
      get_in(source, ["throughput_model", "station_capacity_fraction"]),
      get_in(source, ["throughput_model", "capacity_fraction"]),
      capacity_percent_fraction(source["throughput_model"]),
      get_in(source, ["capacity_model", "station_capacity_fraction"]),
      get_in(source, ["capacity_model", "capacity_fraction"]),
      capacity_percent_fraction(source["capacity_model"]),
      get_in(source, ["activity_context", "capacity_pack_capacity_fraction"]),
      get_in(source, ["activity_context", "station_capacity_fraction"]),
      get_in(source, ["activity_context", "capacity_fraction"]),
      capacity_percent_fraction(source["activity_context"])
    ]
    |> Enum.find_value(&numeric_value/1)
  end

  defp source_station_capacity_fraction(_source), do: nil

  defp capacity_percent_fraction(%{} = source) do
    [
      source["station_capacity_percent"],
      source["capacity_percent"]
    ]
    |> Enum.find_value(fn value ->
      case numeric_value(value) do
        value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
        _value -> nil
      end
    end)
  end

  defp capacity_percent_fraction(_source), do: nil

  defp command_window_activity_context(row, command_window_id, command_window_type) do
    (row["activity_context"] || %{})
    |> normalize_provider_result_artifact_fields()
    |> Map.merge(%{
      "activity_id" => row["activity_id"],
      "timeline_id" => row["timeline_id"],
      "activity_type" => row["activity_type"],
      "scenario_id" => row["scenario_id"],
      "window_type" => command_window_type,
      "command_window_id" => command_window_id,
      "command_window_type" => command_window_type,
      "timeline_integrity_status" => row["timeline_integrity_status"],
      "timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
      "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
      "timeline_integrity_issues" => row["timeline_integrity_issues"],
      "missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
      "missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
      "dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
      "dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
      "dependency_order_violation_activity_ids" => row["dependency_order_violation_activity_ids"],
      "dependency_order_violation_timeline_ids" => row["dependency_order_violation_timeline_ids"],
      "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
      "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
      "exclusivity_violation_group" => row["exclusivity_violation_group"],
      "station_availability" => row["station_availability"],
      "capacity_fraction" => command_window_capacity_fraction(row),
      "station_calendar_entry_id" => row["station_calendar_entry_id"],
      "station_calendar_provider_id" => row["station_calendar_provider_id"],
      "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
      "station_calendar_directions" => row["station_calendar_directions"],
      "station_calendar_status" => row["station_calendar_status"],
      "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
      "trust_boundary" => row["trust_boundary"],
      "provenance" => row["provenance"],
      "source_station_calendar_entry" => row["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
      "station_calendar_reservation_overlap_count" =>
        row["station_calendar_reservation_overlap_count"],
      "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
      "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
      "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
      "station_reservation_id" => row["station_reservation_id"],
      "station_reserved_by" => row["station_reserved_by"],
      "station_reservation_status" => row["station_reservation_status"],
      "station_reservation_match_status" => row["station_reservation_match_status"]
    })
    |> compact_map()
  end

  defp maybe_apply_approval_policy(row, nil), do: row

  defp maybe_apply_approval_policy(row, approval_policy) do
    if row["required_operator_action"] in no_review_actions() do
      row
    else
      requirement = command_window_approval_requirement(row)

      {status, requirements, matches, decision} =
        Policy.decide(
          [requirement],
          [],
          %{"id" => "command_window", "events" => []},
          %{},
          approval_policy
        )

      row
      |> Map.put("approval_status", status)
      |> Map.put("approval_requirements", requirements)
      |> Map.put("approval_rule_matches", matches)
      |> Map.put("policy_decision", decision)
    end
  end

  defp command_window_approval_requirement(row) do
    %{
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "action" => row["required_operator_action"],
      "requirement_type" => command_window_requirement_type(row),
      "reason" => row["operator_action_reason"] || "command window requires operator review",
      "activity_context" =>
        (row["activity_context"] || %{})
        |> normalize_provider_result_artifact_fields()
        |> Map.merge(%{
          "activity_id" => row["activity_id"],
          "timeline_id" => row["timeline_id"],
          "activity_type" => row["activity_type"],
          "scenario_id" => row["scenario_id"],
          "window_type" => row["window_type"],
          "command_window_id" => row["id"],
          "command_window_type" => row["window_type"],
          "required_operator_action" => row["required_operator_action"],
          "operator_action_reason" => row["operator_action_reason"],
          "direction" => row["direction"],
          "ground_station_id" => row["ground_station_id"],
          "starts_at_s" => row["starts_at_s"],
          "ends_at_s" => row["ends_at_s"],
          "status" => row["status"],
          "approval_status" => row["approval_status"],
          "locked" => row["locked"],
          "contact_success" => row["contact_success"],
          "contact_result" => provider_result_artifact_value(row["contact_result"]),
          "command_success" => row["command_success"],
          "command_result" => provider_result_artifact_value(row["command_result"]),
          "command_success_factor" => row["command_success_factor"],
          "command_success_factor_source" => row["command_success_factor_source"],
          "station_availability" => row["station_availability"],
          "capacity_fraction" => command_window_capacity_fraction(row),
          "station_contention_status" => row["station_contention_status"],
          "station_calendar_entry_id" => row["station_calendar_entry_id"],
          "station_calendar_provider_id" => row["station_calendar_provider_id"],
          "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
          "station_calendar_directions" => row["station_calendar_directions"],
          "station_calendar_status" => row["station_calendar_status"],
          "station_calendar_trust_boundary_status" =>
            row["station_calendar_trust_boundary_status"],
          "trust_boundary" => row["trust_boundary"],
          "provenance" => row["provenance"],
          "source_station_calendar_entry" => row["source_station_calendar_entry"],
          "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
          "station_calendar_reservation_overlap_count" =>
            row["station_calendar_reservation_overlap_count"],
          "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
          "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
          "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
          "station_calendar_reservation_expires_at_s" =>
            row["station_calendar_reservation_expires_at_s"],
          "station_reservation_id" => row["station_reservation_id"],
          "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
          "station_reserved_by" => row["station_reserved_by"],
          "station_reservation_status" => row["station_reservation_status"],
          "station_reservation_match_status" => row["station_reservation_match_status"],
          "cadence_import_status" => row["cadence_import_status"],
          "cadence_import_type" => row["cadence_import_type"],
          "timeline_integrity_status" => row["timeline_integrity_status"],
          "timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
          "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
          "missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
          "missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
          "dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
          "dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
          "dependency_order_violation_activity_ids" =>
            row["dependency_order_violation_activity_ids"],
          "dependency_order_violation_timeline_ids" =>
            row["dependency_order_violation_timeline_ids"],
          "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
          "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
          "exclusivity_violation_group" => row["exclusivity_violation_group"],
          "dependency_activity_ids" => row["dependency_activity_ids"],
          "dependency_timeline_ids" => row["dependency_timeline_ids"],
          "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
          "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
          "source_window_id" => row["source_window_id"],
          "source_window_type" => row["source_window_type"],
          "has_source_window" => row["has_source_window"],
          "has_cadence_import" => row["has_cadence_import"],
          "timeline_identity" => row["timeline_identity"]
        })
        |> compact_map()
    }
    |> compact_map()
  end

  defp command_window_requirement_type(%{"window_type" => "health_check_window"}),
    do: "health_check_review"

  defp command_window_requirement_type(%{"window_type" => "command_window"}),
    do: "command_review"

  defp command_window_requirement_type(%{"window_type" => "uplink_window"}),
    do: "command_review"

  defp command_window_requirement_type(_row), do: "contact_schedule_change"

  defp window_type(%{"activity_type" => "command"}), do: "command_window"
  defp window_type(%{"activity_type" => "health_check"}), do: "health_check_window"
  defp window_type(%{"activity_type" => "tracking"}), do: "tracking_window"
  defp window_type(%{"direction" => "health_check"}), do: "health_check_window"
  defp window_type(%{"direction" => "tracking"}), do: "tracking_window"
  defp window_type(%{"direction" => "uplink"}), do: "uplink_window"
  defp window_type(%{"direction" => "command"}), do: "command_window"

  defp window_type(%{"invalid_activity_input" => true} = row),
    do: source_window_type(Map.get(row, "source_activity", %{}))

  defp window_type(_row), do: "command_context_window"

  defp invalid_command_window_input?(%{"invalid_activity_input" => true} = row) do
    source = Map.get(row, "source_activity", %{})

    source_command_window_intent?(source) and source_has_window_interval?(source)
  end

  defp invalid_command_window_input?(_row), do: false

  defp source_command_window_intent?(%{} = source) do
    source["type"] in @window_activity_types or source["direction"] in @window_directions
  end

  defp source_command_window_intent?(_source), do: false

  defp source_has_window_interval?(%{} = source) do
    is_number(source["starts_at_s"] || source["start_s"]) and
      is_number(source["ends_at_s"] || source["end_s"])
  end

  defp source_window_type(%{"type" => "command"}), do: "command_window"
  defp source_window_type(%{"type" => "health_check"}), do: "health_check_window"
  defp source_window_type(%{"type" => "tracking"}), do: "tracking_window"
  defp source_window_type(%{"direction" => "health_check"}), do: "health_check_window"
  defp source_window_type(%{"direction" => "tracking"}), do: "tracking_window"
  defp source_window_type(%{"direction" => "uplink"}), do: "uplink_window"
  defp source_window_type(%{"direction" => "command"}), do: "command_window"
  defp source_window_type(_source), do: "command_context_window"

  defp window_value(%{"invalid_activity_input" => true} = row, "starts_at_s"),
    do: source_activity_value(row, "starts_at_s") || source_activity_value(row, "start_s")

  defp window_value(%{"invalid_activity_input" => true} = row, "ends_at_s"),
    do: source_activity_value(row, "ends_at_s") || source_activity_value(row, "end_s")

  defp window_value(%{"invalid_activity_input" => true} = row, field),
    do: row[field] || source_activity_value(row, field)

  defp window_value(row, field), do: row[field]

  defp source_activity_value(row, field) do
    get_in(row, ["source_activity", field])
  end

  defp normalize_source_activity(%OrbitalDynamics.MissionPlan.Activity{} = activity), do: activity

  defp normalize_source_activity(%{} = activity) do
    activity
    |> stringify_keys()
    |> normalize_activity_time("starts_at_s", "start_s")
    |> normalize_activity_time("ends_at_s", "end_s")
    |> normalize_station_calendar_status_fields()
    |> normalize_station_reservation_aliases()
    |> normalize_direction_field("direction")
    |> normalize_number_field("command_success_factor")
    |> normalize_number_field("contact_success_factor")
    |> normalize_capacity_percent_alias()
    |> normalize_number_field("capacity_pack_capacity_fraction")
    |> normalize_number_field("capacity_fraction")
    |> normalize_number_field("station_capacity_fraction")
  end

  defp normalize_source_activity(activity), do: activity

  defp normalize_station_reservation_aliases(activity) do
    activity
    |> put_alias_if_present("station_reservation_id", "reservation_id")
    |> put_alias_if_present("station_reserved_by", "reserved_by")
    |> put_alias_if_present("station_reservation_status", "reservation_status")
    |> put_alias_if_present("station_reservation_match_status", "reservation_match_status")
  end

  defp put_alias_if_present(activity, canonical_field, alias_field) do
    case {Map.get(activity, canonical_field), Map.get(activity, alias_field)} do
      {value, _alias_value} when value not in [nil, ""] ->
        activity

      {_value, alias_value} when alias_value not in [nil, ""] ->
        Map.put(activity, canonical_field, alias_value)

      _missing ->
        activity
    end
  end

  defp normalize_activity_time(activity, canonical_key, alternate_key) do
    canonical_value = numeric_value(Map.get(activity, canonical_key))
    alternate_value = numeric_value(Map.get(activity, alternate_key))

    cond do
      is_number(canonical_value) -> Map.put(activity, canonical_key, canonical_value)
      is_number(alternate_value) -> Map.put(activity, canonical_key, alternate_value)
      true -> activity
    end
  end

  defp normalize_number_field(activity, field) do
    case numeric_value(Map.get(activity, field)) do
      nil -> activity
      number -> Map.put(activity, field, number)
    end
  end

  defp normalize_capacity_percent_alias(activity) do
    case capacity_percent_fraction(activity) do
      value when is_number(value) -> Map.put_new(activity, "capacity_fraction", value)
      _value -> activity
    end
  end

  defp normalize_station_calendar_status_fields(activity) do
    activity
    |> normalize_status_field("availability")
    |> normalize_status_field("station_availability")
    |> normalize_status_field("station_calendar_status")
    |> normalize_status_field("station_contention_status")
    |> normalize_status_field("reservation_status")
    |> normalize_status_field("station_reservation_status")
    |> normalize_status_field("reservation_match_status")
    |> normalize_status_field("station_reservation_match_status")
    |> normalize_status_list_field("station_calendar_overlap_availabilities")
    |> normalize_status_list_field("station_calendar_reservation_statuses")
    |> normalize_direction_list_field("directions")
    |> normalize_direction_list_field("station_calendar_directions")
    |> normalize_source_station_calendar_field("source_station_calendar_entry")
    |> normalize_source_station_calendar_field("source_station_calendar_overlaps")
  end

  defp normalize_status_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, value} when value in [nil, ""] ->
        activity

      {:ok, value} ->
        Map.put(activity, field, normalized_status_token(value))

      :error ->
        activity
    end
  end

  defp normalize_status_list_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, values} when is_list(values) ->
        values =
          values
          |> Enum.map(&normalized_status_token/1)
          |> Enum.reject(&(&1 in [nil, ""]))

        Map.put(activity, field, values)

      {:ok, value} when value not in [nil, ""] ->
        Map.put(activity, field, [normalized_status_token(value)])

      _missing_or_empty ->
        activity
    end
  end

  defp normalize_source_station_calendar_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, values} when is_list(values) ->
        Map.put(activity, field, Enum.map(values, &normalize_source_station_calendar/1))

      {:ok, value} ->
        Map.put(activity, field, normalize_source_station_calendar(value))

      :error ->
        activity
    end
  end

  defp normalize_source_station_calendar(%{} = source) do
    source
    |> normalize_station_calendar_status_fields()
    |> normalize_station_reservation_aliases()
    |> normalize_direction_field("direction")
  end

  defp normalize_source_station_calendar(value), do: value

  defp normalize_direction_list_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, values} when is_list(values) ->
        directions =
          values
          |> Enum.map(&normalized_direction_token/1)
          |> Enum.reject(&is_nil/1)

        Map.put(activity, field, directions)

      {:ok, value} when value not in [nil, ""] ->
        case normalized_direction_token(value) do
          nil -> activity
          direction -> Map.put(activity, field, [direction])
        end

      _missing_or_empty ->
        activity
    end
  end

  defp normalize_direction_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, value} when value in [nil, ""] ->
        activity

      {:ok, value} ->
        case normalized_direction_token(value) do
          nil -> activity
          direction -> Map.put(activity, field, direction)
        end

      :error ->
        activity
    end
  end

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

  defp normalized_direction_token(value) when value in [nil, ""], do: nil

  defp normalized_direction_token(value) do
    value
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
      direction -> Map.get(@provider_direction_aliases, direction, direction)
    end
  end

  defp numeric_value(value) when is_integer(value) or is_float(value), do: value

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp no_review_actions do
    ["monitor_activity", "none_locked_activity", "none_terminal_activity"]
  end

  defp activity_ids_by_field(rows, field) do
    ids_by_field =
      rows
      |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "activity_id"))
      |> Enum.reject(fn {field_value, ids} ->
        is_nil(field_value) or Enum.all?(ids, &is_nil/1)
      end)
      |> Map.new(fn {field_value, ids} ->
        {field_value, ids |> Enum.reject(&is_nil/1) |> Enum.uniq() |> Enum.sort()}
      end)

    if ids_by_field == %{}, do: nil, else: ids_by_field
  end

  defp station_calendar_review_supersedable_actions do
    no_review_actions() ++ ["prepare_cadence_import"]
  end

  defp context_value(row, field), do: get_in(row, ["activity_context", field])

  defp row_context_value(row, field), do: row[field] || context_value(row, field)

  defp normalize_provider_result_artifact_fields(%{} = map) do
    ["contact_result", "command_result"]
    |> Enum.reduce(map, fn field, acc ->
      case Map.fetch(acc, field) do
        {:ok, value} ->
          case provider_result_artifact_value(value) do
            nil -> Map.delete(acc, field)
            normalized -> Map.put(acc, field, normalized)
          end

        :error ->
          acc
      end
    end)
  end

  defp normalize_provider_result_artifact_fields(value), do: value

  defp provider_result_values(result) when is_binary(result) do
    result
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(values) when is_list(values) do
    Enum.flat_map(values, &provider_result_values/1)
  end

  defp provider_result_values(%{} = result) do
    Enum.flat_map(@provider_result_map_value_keys, fn key ->
      result
      |> Map.get(key)
      |> provider_result_values()
    end)
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_values()
  end

  defp provider_result_values(result)
       when is_integer(result) or is_float(result) or is_boolean(result) do
    result
    |> to_string()
    |> provider_result_values()
  end

  defp provider_result_values(_result), do: []

  defp provider_result_artifact_value(nil), do: nil

  defp provider_result_artifact_value(result) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  defp provider_result_artifact_value(results) when is_list(results) do
    case provider_result_values(results) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(%{} = result) do
    case provider_result_values(result) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(result) when is_integer(result),
    do: Integer.to_string(result)

  defp provider_result_artifact_value(result) when is_float(result), do: Float.to_string(result)
  defp provider_result_artifact_value(result) when is_boolean(result), do: Atom.to_string(result)

  defp provider_result_artifact_value(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_artifact_value()
  end

  defp provider_result_artifact_value(_result), do: nil

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
