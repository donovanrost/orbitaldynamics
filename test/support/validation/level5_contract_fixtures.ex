defmodule OrbitalDynamics.Validation.Level5ContractFixtures do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.LocalSearchSupport
  alias OrbitalDynamics.{AuthorityContext, CandidateRefresh, Timeline, Validation}

  @generated_at ~U[2026-05-14 00:00:00Z]

  def authority_context_fixture_observations do
    Validation.artifact_observations("authority_context.v1", authority_context_fixture())
  end

  def authority_context_fixture do
    AuthorityContext.new!(%{
      "schema_contract" => "authority_context.v1",
      "authority_source" => "mission-operations-authority-registry",
      "source_revision" => "authority-revision-17",
      "effective_from" => "2026-05-14T00:00:00Z",
      "valid_until" => "2026-05-15T00:00:00Z",
      "evaluation_time" => "2026-05-14T12:00:00Z"
    })
  end

  def campaign_plan_search_trace_fixture_observations do
    Validation.artifact_observations(
      "campaign_plan_search_trace.v1",
      campaign_plan_search_trace_fixture()
    )
  end

  def campaign_plan_search_trace_fixture do
    LocalSearchSupport.result_set()
    |> OrbitalDynamics.campaign_plan_with_local_search(
      campaign: LocalSearchSupport.campaign(),
      generated_at: LocalSearchSupport.generated_at(),
      local_search: LocalSearchSupport.local_search()
    )
    |> Map.fetch!("optimizer_search_trace")
  end

  def local_search_optimization_certificate_fixture_observations do
    Validation.artifact_observations(
      "local_search_optimization_certificate.v1",
      local_search_optimization_certificate_fixture()
    )
  end

  def local_search_optimization_certificate_fixture do
    seed = %{"x" => 1, "y" => 0}

    candidate_ids = [
      "fixture_certificate:seed",
      "fixture_certificate:x:decrease",
      "fixture_certificate:x:increase",
      "fixture_certificate:y:increase"
    ]

    evidence =
      Map.new(candidate_ids, fn id ->
        {id,
         %{
           "id" => "source:#{id}",
           "revision" => "fixture-revision-1",
           "payload" => %{"candidate_id" => id, "quality" => "accepted"}
         }}
      end)

    evaluator = fn parameters, source_evidence ->
      eligible = parameters["x"] > 0

      %{
        "score_terms" => %{
          "parameter_value" => parameters["x"] + parameters["y"],
          "source_quality" =>
            if(source_evidence["payload"]["quality"] == "accepted", do: 0, else: -100)
        },
        "eligible" => eligible,
        "rejection_reasons" => if(eligible, do: [], else: ["x_must_be_positive"])
      }
    end

    case OrbitalDynamics.certified_local_search(seed, evidence, evaluator,
           steps: %{"x" => 1, "y" => 1},
           bounds: %{"x" => {0, 2}, "y" => {0, 2}},
           id_prefix: "fixture_certificate"
         ) do
      %{} = certificate -> certificate
      {:error, failure} -> raise "local-search certificate fixture failed: #{inspect(failure)}"
    end
  end

  def candidate_refresh_execution_fixture_observations do
    Validation.artifact_observations(
      "candidate_refresh_execution.v1",
      candidate_refresh_execution_fixture()
    )
  end

  def candidate_refresh_execution_fixture do
    case CandidateRefresh.run(candidate_refresh_request(), generated_at: @generated_at) do
      {:ok, artifact} -> Map.fetch!(artifact, "candidate_refresh_execution")
      {:error, reason} -> raise "candidate refresh execution fixture failed: #{inspect(reason)}"
    end
  end

  def downlink_link_budget_fixture_observations do
    Validation.artifact_observations("downlink_link_budget.v1", downlink_link_budget_fixture())
  end

  def downlink_link_budget_fixture do
    OrbitalDynamics.downlink_link_budget(downlink_contact(), downlink_parameters())
  end

  def resource_state_trace_fixture_observations do
    Validation.artifact_observations("resource_state_trace.v1", resource_state_trace_fixture())
  end

  def resource_state_trace_fixture do
    OrbitalDynamics.resource_state_trace(
      [
        %{
          id: "limit_crossing",
          type: "observe",
          spacecraft_id: "sc_1",
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          resource_effects: %{
            energy_consumed_wh: 25.0,
            data_stored_mb: 30.0,
            assumptions: %{effect_basis: :declared_activity_profile},
            provenance: %{source_revision: "payload-profile-r3"}
          }
        }
      ],
      %{
        spacecraft_id: "sc_1",
        battery_capacity_wh: 100.0,
        battery_energy_used_wh: 90.0,
        storage_capacity_mb: 100.0,
        storage_used_mb: 90.0,
        assumptions: %{initial_state: :operator_declared},
        provenance: %{
          source_quality: :operator_supplied,
          trust_boundary: :operator_declared
        }
      },
      as_of_s: 5.0,
      source: "selected_timeline_revision:7",
      provenance: %{timeline_revision: 7}
    )
  end

  def timeline_revision_fixture_observations do
    Validation.artifact_observations("timeline_revision.v1", timeline_revision_fixture())
  end

  def timeline_revision_fixture do
    {source, replacement} = timeline_pair()

    source
    |> Timeline.transition_application_report(replacement,
      source: "validation_reference_fixture",
      timeline_revision?: true
    )
    |> Map.fetch!("timeline_revision")
  end

  defp candidate_refresh_request do
    %{
      "accepted_planning_state" => %{
        "schema_version" => 1,
        "schema_contract" => "accepted_planning_state.v1",
        "artifact_type" => "accepted_planning_state",
        "snapshot_id" => "snapshot_a",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [
          %{
            "spacecraft_id" => "sat_a",
            "scenario_id" => "scenario_a",
            "epoch" => %{"seconds_since_j2000" => 0.0, "time_scale" => "tdb"},
            "frame" => "earth_inertial_j2000",
            "state_vector" => %{
              "position_km" => [7_000.0, 0.0, 0.0],
              "velocity_km_s" => [0.0, 7.5, 0.0]
            },
            "source" => %{"system" => "operator_import", "source_id" => "state_a"},
            "provenance" => %{"trust_boundary" => "operator_supplied"},
            "quality" => %{"level" => "accepted"}
          }
        ],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "cadence_snapshot", "source_id" => "snapshot_a"},
        "quality" => %{"level" => "planning_accepted"},
        "provenance" => %{"created_by" => "validation_reference_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 10.0
      },
      "spacecraft" => %{
        "spacecraft_id" => "sat_a",
        "scenario_id" => "scenario_a",
        "dry_mass_kg" => 100.0,
        "propellant_mass_kg" => 5.0,
        "drag_area_m2" => 2.0,
        "drag_coefficient" => 2.2
      },
      "ground_station" => %{
        "ground_station_id" => "station_a",
        "latitude_deg" => 0.0,
        "longitude_deg" => 0.0,
        "altitude_km" => 0.0,
        "minimum_elevation_deg" => 5.0
      },
      "constraints" => %{"avoid_eclipse" => true},
      "scoring_policy" => %{
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{}
    }
  end

  defp downlink_contact do
    %{
      id: "dl_1",
      type: "downlink",
      spacecraft_id: "sc_1",
      ground_station_id: "gs_1",
      direction: "downlink",
      mode: "fixed_single_carrier",
      starts_at_s: 100.0,
      ends_at_s: 220.0,
      source_window_id: "access_1",
      source_window_revision: "window-r7"
    }
  end

  defp downlink_parameters do
    %{
      source: "mission_rf_configuration",
      source_revision: "rf-config-r4",
      access_window: %{
        id: "access_1",
        revision: "window-r7",
        spacecraft_id: "sc_1",
        ground_station_id: "gs_1",
        starts_at_s: 90.0,
        ends_at_s: 230.0,
        source: "access_windows.v1",
        source_revision: "trajectory-r12"
      },
      geometry: %{
        slant_range: %{value: 1_000.0, unit: "km"},
        elevation: %{value: 30.0, unit: "deg"},
        sample_at: %{value: 160.0, unit: "s"}
      },
      spacecraft_terminal: %{
        id: "sc_terminal_1",
        spacecraft_id: "sc_1",
        source: "spacecraft_terminal_catalog",
        revision: "sc-terminal-r3",
        direction: "downlink",
        mode: "fixed_single_carrier",
        carrier_frequency: %{value: 2.2e9, unit: "Hz"},
        transmit_power: %{value: 20.0, unit: "W"},
        transmit_antenna_gain: %{value: 5.0, unit: "dBi"}
      },
      ground_terminal: %{
        id: "gs_terminal_1",
        ground_station_id: "gs_1",
        source: "ground_terminal_catalog",
        revision: "gs-terminal-r9",
        direction: "downlink",
        mode: "fixed_single_carrier",
        carrier_frequency: %{value: 2.2e9, unit: "Hz"},
        receive_antenna_gain: %{value: 35.0, unit: "dBi"},
        system_noise_temperature: %{value: 500.0, unit: "K"}
      },
      rf_link: %{
        direction: "downlink",
        mode: "fixed_single_carrier",
        carrier_frequency: %{value: 2.2e9, unit: "Hz"},
        occupied_bandwidth: %{value: 1.0e6, unit: "Hz"},
        explicit_losses: %{value: 3.0, unit: "dB"},
        coding_efficiency: %{value: 0.5, unit: "ratio"},
        modulation_efficiency: %{value: 1.0, unit: "bit/s/Hz"}
      },
      margin_policy: %{
        minimum_elevation: %{value: 10.0, unit: "deg"},
        required_eb_n0: %{value: 3.0, unit: "dB"},
        required_margin: %{value: 2.0, unit: "dB"}
      }
    }
  end

  defp timeline_pair do
    unchanged = %{
      id: :obs_keep,
      type: :observe,
      target_id: :target_a,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      metadata: %{timeline_id: :"timeline:obs_keep"}
    }

    changed_source = %{
      id: :cmd_change,
      type: :command,
      status: :planned,
      starts_at_s: 50.0,
      ends_at_s: 60.0,
      metadata: %{timeline_id: :"timeline:cmd_change"}
    }

    changed_replacement = %{
      id: :cmd_change,
      type: :command,
      status: :planned,
      starts_at_s: 52.0,
      ends_at_s: 62.0,
      metadata: %{timeline_id: :"timeline:cmd_change"}
    }

    added = %{
      id: :new_contact,
      type: :planned_contact,
      ground_station_id: :dss_14,
      starts_at_s: 70.0,
      ends_at_s: 80.0,
      metadata: %{timeline_id: :"timeline:new_contact"}
    }

    {[unchanged, changed_source], [unchanged, changed_replacement, added]}
  end
end
