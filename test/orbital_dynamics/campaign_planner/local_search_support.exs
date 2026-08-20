defmodule OrbitalDynamics.CampaignPlanner.LocalSearchSupport do
  alias OrbitalDynamics.{Epoch, ResultSet}
  alias OrbitalDynamics.Optimizer.SourceEvidenceRegistry
  alias OrbitalDynamics.Search.Local

  def campaign do
    %{
      "targets" => [%{"id" => "target_a", "priority" => 1.0}],
      "constraints" => %{"max_timeline_activities" => 1},
      "scoring_policy" => %{
        "target_value_weight" => 1.0,
        "contact_value_weight" => 0.1,
        "rank_limit" => 1,
        "contact_activity_types" => ["downlink"]
      }
    }
  end

  def result_set(order \\ :forward) do
    events = [
      target_visibility_result(:leo_2, :target_a, 20.0, 80.0),
      target_visibility_result(:leo_1, :target_a, 10.0, 110.0)
    ]

    events = if order == :reverse, do: Enum.reverse(events), else: events

    ResultSet.new!(%{
      study_id: :campaign_local_search,
      trajectory_results: [],
      event_results: events,
      errors: [],
      assumptions: %{},
      metadata: %{}
    })
  end

  def generated_at, do: ~U[2026-08-20 12:00:00Z]

  def local_search(overrides \\ %{}) do
    base = %{
      "steps" => %{"target_value_weight" => 1.0},
      "bounds" => %{"target_value_weight" => [0.0, 2.0]},
      "id_prefix" => "campaign_policy",
      "max_alternatives" => 3,
      "hard_feasibility" => hard_feasibility()
    }

    Map.merge(base, overrides)
  end

  def hard_feasibility(opts \\ []) do
    alternatives = Keyword.get(opts, :alternatives, alternatives())
    all_infeasible? = Keyword.get(opts, :all_infeasible?, false)
    higher_score_infeasible? = Keyword.get(opts, :higher_score_infeasible?, true)

    {candidates, entries} =
      alternatives
      |> Enum.map(fn alternative ->
        trace = resource_trace(alternative)
        budget = downlink_budget(alternative)

        required_volume_mb =
          cond do
            all_infeasible? -> 10.0
            higher_score_infeasible? and String.ends_with?(alternative["id"], ":increase") -> 10.0
            true -> 5.0
          end

        candidate = %{
          "alternative_id" => alternative["id"],
          "resource_state_trace" => trace,
          "resource_threshold" => %{
            "metric" => "minimum_battery_state_of_charge",
            "operator" => "greater_than_or_equal",
            "threshold" => 0.5
          },
          "downlink_link_budget" => budget,
          "downlink_threshold" => %{
            "metric" => "completion_fraction",
            "operator" => "greater_than_or_equal",
            "threshold" => 1.0,
            "required_volume_mb" => required_volume_mb
          }
        }

        entry =
          SourceEvidenceRegistry.entry(
            alternative["id"],
            "campaign-policy-r1",
            alternative["parameters"],
            trace["id"],
            budget["id"]
          )

        {candidate, entry}
      end)
      |> Enum.unzip()

    %{
      "mode" => "hard",
      "evidence_registry" => entries |> Map.new() |> SourceEvidenceRegistry.build(),
      "candidates" => candidates
    }
  end

  def alternatives(opts \\ []) do
    seed =
      campaign()["scoring_policy"]
      |> Map.take(OrbitalDynamics.CampaignPlanner.LocalSearchSelection.numeric_policy_keys())

    defaults = [
      steps: %{"target_value_weight" => 1.0},
      bounds: %{"target_value_weight" => {0.0, 2.0}},
      id_prefix: "campaign_policy",
      max_alternatives: 3
    ]

    Local.neighborhood(seed, Keyword.merge(defaults, opts))["alternatives"]
  end

  def update_candidate(config, id, update) do
    Map.update!(config, "candidates", fn candidates ->
      Enum.map(candidates, fn candidate ->
        if candidate["alternative_id"] == id, do: update.(candidate), else: candidate
      end)
    end)
  end

  def rebuild_registry(config, update_entries) do
    entries = config["evidence_registry"]["entries"] |> update_entries.()
    Map.put(config, "evidence_registry", SourceEvidenceRegistry.build(entries))
  end

  def candidate(config, id),
    do: Enum.find(config["candidates"], &(&1["alternative_id"] == id))

  defp target_visibility_result(scenario_id, target_id, starts_at_s, ends_at_s) do
    %{
      scenario_id: scenario_id,
      event_type: :target_visibility,
      events: [
        %{
          type: :target_visibility,
          starts_at: Epoch.new!(starts_at_s, :tdb),
          ends_at: Epoch.new!(ends_at_s, :tdb),
          metadata: %{
            target_id: target_id,
            target_priority: 1.0,
            max_elevation_deg: 60.0,
            minimum_elevation_deg: 10.0
          }
        }
      ],
      source: %{target_id: target_id}
    }
  end

  defp resource_trace(alternative) do
    OrbitalDynamics.resource_state_trace([], initial_resource_summary(),
      provenance: %{
        resource_state_trace_revision: "trace-r1:#{alternative["generation_index"]}"
      }
    )
  end

  defp initial_resource_summary do
    %{
      spacecraft_id: "sc_1",
      battery_capacity_wh: 100.0,
      battery_energy_used_wh: 20.0,
      storage_capacity_mb: 100.0,
      storage_used_mb: 40.0,
      assumptions: %{initial_state: :operator_declared},
      provenance: %{
        source_quality: :operator_supplied,
        trust_boundary: :operator_declared
      }
    }
  end

  defp downlink_budget(alternative) do
    index = alternative["generation_index"]

    OrbitalDynamics.downlink_link_budget(
      %{
        id: "dl_#{index}",
        type: "downlink",
        spacecraft_id: "sc_1",
        ground_station_id: "gs_1",
        direction: "downlink",
        mode: "fixed_single_carrier",
        starts_at_s: 100.0,
        ends_at_s: 220.0,
        source_window_id: "access_1",
        source_window_revision: "window-r7"
      },
      downlink_parameters("rf-config-r4:#{index}")
    )
  end

  defp downlink_parameters(source_revision) do
    %{
      source: "mission_rf_configuration",
      source_revision: source_revision,
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
end
