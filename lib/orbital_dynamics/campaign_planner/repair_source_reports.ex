defmodule OrbitalDynamics.CampaignPlanner.RepairSourceReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchRefreshSourceInputs,
    CandidateRejectionPressureEvents,
    CandidateReviewSourceReports,
    ValueEncoding
  }

  def source_window_lineage(candidate_refresh),
    do: source_window_lineage(candidate_refresh, default_callbacks())

  def source_window_lineage(nil, _callbacks), do: []

  def source_window_lineage(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    candidate_refresh
    |> stringify_keys.()
    |> Map.get("source_window_lineage")
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(stringify_keys)
  end

  def candidate_refresh_provenance(candidate_refresh),
    do: candidate_refresh_provenance(candidate_refresh, default_callbacks())

  def candidate_refresh_provenance(nil, _callbacks), do: nil

  def candidate_refresh_provenance(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    candidate_refresh
    |> stringify_keys.()
    |> Map.get("provenance")
    |> case do
      provenance when provenance == %{} -> nil
      %{} = provenance -> provenance
      _provenance -> nil
    end
  end

  def validation_records(candidate_refresh),
    do: validation_records(candidate_refresh, default_callbacks())

  def validation_records(nil, _callbacks), do: []

  def validation_records(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    candidate_refresh
    |> stringify_keys.()
    |> Map.get("validation_records")
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(stringify_keys)
  end

  def contact_intent_summary(candidate_refresh),
    do: contact_intent_summary(candidate_refresh, default_callbacks())

  def contact_intent_summary(nil, _callbacks), do: nil

  def contact_intent_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_contact_intent_summary"),
      Map.get(candidate_refresh, "contact_intent_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def realized_state_snapshot(candidate_refresh),
    do: realized_state_snapshot(candidate_refresh, default_callbacks())

  def realized_state_snapshot(nil, _callbacks), do: nil

  def realized_state_snapshot(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_realized_state_snapshot"),
      Map.get(candidate_refresh, "realized_state_snapshot")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = snapshot -> stringify_keys.(snapshot)
      _snapshot -> nil
    end
  end

  def contact_filter(candidate_refresh),
    do: contact_filter(candidate_refresh, default_callbacks())

  def contact_filter(nil, _callbacks), do: nil

  def contact_filter(%{} = candidate_refresh, callbacks),
    do: direct_report(candidate_refresh, "contact_filter_report", callbacks)

  def contact_allocation(candidate_refresh),
    do: contact_allocation(candidate_refresh, default_callbacks())

  def contact_allocation(nil, _callbacks), do: nil

  def contact_allocation(%{} = candidate_refresh, callbacks),
    do: direct_report(candidate_refresh, "contact_allocation_report", callbacks)

  def contact_allocation_summary(candidate_refresh),
    do: contact_allocation_summary(candidate_refresh, default_callbacks())

  def contact_allocation_summary(nil, _callbacks), do: nil

  def contact_allocation_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_contact_allocation_summary"),
      Map.get(candidate_refresh, "contact_allocation_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def contact_allocation_station_pressure_summary(candidate_refresh),
    do:
      contact_allocation_station_pressure_summary(
        candidate_refresh,
        default_callbacks()
      )

  def contact_allocation_station_pressure_summary(nil, _callbacks), do: nil

  def contact_allocation_station_pressure_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_contact_allocation_station_pressure_summary"),
      Map.get(candidate_refresh, "contact_allocation_station_pressure_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def contact_allocation_reservation_conflict_summary(candidate_refresh),
    do:
      contact_allocation_reservation_conflict_summary(
        candidate_refresh,
        default_callbacks()
      )

  def contact_allocation_reservation_conflict_summary(nil, _callbacks), do: nil

  def contact_allocation_reservation_conflict_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_contact_allocation_reservation_conflict_summary"),
      Map.get(candidate_refresh, "contact_allocation_reservation_conflict_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def contact_allocation_capacity_pack_summary(candidate_refresh),
    do:
      contact_allocation_capacity_pack_summary(
        candidate_refresh,
        default_callbacks()
      )

  def contact_allocation_capacity_pack_summary(nil, _callbacks), do: nil

  def contact_allocation_capacity_pack_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_contact_allocation_capacity_pack_summary"),
      Map.get(candidate_refresh, "contact_allocation_capacity_pack_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def contact_allocation_provider_reservation_request_summary(candidate_refresh),
    do:
      contact_allocation_provider_reservation_request_summary(
        candidate_refresh,
        default_callbacks()
      )

  def contact_allocation_provider_reservation_request_summary(nil, _callbacks), do: nil

  def contact_allocation_provider_reservation_request_summary(
        %{} = candidate_refresh,
        callbacks
      ) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(
        candidate_refresh,
        "source_contact_allocation_provider_reservation_request_summary"
      ),
      Map.get(candidate_refresh, "contact_allocation_provider_reservation_request_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def contact_contention(candidate_refresh),
    do: contact_contention(candidate_refresh, default_callbacks())

  def contact_contention(nil, _callbacks), do: nil

  def contact_contention(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_contact_contention_report"),
      Map.get(candidate_refresh, "contact_contention_report"),
      get_in(candidate_refresh, ["contact_allocation_report", "contact_contention_report"]),
      get_in(candidate_refresh, [
        "source_contact_allocation_report",
        "contact_contention_report"
      ])
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def contact_contention_resolution(candidate_refresh),
    do: contact_contention_resolution(candidate_refresh, default_callbacks())

  def contact_contention_resolution(nil, _callbacks), do: nil

  def contact_contention_resolution(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_contact_contention_resolution_report"),
      Map.get(candidate_refresh, "contact_contention_resolution_report"),
      get_in(candidate_refresh, [
        "contact_allocation_report",
        "contact_contention_resolution_report"
      ]),
      get_in(candidate_refresh, [
        "source_contact_allocation_report",
        "contact_contention_resolution_report"
      ])
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def contact_contention_resolution_summary(candidate_refresh),
    do: contact_contention_resolution_summary(candidate_refresh, default_callbacks())

  def contact_contention_resolution_summary(nil, _callbacks), do: nil

  def contact_contention_resolution_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_contact_contention_resolution_summary"),
      Map.get(candidate_refresh, "contact_contention_resolution_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def link_capacity(candidate_refresh),
    do: link_capacity(candidate_refresh, default_callbacks())

  def link_capacity(nil, _callbacks), do: nil

  def link_capacity(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_link_capacity_report"),
      Map.get(candidate_refresh, "link_capacity_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def link_capacity_summary(candidate_refresh),
    do: link_capacity_summary(candidate_refresh, default_callbacks())

  def link_capacity_summary(nil, _callbacks), do: nil

  def link_capacity_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_link_capacity_summary"),
      Map.get(candidate_refresh, "link_capacity_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def relay_data_path_summary(candidate_refresh),
    do: relay_data_path_summary(candidate_refresh, default_callbacks())

  def relay_data_path_summary(nil, _callbacks), do: nil

  def relay_data_path_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_relay_data_path_summary"),
      Map.get(candidate_refresh, "relay_data_path_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def station_calendar_precedence_summary(candidate_refresh),
    do: station_calendar_precedence_summary(candidate_refresh, default_callbacks())

  def station_calendar_precedence_summary(nil, _callbacks), do: nil

  def station_calendar_precedence_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_station_calendar_precedence_summary"),
      Map.get(candidate_refresh, "station_calendar_precedence_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def station_reservation(candidate_refresh),
    do: station_reservation(candidate_refresh, default_callbacks())

  def station_reservation(nil, _callbacks), do: nil

  def station_reservation(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_station_reservation_report"),
      Map.get(candidate_refresh, "station_reservation_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def station_reservation_review_summary(candidate_refresh),
    do: station_reservation_review_summary(candidate_refresh, default_callbacks())

  def station_reservation_review_summary(nil, _callbacks), do: nil

  def station_reservation_review_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_station_reservation_review_summary"),
      Map.get(candidate_refresh, "station_reservation_review_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def station_reservation_hold_import_readiness_summary(candidate_refresh),
    do:
      station_reservation_hold_import_readiness_summary(
        candidate_refresh,
        default_callbacks()
      )

  def station_reservation_hold_import_readiness_summary(nil, _callbacks), do: nil

  def station_reservation_hold_import_readiness_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_station_reservation_hold_import_readiness_summary"),
      Map.get(candidate_refresh, "station_reservation_hold_import_readiness_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def station_reservation_hold_summary(candidate_refresh),
    do: station_reservation_hold_summary(candidate_refresh, default_callbacks())

  def station_reservation_hold_summary(nil, _callbacks), do: nil

  def station_reservation_hold_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_station_reservation_hold_summary"),
      Map.get(candidate_refresh, "station_reservation_hold_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def constraint(candidate_refresh),
    do: constraint(candidate_refresh, default_callbacks())

  def constraint(nil, _callbacks), do: nil

  def constraint(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_constraint_report"),
      Map.get(candidate_refresh, "constraint_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def objective_satisfaction(candidate_refresh),
    do: objective_satisfaction(candidate_refresh, default_callbacks())

  def objective_satisfaction(nil, _callbacks), do: nil

  def objective_satisfaction(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_objective_satisfaction_report"),
      Map.get(candidate_refresh, "objective_satisfaction_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def objective_tradeoff(candidate_refresh),
    do: objective_tradeoff(candidate_refresh, default_callbacks())

  def objective_tradeoff(nil, _callbacks), do: nil

  def objective_tradeoff(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_objective_tradeoff_report"),
      Map.get(candidate_refresh, "objective_tradeoff_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def score_term(candidate_refresh), do: score_term(candidate_refresh, default_callbacks())

  def score_term(nil, _callbacks), do: nil

  def score_term(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_score_term_report"),
      Map.get(candidate_refresh, "score_term_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def timeline_diff(candidate_refresh),
    do: timeline_diff(candidate_refresh, default_callbacks())

  def timeline_diff(nil, _callbacks), do: nil

  def timeline_diff(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_timeline_diff_report"),
      Map.get(candidate_refresh, "timeline_diff_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def timeline_diff_summary(candidate_refresh),
    do: timeline_diff_summary(candidate_refresh, default_callbacks())

  def timeline_diff_summary(nil, _callbacks), do: nil

  def timeline_diff_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_timeline_diff_summary"),
      Map.get(candidate_refresh, "timeline_diff_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def timeline_integrity(candidate_refresh),
    do: timeline_integrity(candidate_refresh, default_callbacks())

  def timeline_integrity(nil, _callbacks), do: nil

  def timeline_integrity(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_timeline_integrity_report"),
      Map.get(candidate_refresh, "timeline_integrity_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def timeline_dependency_impact(candidate_refresh),
    do: timeline_dependency_impact(candidate_refresh, default_callbacks())

  def timeline_dependency_impact(nil, _callbacks), do: nil

  def timeline_dependency_impact(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_timeline_dependency_impact_summary"),
      Map.get(candidate_refresh, "timeline_dependency_impact_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def timeline_lifecycle_state(candidate_refresh),
    do: timeline_lifecycle_state(candidate_refresh, default_callbacks())

  def timeline_lifecycle_state(nil, _callbacks), do: nil

  def timeline_lifecycle_state(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_timeline_lifecycle_state_summary"),
      Map.get(candidate_refresh, "timeline_lifecycle_state_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def timeline_activity_precondition_summaries(candidate_refresh),
    do: timeline_activity_precondition_summaries(candidate_refresh, default_callbacks())

  def timeline_activity_precondition_summaries(nil, _callbacks), do: []

  def timeline_activity_precondition_summaries(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_timeline_activity_precondition_summary"),
      Map.get(candidate_refresh, "timeline_activity_precondition_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.filter(&is_map/1)
    |> Enum.map(stringify_keys)
  end

  def timeline_activity_lifecycle_states(candidate_refresh),
    do: timeline_activity_lifecycle_states(candidate_refresh, default_callbacks())

  def timeline_activity_lifecycle_states(nil, _callbacks), do: []

  def timeline_activity_lifecycle_states(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_timeline_activity_lifecycle_state"),
      Map.get(candidate_refresh, "timeline_activity_lifecycle_state")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.filter(&is_map/1)
    |> Enum.map(stringify_keys)
  end

  def timeline_activity_states(candidate_refresh),
    do: timeline_activity_states(candidate_refresh, default_callbacks())

  def timeline_activity_states(nil, _callbacks), do: []

  def timeline_activity_states(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_timeline_activity_state"),
      Map.get(candidate_refresh, "timeline_activity_state"),
      Map.get(candidate_refresh, "source_timeline_activity_status_state"),
      Map.get(candidate_refresh, "timeline_activity_status_state"),
      Map.get(candidate_refresh, "source_timeline_activity_approval_state"),
      Map.get(candidate_refresh, "timeline_activity_approval_state")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.filter(&is_map/1)
    |> Enum.map(stringify_keys)
  end

  def timeline_preservation_statuses(candidate_refresh),
    do: timeline_preservation_statuses(candidate_refresh, default_callbacks())

  def timeline_preservation_statuses(nil, _callbacks), do: []

  def timeline_preservation_statuses(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_timeline_preservation_status"),
      Map.get(candidate_refresh, "timeline_preservation_status")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.filter(&is_map/1)
    |> Enum.map(stringify_keys)
  end

  def timeline_publication_summaries(candidate_refresh),
    do: timeline_publication_summaries(candidate_refresh, default_callbacks())

  def timeline_publication_summaries(nil, _callbacks), do: []

  def timeline_publication_summaries(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_timeline_publication_summary"),
      Map.get(candidate_refresh, "timeline_publication_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.filter(&is_map/1)
    |> Enum.map(stringify_keys)
  end

  def timeline_preservation(candidate_refresh),
    do: timeline_preservation(candidate_refresh, default_callbacks())

  def timeline_preservation(nil, _callbacks), do: nil

  def timeline_preservation(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_timeline_preservation_report"),
      Map.get(candidate_refresh, "timeline_preservation_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def timeline_transition_application(candidate_refresh),
    do: timeline_transition_application(candidate_refresh, default_callbacks())

  def timeline_transition_application(nil, _callbacks), do: nil

  def timeline_transition_application(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_timeline_transition_application_report"),
      Map.get(candidate_refresh, "timeline_transition_application_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def timeline_transition_application_summary(candidate_refresh),
    do: timeline_transition_application_summary(candidate_refresh, default_callbacks())

  def timeline_transition_application_summary(nil, _callbacks), do: nil

  def timeline_transition_application_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_timeline_transition_application_summary"),
      Map.get(candidate_refresh, "timeline_transition_application_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def operational_timeline(candidate_refresh),
    do: operational_timeline(candidate_refresh, default_callbacks())

  def operational_timeline(nil, _callbacks), do: nil

  def operational_timeline(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_operational_timeline_report"),
      Map.get(candidate_refresh, "operational_timeline_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def command_window(candidate_refresh),
    do: command_window(candidate_refresh, default_callbacks())

  def command_window(nil, _callbacks), do: nil

  def command_window(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_command_window_report"),
      Map.get(candidate_refresh, "command_window_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def maneuver_review(candidate_refresh),
    do: maneuver_review(candidate_refresh, default_callbacks())

  def maneuver_review(nil, _callbacks), do: nil

  def maneuver_review(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_maneuver_review_report"),
      Map.get(candidate_refresh, "maneuver_review_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def schema_validation(candidate_refresh),
    do: schema_validation(candidate_refresh, default_callbacks())

  def schema_validation(nil, _callbacks), do: nil

  def schema_validation(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_schema_validation_report"),
      Map.get(candidate_refresh, "schema_validation_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def schema_validation_batch(candidate_refresh),
    do: schema_validation_batch(candidate_refresh, default_callbacks())

  def schema_validation_batch(nil, _callbacks), do: nil

  def schema_validation_batch(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_schema_validation_batch_report"),
      Map.get(candidate_refresh, "schema_validation_batch_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def model_acceptance(candidate_refresh),
    do: model_acceptance(candidate_refresh, default_callbacks())

  def model_acceptance(nil, _callbacks), do: nil

  def model_acceptance(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_model_acceptance_report"),
      Map.get(candidate_refresh, "model_acceptance_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def validation_safety_case(candidate_refresh),
    do: validation_safety_case(candidate_refresh, default_callbacks())

  def validation_safety_case(nil, _callbacks), do: nil

  def validation_safety_case(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_validation_safety_case_summary"),
      Map.get(candidate_refresh, "validation_safety_case_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def provider_counteroffer(candidate_refresh),
    do: provider_counteroffer(candidate_refresh, default_callbacks())

  def provider_counteroffer(nil, _callbacks), do: nil

  def provider_counteroffer(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_provider_counteroffer_report"),
      Map.get(candidate_refresh, "provider_counteroffer_report")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def provider_counteroffer_review(candidate_refresh),
    do: provider_counteroffer_review(candidate_refresh, default_callbacks())

  def provider_counteroffer_review(nil, _callbacks), do: nil

  def provider_counteroffer_review(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_provider_counteroffer_review_summary"),
      Map.get(candidate_refresh, "provider_counteroffer_review_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def provider_counteroffer_plan_impact(candidate_refresh),
    do: provider_counteroffer_plan_impact(candidate_refresh, default_callbacks())

  def provider_counteroffer_plan_impact(nil, _callbacks), do: nil

  def provider_counteroffer_plan_impact(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_provider_counteroffer_plan_impact_summary"),
      Map.get(candidate_refresh, "provider_counteroffer_plan_impact_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def provider_counteroffer_import_readiness(candidate_refresh),
    do: provider_counteroffer_import_readiness(candidate_refresh, default_callbacks())

  def provider_counteroffer_import_readiness(nil, _callbacks), do: nil

  def provider_counteroffer_import_readiness(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_provider_counteroffer_import_readiness_summary"),
      Map.get(candidate_refresh, "provider_counteroffer_import_readiness_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def resource_filter(candidate_refresh),
    do: resource_filter(candidate_refresh, default_callbacks())

  def resource_filter(nil, _callbacks), do: nil

  def resource_filter(%{} = candidate_refresh, callbacks),
    do: direct_report(candidate_refresh, "resource_filter_report", callbacks)

  def resource_filter_summary(candidate_refresh),
    do: resource_filter_summary(candidate_refresh, default_callbacks())

  def resource_filter_summary(nil, _callbacks), do: nil

  def resource_filter_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_resource_filter_summary"),
      Map.get(candidate_refresh, "resource_filter_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def resource_projection_flow_summary(candidate_refresh),
    do: resource_projection_flow_summary(candidate_refresh, default_callbacks())

  def resource_projection_flow_summary(nil, _callbacks), do: nil

  def resource_projection_flow_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_resource_projection_flow_summary"),
      Map.get(candidate_refresh, "resource_projection_flow_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def freshness(candidate_refresh), do: freshness(candidate_refresh, default_callbacks())

  def freshness(nil, _callbacks), do: nil

  def freshness(%{} = candidate_refresh, callbacks),
    do: direct_report(candidate_refresh, "freshness_report", callbacks)

  def operational_readiness(candidate_refresh),
    do: operational_readiness(candidate_refresh, default_callbacks())

  def operational_readiness(candidate_refresh, callbacks) do
    source_report(
      candidate_refresh,
      "source_operational_readiness_report",
      "operational_readiness_report",
      callbacks
    )
  end

  def operational_import_eligibility(candidate_refresh),
    do: operational_import_eligibility(candidate_refresh, default_callbacks())

  def operational_import_eligibility(nil, _callbacks), do: nil

  def operational_import_eligibility(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_operational_import_eligibility_summary"),
      Map.get(candidate_refresh, "operational_import_eligibility_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def operational_readiness_gate_summary(candidate_refresh),
    do: operational_readiness_gate_summary(candidate_refresh, default_callbacks())

  def operational_readiness_gate_summary(nil, _callbacks), do: nil

  def operational_readiness_gate_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_operational_readiness_gate_summary"),
      Map.get(candidate_refresh, "operational_readiness_gate_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def operational_execution_boundary_summary(candidate_refresh),
    do: operational_execution_boundary_summary(candidate_refresh, default_callbacks())

  def operational_execution_boundary_summary(nil, _callbacks), do: nil

  def operational_execution_boundary_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_operational_execution_boundary_summary"),
      Map.get(candidate_refresh, "operational_execution_boundary_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def operational_quality_gate_summary(candidate_refresh),
    do: operational_quality_gate_summary(candidate_refresh, default_callbacks())

  def operational_quality_gate_summary(nil, _callbacks), do: nil

  def operational_quality_gate_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_operational_quality_gate_summary"),
      Map.get(candidate_refresh, "operational_quality_gate_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def operational_quality_gate_unavailable_resource_summary(candidate_refresh),
    do:
      operational_quality_gate_unavailable_resource_summary(
        candidate_refresh,
        default_callbacks()
      )

  def operational_quality_gate_unavailable_resource_summary(nil, _callbacks), do: nil

  def operational_quality_gate_unavailable_resource_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_operational_quality_gate_unavailable_resource_summary"),
      Map.get(candidate_refresh, "operational_quality_gate_unavailable_resource_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def operational_quality_gate_operator_training_summary(candidate_refresh),
    do: operational_quality_gate_operator_training_summary(candidate_refresh, default_callbacks())

  def operational_quality_gate_operator_training_summary(nil, _callbacks), do: nil

  def operational_quality_gate_operator_training_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_operational_quality_gate_operator_training_summary"),
      Map.get(candidate_refresh, "operational_quality_gate_operator_training_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def operational_quality_gate_schema_validation_summary(candidate_refresh),
    do:
      operational_quality_gate_schema_validation_summary(
        candidate_refresh,
        default_callbacks()
      )

  def operational_quality_gate_schema_validation_summary(nil, _callbacks), do: nil

  def operational_quality_gate_schema_validation_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_operational_quality_gate_schema_validation_summary"),
      Map.get(candidate_refresh, "operational_quality_gate_schema_validation_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def operational_quality_gate_import_readiness_summary(candidate_refresh),
    do:
      operational_quality_gate_import_readiness_summary(
        candidate_refresh,
        default_callbacks()
      )

  def operational_quality_gate_import_readiness_summary(nil, _callbacks), do: nil

  def operational_quality_gate_import_readiness_summary(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, "source_operational_quality_gate_import_readiness_summary"),
      Map.get(candidate_refresh, "operational_quality_gate_import_readiness_summary")
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.find(&is_map/1)
    |> case do
      %{} = summary -> stringify_keys.(summary)
      _summary -> nil
    end
  end

  def quality_gate(candidate_refresh), do: quality_gate(candidate_refresh, default_callbacks())

  def quality_gate(candidate_refresh, callbacks) do
    source_report(
      candidate_refresh,
      "source_quality_gate_report",
      "quality_gate_report",
      callbacks
    )
  end

  def refresh_budget(candidate_refresh),
    do: refresh_budget(candidate_refresh, default_callbacks())

  def refresh_budget(nil, _callbacks), do: nil

  def refresh_budget(%{} = candidate_refresh, callbacks),
    do: direct_report(candidate_refresh, "refresh_budget_report", callbacks)

  def candidate_rejection_report(request),
    do: candidate_rejection_report(request, default_callbacks())

  def candidate_rejection_report(%{} = request, callbacks) do
    request
    |> candidate_rejection_reports(callbacks)
    |> List.first()
  end

  def candidate_rejection_reports(request),
    do: candidate_rejection_reports(request, default_callbacks())

  def candidate_rejection_reports(%{} = request, callbacks) do
    source_report_family_callbacks = Keyword.fetch!(callbacks, :source_report_family_callbacks)

    mission_state_reports =
      request
      |> Map.get(:mission_state)
      |> CandidateReviewSourceReports.candidate_rejection_reports(
        source_report_family_callbacks.()
      )
      |> Enum.map(fn {report, _source_path} -> report end)

    mission_state_reports ++
      candidate_refresh_rejection_reports(Map.get(request, :candidate_refresh), callbacks)
  end

  def candidate_refresh_rejection_reports(candidate_refresh),
    do: candidate_refresh_rejection_reports(candidate_refresh, default_callbacks())

  def candidate_refresh_rejection_reports(nil, _callbacks), do: []

  def candidate_refresh_rejection_reports(%{} = candidate_refresh, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    ["source_candidate_rejection_report", "candidate_rejection_report"]
    |> Enum.flat_map(fn field ->
      candidate_refresh
      |> Map.get(field)
      |> List.wrap()
    end)
    |> Enum.filter(&is_map/1)
    |> Enum.map(stringify_keys)
  end

  def rejected_candidate_ids(request), do: rejected_candidate_ids(request, default_callbacks())

  def rejected_candidate_ids(%{} = request, callbacks) do
    request
    |> candidate_rejection_reports(callbacks)
    |> candidate_rejection_rejected_candidate_ids(callbacks)
    |> MapSet.new()
  end

  def candidate_rejection_rejected_candidate_ids(reports),
    do: candidate_rejection_rejected_candidate_ids(reports, default_callbacks())

  def candidate_rejection_rejected_candidate_ids(reports, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    candidate_rejection_candidate_id =
      Keyword.fetch!(callbacks, :candidate_rejection_candidate_id)

    reports
    |> List.wrap()
    |> Enum.flat_map(fn report ->
      report
      |> stringify_keys.()
      |> Map.get("rows", [])
      |> List.wrap()
    end)
    |> Enum.map(stringify_keys)
    |> Enum.filter(&(Map.get(&1, "rejection_status", "rejected") == "rejected"))
    |> Enum.map(candidate_rejection_candidate_id)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def source_report(candidate_refresh, source_key, canonical_key),
    do: source_report(candidate_refresh, source_key, canonical_key, default_callbacks())

  def source_report(nil, _source_key, _canonical_key, _callbacks), do: nil

  def source_report(%{} = candidate_refresh, source_key, canonical_key, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    candidate_refresh = stringify_keys.(candidate_refresh)

    [
      Map.get(candidate_refresh, source_key),
      Map.get(candidate_refresh, canonical_key)
    ]
    |> Enum.find(&is_map/1)
    |> case do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  def refresh_warnings(candidate_refresh),
    do: refresh_warnings(candidate_refresh, default_callbacks())

  def refresh_warnings(nil, _callbacks), do: []

  def refresh_warnings(%{} = candidate_refresh, callbacks) do
    freshness_warnings =
      candidate_refresh
      |> freshness(callbacks)
      |> case do
        %{"status" => "stale"} ->
          [
            "candidate refresh freshness policy marked the snapshot, horizon, or state quality stale"
          ]

        %{"status" => "unknown"} ->
          ["candidate refresh freshness could not be fully evaluated"]

        _report ->
          []
      end

    source_warnings =
      candidate_refresh
      |> Map.get("warnings", [])
      |> List.wrap()
      |> Enum.filter(&is_binary/1)

    (freshness_warnings ++ source_warnings)
    |> Enum.uniq()
  end

  defp direct_report(%{} = candidate_refresh, field, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    case Map.get(candidate_refresh, field) do
      %{} = report -> stringify_keys.(report)
      _report -> nil
    end
  end

  defp default_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      source_report_family_callbacks: &source_report_family_callbacks/0,
      candidate_rejection_candidate_id: &CandidateRejectionPressureEvents.candidate_id/1
    ]
  end

  defp source_report_family_callbacks do
    [
      source_report_entries: &BranchRefreshSourceInputs.source_report_entries/2,
      source_artifact_entries: &BranchRefreshSourceInputs.source_artifact_entries/2,
      result_artifact_embedded_reports: &mission_state_result_artifact_embedded_reports/2,
      result_artifact_operational_readiness_gate_summaries:
        &mission_state_result_artifact_operational_readiness_gate_summaries/1
    ]
  end

  defp mission_state_result_artifact_embedded_reports(mission_state, report_key) do
    BranchRefreshSourceInputs.result_artifact_embedded_reports(
      mission_state,
      "mission_state",
      report_key
    )
  end

  defp mission_state_result_artifact_operational_readiness_gate_summaries(mission_state) do
    BranchRefreshSourceInputs.operational_readiness_gate_summaries_from_result_artifacts(
      mission_state,
      "mission_state"
    )
  end
end
