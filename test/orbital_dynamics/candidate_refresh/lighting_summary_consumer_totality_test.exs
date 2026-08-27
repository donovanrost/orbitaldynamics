defmodule OrbitalDynamics.CandidateRefresh.LightingSummaryConsumerTotalityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityCandidate,
    ActivityIdentity,
    ScalarValues,
    ValueEncoding
  }

  alias OrbitalDynamics.CandidateRefresh.ObservationCandidate
  alias OrbitalDynamics.{CampaignPlanner, CandidateRefresh, Epoch, ResultSet}

  defmodule StructProbe do
    defstruct [:value]
  end

  @event_limit 10_000
  @safe_number_bound 1_000_000_000_000_000
  @generated_at ~U[2026-05-14 00:00:00Z]

  test "CandidateRefresh public build rejects invalid observation lighting before emission" do
    for {label, event_results} <- invalid_lighting_event_results() do
      artifact =
        event_results
        |> result_set()
        |> CandidateRefresh.build(
          candidate_refresh: refresh_request(invalid_lighting_constraints()),
          generated_at: @generated_at
        )

      assert observation_entries(artifact, "candidate_activities") == [],
             "#{label} emitted a CandidateRefresh observation"

      assert error_tuple_entries(artifact, "candidate_activities") == [],
             "#{label} leaked a CandidateRefresh error tuple"

      refute invalid_refreshed_eclipse_interval?(artifact),
             "#{label} leaked an invalid refreshed eclipse interval"

      refute encoded_tuple_probe?(artifact),
             "#{label} leaked tuple-shaped metadata through CandidateRefresh encoding"
    end
  end

  test "CampaignPlanner public build rejects invalid observation lighting before emission" do
    for {label, event_results} <- invalid_lighting_event_results() do
      artifact =
        event_results
        |> result_set()
        |> CampaignPlanner.build(
          campaign: campaign(invalid_lighting_constraints()),
          generated_at: @generated_at
        )

      assert observation_entries(artifact, "candidate_activities") == [],
             "#{label} emitted a CampaignPlanner candidate observation"

      assert observation_entries(artifact, "activities") == [],
             "#{label} emitted a selected CampaignPlanner observation"

      assert error_tuple_entries(artifact, "candidate_activities") == [],
             "#{label} leaked a CampaignPlanner candidate error tuple"

      assert error_tuple_entries(artifact, "activities") == [],
             "#{label} leaked a CampaignPlanner selected error tuple"

      refute encoded_tuple_probe?(artifact),
             "#{label} leaked tuple-shaped metadata through CampaignPlanner encoding"
    end
  end

  test "invalid observation lighting remains scenario local when identity is admitted" do
    event_results = [
      target_visibility_result(
        [unsupported_metadata_event(target_visibility_event(120.0, 180.0))],
        :leo_bad
      ),
      target_visibility_result(
        [target_visibility_event(120.0, 180.0, :target_b)],
        :leo_1,
        :target_b
      )
    ]

    refresh_artifact =
      event_results
      |> result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh_request(valid_constraints()),
        generated_at: @generated_at
      )

    campaign_artifact =
      event_results
      |> result_set()
      |> CampaignPlanner.build(
        campaign: campaign(valid_constraints()),
        generated_at: @generated_at
      )

    assert [%{"scenario_id" => "leo_1", "target_id" => "target_b"}] =
             scoreable_observations(refresh_artifact, "candidate_activities")

    assert [%{"scenario_id" => "leo_1", "target_id" => "target_b"}] =
             scoreable_observations(campaign_artifact, "candidate_activities")

    refute Enum.any?(
             observation_entries(refresh_artifact, "candidate_activities"),
             &match?(%{"scenario_id" => "leo_bad"}, &1)
           )

    refute Enum.any?(
             observation_entries(campaign_artifact, "candidate_activities"),
             &match?(%{"scenario_id" => "leo_bad"}, &1)
           )
  end

  test "unscoped invalid observation lighting suppresses observations but preserves downlinks" do
    event_results = [
      improper_scenario_result(
        target_visibility_result([target_visibility_event(120.0, 180.0)], :leo_bad)
      ),
      target_visibility_result([target_visibility_event(120.0, 180.0)], :leo_1),
      ground_station_access_result([ground_station_access_event(130.0, 190.0)], :leo_1)
    ]

    refresh_artifact =
      event_results
      |> result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh_request(valid_constraints()),
        generated_at: @generated_at
      )

    campaign_artifact =
      event_results
      |> result_set()
      |> CampaignPlanner.build(
        campaign: campaign(valid_constraints()),
        generated_at: @generated_at
      )

    assert observation_entries(refresh_artifact, "candidate_activities") == []
    assert observation_entries(campaign_artifact, "candidate_activities") == []
    assert observation_entries(campaign_artifact, "activities") == []

    assert [%{"type" => "downlink", "scenario_id" => "leo_1"}] =
             downlink_entries(refresh_artifact, "candidate_activities")

    assert [%{"type" => "downlink", "scenario_id" => "leo_1"}] =
             downlink_entries(campaign_artifact, "candidate_activities")

    assert [%{"type" => "ground_station_access", "scenario_id" => "leo_1"}] =
             Map.get(refresh_artifact, "refreshed_windows") |> Map.get("access_windows")
  end

  test "public build rejects arbitrary structs nested in admitted metadata routes before encoding" do
    for {label, event_results} <- struct_metadata_route_event_results() do
      refresh_artifact =
        event_results
        |> result_set()
        |> CandidateRefresh.build(
          candidate_refresh: refresh_request(valid_constraints()),
          generated_at: @generated_at
        )

      campaign_artifact =
        event_results
        |> result_set()
        |> CampaignPlanner.build(
          campaign: campaign(valid_constraints()),
          generated_at: @generated_at
        )

      assert scoreable_observations(refresh_artifact, "candidate_activities") == [],
             "#{label} emitted a CandidateRefresh observation"

      assert scoreable_observations(campaign_artifact, "candidate_activities") == [],
             "#{label} emitted a CampaignPlanner observation"

      assert downlink_entries(refresh_artifact, "candidate_activities") == [],
             "#{label} emitted a CandidateRefresh downlink"

      assert downlink_entries(campaign_artifact, "candidate_activities") == [],
             "#{label} emitted a CampaignPlanner downlink"

      refute invalid_refreshed_eclipse_interval?(refresh_artifact),
             "#{label} leaked malformed refreshed eclipse interval"
    end
  end

  test "public observation builders return exact typed invalid lighting errors" do
    for {label, result, event, eclipse_intervals, overlap_duration, expected_reason} <-
          direct_invalid_observation_inputs() do
      expected = {:error, {:invalid_observation_lighting, expected_reason}}

      assert expected ==
               ObservationCandidate.build(
                 result,
                 {event, 1},
                 refresh_request(valid_constraints()),
                 eclipse_intervals,
                 scoring_policy(),
                 fn _input -> %{} end,
                 fn _value -> nil end,
                 fn _refresh -> [] end
               ),
             "#{label} returned the wrong CandidateRefresh builder contract"

      assert expected ==
               ActivityCandidate.observe(
                 result,
                 {event, 1},
                 campaign(valid_constraints()),
                 eclipse_intervals,
                 scoring_policy(),
                 direct_observe_callbacks(overlap_duration)
               ),
             "#{label} returned the wrong CampaignPlanner observe contract"
    end
  end

  test "public observation builders enforce numeric metadata safe bounds" do
    for field <- target_numeric_metadata_keys() do
      result =
        target_visibility_result([
          numeric_metadata_event(
            target_visibility_event(120.0, 180.0),
            field,
            @safe_number_bound + 1
          )
        ])

      event =
        numeric_metadata_event(
          target_visibility_event(120.0, 180.0),
          field,
          @safe_number_bound + 1
        )

      expected = {:error, {:invalid_observation_lighting, {:invalid_option, :metadata}}}

      assert expected ==
               ObservationCandidate.build(
                 result,
                 {event, 1},
                 refresh_request(valid_constraints()),
                 [],
                 scoring_policy(),
                 fn _input -> %{} end,
                 fn _value -> nil end,
                 fn _refresh -> [] end
               ),
             "#{field} bound+1 was admitted by CandidateRefresh observation build"

      assert expected ==
               ActivityCandidate.observe(
                 result,
                 {event, 1},
                 campaign(valid_constraints()),
                 [],
                 scoring_policy(),
                 direct_observe_callbacks(zero_overlap_duration())
               ),
             "#{field} bound+1 was admitted by CampaignPlanner observation build"

      result =
        target_visibility_result([
          numeric_metadata_event(target_visibility_event(120.0, 180.0), field, huge_integer())
        ])

      event = numeric_metadata_event(target_visibility_event(120.0, 180.0), field, huge_integer())

      assert expected ==
               ObservationCandidate.build(
                 result,
                 {event, 1},
                 refresh_request(valid_constraints()),
                 [],
                 scoring_policy(),
                 fn _input -> %{} end,
                 fn _value -> nil end,
                 fn _refresh -> [] end
               ),
             "#{field} huge integer was admitted by CandidateRefresh observation build"

      assert expected ==
               ActivityCandidate.observe(
                 result,
                 {event, 1},
                 campaign(valid_constraints()),
                 [],
                 scoring_policy(),
                 direct_observe_callbacks(zero_overlap_duration())
               ),
             "#{field} huge integer was admitted by CampaignPlanner observation build"
    end

    result =
      target_visibility_result([
        numeric_metadata_event(
          target_visibility_event(120.0, 180.0),
          :sample_count,
          @safe_number_bound
        )
      ])

    event =
      numeric_metadata_event(
        target_visibility_event(120.0, 180.0),
        :sample_count,
        @safe_number_bound
      )

    assert %{"type" => "observe"} =
             ObservationCandidate.build(
               result,
               {event, 1},
               refresh_request(valid_constraints()),
               [],
               scoring_policy(),
               fn _input -> %{} end,
               fn _value -> nil end,
               fn _refresh -> [] end
             )

    assert %{"type" => "observe"} =
             ActivityCandidate.observe(
               result,
               {event, 1},
               campaign(valid_constraints()),
               [],
               scoring_policy(),
               direct_observe_callbacks(zero_overlap_duration())
             )
  end

  test "CampaignPlanner observation overlap callback unexpected returns remain visible" do
    result = target_visibility_result([target_visibility_event(120.0, 180.0)])
    event = target_visibility_event(120.0, 180.0)

    for {_label, unexpected, exception} <- unexpected_overlap_callback_returns() do
      callbacks = campaign_activity_callbacks(fn _interval, _intervals -> unexpected end)

      assert_raise exception, fn ->
        ActivityCandidate.observe(
          result,
          {event, 1},
          campaign(valid_constraints()),
          [],
          scoring_policy(),
          callbacks
        )
      end

      assert_raise exception, fn ->
        ActivityCandidate.build(
          valid_event_results(),
          campaign(valid_constraints()),
          valid_constraints(),
          scoring_policy(),
          callbacks
        )
      end
    end
  end

  test "CampaignPlanner overlap callback documented domain outcomes remain suppressible" do
    result = target_visibility_result([target_visibility_event(120.0, 180.0)])
    event = target_visibility_event(120.0, 180.0)

    for {label, overlap_duration, expected_reason} <- expected_overlap_callback_domain_errors() do
      callbacks = campaign_activity_callbacks(overlap_duration)
      expected = {:error, {:invalid_observation_lighting, expected_reason}}

      assert expected ==
               ActivityCandidate.observe(
                 result,
                 {event, 1},
                 campaign(valid_constraints()),
                 [],
                 scoring_policy(),
                 callbacks
               ),
             "#{label} did not retain the observe typed contract"

      assert [] ==
               ActivityCandidate.build(
                 valid_event_results(),
                 campaign(valid_constraints()),
                 valid_constraints(),
                 scoring_policy(),
                 callbacks
               ),
             "#{label} did not retain the build suppression contract"
    end
  end

  test "consumer lighting summary wrappers do not suppress unexpected helper shapes" do
    for path <- [
          "lib/orbital_dynamics/candidate_refresh/observation_candidate.ex",
          "lib/orbital_dynamics/campaign_planner/activity_candidate.ex"
        ] do
      source = File.read!(path)
      wrapper = lighting_summary_wrapper(source)

      refute wrapper =~ "_other -> {:error, {:invalid_return, :lighting_summary}}"
      refute wrapper =~ "{:error, reason} -> {:error, reason}"
      assert wrapper =~ "when field in [:duration_s, :eclipse_overlap_s]"
    end
  end

  test "CandidateRefresh public build preserves valid finite observation lighting shape" do
    artifact =
      valid_event_results()
      |> result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh_request(valid_constraints()),
        generated_at: @generated_at
      )

    assert [candidate] = scoreable_observations(artifact, "candidate_activities")
    assert common_observation_projection(candidate) == valid_observation_projection()
  end

  test "CampaignPlanner public build preserves valid finite observation lighting shape" do
    artifact =
      valid_event_results()
      |> result_set()
      |> CampaignPlanner.build(
        campaign: campaign(valid_constraints()),
        generated_at: @generated_at
      )

    assert [candidate] = scoreable_observations(artifact, "candidate_activities")
    assert common_observation_projection(candidate) == valid_observation_projection()
  end

  test "valid non-observation event results are preserved" do
    event_results = [
      target_visibility_result([target_visibility_event(120.0, 180.0)]),
      ground_station_access_result([ground_station_access_event(130.0, 190.0)])
    ]

    refresh_artifact =
      event_results
      |> result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh_request(valid_constraints()),
        generated_at: @generated_at
      )

    campaign_artifact =
      event_results
      |> result_set()
      |> CampaignPlanner.build(
        campaign: campaign(valid_constraints()),
        generated_at: @generated_at
      )

    assert [%{"type" => "observe"}] =
             scoreable_observations(refresh_artifact, "candidate_activities")

    assert [%{"type" => "downlink"}] = downlink_entries(refresh_artifact, "candidate_activities")

    assert [%{"type" => "observe"}] =
             scoreable_observations(campaign_artifact, "candidate_activities")

    assert [%{"type" => "downlink"}] = downlink_entries(campaign_artifact, "candidate_activities")
  end

  test "malformed unrelated event results do not invalidate valid observations" do
    event_results = [
      target_visibility_result([target_visibility_event(120.0, 180.0)]),
      malformed_unrelated_result()
    ]

    refresh_artifact =
      event_results
      |> result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh_request(valid_constraints()),
        generated_at: @generated_at
      )

    campaign_artifact =
      event_results
      |> result_set()
      |> CampaignPlanner.build(
        campaign: campaign(valid_constraints()),
        generated_at: @generated_at
      )

    assert [%{"type" => "observe"}] =
             scoreable_observations(refresh_artifact, "candidate_activities")

    assert [%{"type" => "observe"}] =
             scoreable_observations(campaign_artifact, "candidate_activities")
  end

  defp invalid_lighting_event_results do
    [
      {"negative target duration",
       [
         target_visibility_result([target_visibility_event(240.0, 120.0)])
       ]},
      {"unsafe target start",
       [
         target_visibility_result([target_visibility_event(:infinity, 180.0)])
       ]},
      {"unsafe target end",
       [
         target_visibility_result([target_visibility_event(120.0, :infinity)])
       ]},
      {"overflow target duration",
       [
         target_visibility_result([target_visibility_event(-1.0e15, 1.0e15)])
       ]},
      {"malformed target event",
       [
         target_visibility_result([Map.delete(target_visibility_event(120.0, 180.0), :ends_at)])
       ]},
      {"forged target epoch struct",
       [
         target_visibility_result([
           %{target_visibility_event(120.0, 180.0) | starts_at: forged_epoch(120.0)}
         ])
       ]},
      {"wrong target epoch struct",
       [
         target_visibility_result([
           %{target_visibility_event(120.0, 180.0) | starts_at: %StructProbe{value: :epoch}}
         ])
       ]},
      {"bogus target epoch scale",
       [
         target_visibility_result([
           %{target_visibility_event(120.0, 180.0) | starts_at: bogus_scale_epoch(120.0)}
         ])
       ]},
      {"wide target result map",
       [
         wide_result(target_visibility_result([target_visibility_event(120.0, 180.0)]))
       ]},
      {"deep target result map",
       [
         deep_result(target_visibility_result([target_visibility_event(120.0, 180.0)]))
       ]},
      {"wide target source map",
       [
         wide_source_result(target_visibility_result([target_visibility_event(120.0, 180.0)]))
       ]},
      {"deep target source map",
       [
         deep_target_source_result(
           target_visibility_result([target_visibility_event(120.0, 180.0)])
         )
       ]},
      {"struct target source map",
       [
         struct_target_source_result(
           target_visibility_result([target_visibility_event(120.0, 180.0)])
         )
       ]},
      {"wide target metadata map",
       [
         target_visibility_result([wide_metadata_event(target_visibility_event(120.0, 180.0))])
       ]},
      {"deep target metadata map",
       [
         target_visibility_result([deep_metadata_event(target_visibility_event(120.0, 180.0))])
       ]},
      {"unsupported target metadata key",
       [
         target_visibility_result([
           unsupported_metadata_event(target_visibility_event(120.0, 180.0))
         ])
       ]},
      {"unsupported target event key type",
       [
         target_visibility_result([
           unsupported_event_key_event(target_visibility_event(120.0, 180.0))
         ])
       ]},
      {"target metadata atom string collision",
       [
         target_visibility_result([
           metadata_collision_event(target_visibility_event(120.0, 180.0))
         ])
       ]},
      {"target boundary detail tuple",
       [
         target_visibility_result([
           tuple_metadata_event(
             target_visibility_event(120.0, 180.0),
             :start_boundary_detail,
             {:caller, :tuple}
           )
         ])
       ]},
      {"target json metadata tuple",
       [
         target_visibility_result([
           tuple_metadata_event(
             target_visibility_event(120.0, 180.0),
             :activity_context,
             {1.0, 2.0, 3.0}
           )
         ])
       ]},
      {"target numeric metadata bound plus one",
       [
         target_visibility_result([
           numeric_metadata_event(
             target_visibility_event(120.0, 180.0),
             :sample_count,
             @safe_number_bound + 1
           )
         ])
       ]},
      {"target numeric metadata huge integer",
       [
         target_visibility_result([
           numeric_metadata_event(
             target_visibility_event(120.0, 180.0),
             :sample_count,
             huge_integer()
           )
         ])
       ]},
      {"target result atom string collision",
       [
         result_collision(target_visibility_result([target_visibility_event(120.0, 180.0)]))
       ]},
      {"improper target scenario id",
       [
         improper_scenario_result(
           target_visibility_result([target_visibility_event(120.0, 180.0)])
         )
       ]},
      {"deep target scenario id",
       [
         deep_scenario_result(target_visibility_result([target_visibility_event(120.0, 180.0)]))
       ]},
      {"oversized target scenario id",
       [
         oversized_scenario_result(
           target_visibility_result([target_visibility_event(120.0, 180.0)])
         )
       ]},
      {"improper target events",
       [
         %{target_visibility_result([]) | events: [target_visibility_event(120.0, 180.0) | :tail]}
       ]},
      {"oversized target events",
       [
         target_visibility_result(
           List.duplicate(target_visibility_event(120.0, 180.0), @event_limit + 1)
         )
       ]},
      {"unsafe eclipse interval start",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([eclipse_event(:infinity, 180.0)])
       ]},
      {"unsafe eclipse interval end",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([eclipse_event(120.0, :infinity)])
       ]},
      {"overflow eclipse interval duration",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([eclipse_event(-1.0e15, 1.0e15)])
       ]},
      {"malformed eclipse event",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([Map.delete(eclipse_event(120.0, 180.0), :ends_at)])
       ]},
      {"forged eclipse epoch struct",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([%{eclipse_event(120.0, 180.0) | starts_at: forged_epoch(120.0)}])
       ]},
      {"wrong eclipse epoch struct",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([%{eclipse_event(120.0, 180.0) | starts_at: %StructProbe{value: :epoch}}])
       ]},
      {"bogus eclipse epoch scale",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([%{eclipse_event(120.0, 180.0) | starts_at: bogus_scale_epoch(120.0)}])
       ]},
      {"wide eclipse source map",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         wide_source_result(eclipse_result([eclipse_event(120.0, 180.0)]))
       ]},
      {"deep eclipse source map",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         deep_eclipse_source_result(eclipse_result([eclipse_event(120.0, 180.0)]))
       ]},
      {"wide eclipse metadata map",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([wide_metadata_event(eclipse_event(120.0, 180.0))])
       ]},
      {"deep eclipse metadata map",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([deep_eclipse_metadata_event(eclipse_event(120.0, 180.0))])
       ]},
      {"eclipse malformed sun direction tuple",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([
           tuple_metadata_event(eclipse_event(120.0, 180.0), :sun_direction, {:caller, :tuple})
         ])
       ]},
      {"eclipse unsafe sun direction bound plus one",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([
           tuple_metadata_event(
             eclipse_event(120.0, 180.0),
             :sun_direction,
             {@safe_number_bound + 1, 0.0, 0.0}
           )
         ])
       ]},
      {"eclipse unsafe sun direction huge integer",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([
           tuple_metadata_event(
             eclipse_event(120.0, 180.0),
             :sun_direction,
             {huge_integer(), 0.0, 0.0}
           )
         ])
       ]},
      {"eclipse boundary vector malformed tuple",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([
           tuple_metadata_event(
             eclipse_event(120.0, 180.0),
             :start_boundary_detail,
             %{sun_direction: {:caller, :tuple}}
           )
         ])
       ]},
      {"unsupported eclipse event key type",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([unsupported_event_key_event(eclipse_event(120.0, 180.0))])
       ]},
      {"eclipse result atom string collision",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         result_collision(eclipse_result([eclipse_event(120.0, 180.0)]))
       ]},
      {"improper eclipse scenario id",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         improper_scenario_result(eclipse_result([eclipse_event(120.0, 180.0)]))
       ]},
      {"deep eclipse scenario id",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         deep_scenario_result(eclipse_result([eclipse_event(120.0, 180.0)]))
       ]},
      {"oversized eclipse scenario id",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         oversized_scenario_result(eclipse_result([eclipse_event(120.0, 180.0)]))
       ]},
      {"improper eclipse events",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         %{eclipse_result([]) | events: [eclipse_event(120.0, 180.0) | :tail]}
       ]},
      {"oversized eclipse events",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result(List.duplicate(eclipse_event(120.0, 121.0), @event_limit + 1))
       ]},
      {"overlap exceeds duration",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([eclipse_event(120.0, 180.0), eclipse_event(120.0, 180.0)])
       ]},
      {"negative eclipse interval duration",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([eclipse_event(180.0, 120.0)])
       ]}
    ]
  end

  defp direct_invalid_observation_inputs do
    [
      {"negative target duration",
       target_visibility_result([target_visibility_event(240.0, 120.0)]),
       target_visibility_event(240.0, 120.0), [], zero_overlap_duration(),
       {:invalid_timing, :negative_duration_s}},
      {"unsafe target end", target_visibility_result([target_visibility_event(120.0, :infinity)]),
       target_visibility_event(120.0, :infinity), [], zero_overlap_duration(),
       {:invalid_option, :ends_at_s}},
      {"overflow target duration",
       target_visibility_result([target_visibility_event(-1.0e15, 1.0e15)]),
       target_visibility_event(-1.0e15, 1.0e15), [], zero_overlap_duration(),
       {:invalid_option, :duration_s}},
      {"wide result map",
       wide_result(target_visibility_result([target_visibility_event(120.0, 180.0)])),
       target_visibility_event(120.0, 180.0), [], zero_overlap_duration(),
       {:container_limit_exceeded, :event_result}},
      {"deep result map",
       deep_result(target_visibility_result([target_visibility_event(120.0, 180.0)])),
       target_visibility_event(120.0, 180.0), [], zero_overlap_duration(),
       {:container_limit_exceeded, :event_result}},
      {"wide source map",
       wide_source_result(target_visibility_result([target_visibility_event(120.0, 180.0)])),
       target_visibility_event(120.0, 180.0), [], zero_overlap_duration(),
       {:container_limit_exceeded, :source}},
      {"deep target source id",
       deep_target_source_result(
         target_visibility_result([target_visibility_event(120.0, 180.0)])
       ), target_visibility_event(120.0, 180.0), [], zero_overlap_duration(),
       {:invalid_option, :source}},
      {"struct target source id",
       struct_target_source_result(
         target_visibility_result([target_visibility_event(120.0, 180.0)])
       ), target_visibility_event(120.0, 180.0), [], zero_overlap_duration(),
       {:invalid_option, :source}},
      {"deep metadata map", target_visibility_result([target_visibility_event(120.0, 180.0)]),
       deep_metadata_event(target_visibility_event(120.0, 180.0)), [], zero_overlap_duration(),
       {:container_limit_exceeded, :metadata}},
      {"unsupported metadata key",
       target_visibility_result([target_visibility_event(120.0, 180.0)]),
       unsupported_metadata_event(target_visibility_event(120.0, 180.0)), [],
       zero_overlap_duration(), {:unsupported_key, :metadata}},
      {"unsupported event key type",
       target_visibility_result([target_visibility_event(120.0, 180.0)]),
       unsupported_event_key_event(target_visibility_event(120.0, 180.0)), [],
       zero_overlap_duration(), {:unsupported_key_type, :event}},
      {"forged epoch struct", target_visibility_result([target_visibility_event(120.0, 180.0)]),
       %{target_visibility_event(120.0, 180.0) | starts_at: forged_epoch(120.0)}, [],
       zero_overlap_duration(), {:invalid_option, :starts_at_s}},
      {"wrong epoch struct", target_visibility_result([target_visibility_event(120.0, 180.0)]),
       %{target_visibility_event(120.0, 180.0) | starts_at: %StructProbe{value: :epoch}}, [],
       zero_overlap_duration(), {:invalid_option, :starts_at_s}},
      {"bogus epoch scale", target_visibility_result([target_visibility_event(120.0, 180.0)]),
       %{target_visibility_event(120.0, 180.0) | starts_at: bogus_scale_epoch(120.0)}, [],
       zero_overlap_duration(), {:invalid_option, :starts_at_s}},
      {"arbitrary target metadata struct",
       target_visibility_result([target_visibility_event(120.0, 180.0)]),
       struct_metadata_event(target_visibility_event(120.0, 180.0), :activity_context), [],
       zero_overlap_duration(), {:invalid_container, :metadata}},
      {"target boundary detail tuple",
       target_visibility_result([target_visibility_event(120.0, 180.0)]),
       tuple_metadata_event(
         target_visibility_event(120.0, 180.0),
         :start_boundary_detail,
         {:caller, :tuple}
       ), [], zero_overlap_duration(), {:invalid_container, :metadata}},
      {"target json metadata tuple",
       target_visibility_result([target_visibility_event(120.0, 180.0)]),
       tuple_metadata_event(
         target_visibility_event(120.0, 180.0),
         :activity_context,
         {1.0, 2.0, 3.0}
       ), [], zero_overlap_duration(), {:invalid_container, :metadata}},
      {"target numeric metadata bound plus one",
       target_visibility_result([target_visibility_event(120.0, 180.0)]),
       numeric_metadata_event(
         target_visibility_event(120.0, 180.0),
         :sample_count,
         @safe_number_bound + 1
       ), [], zero_overlap_duration(), {:invalid_option, :metadata}},
      {"target numeric metadata huge integer",
       target_visibility_result([target_visibility_event(120.0, 180.0)]),
       numeric_metadata_event(
         target_visibility_event(120.0, 180.0),
         :sample_count,
         huge_integer()
       ), [], zero_overlap_duration(), {:invalid_option, :metadata}},
      {"metadata atom string collision",
       target_visibility_result([target_visibility_event(120.0, 180.0)]),
       metadata_collision_event(target_visibility_event(120.0, 180.0)), [],
       zero_overlap_duration(), {:atom_string_alias_collision, "target_id"}},
      {"result atom string collision",
       result_collision(target_visibility_result([target_visibility_event(120.0, 180.0)])),
       target_visibility_event(120.0, 180.0), [], zero_overlap_duration(),
       {:atom_string_alias_collision, "scenario_id"}},
      {"improper scenario id",
       improper_scenario_result(
         target_visibility_result([target_visibility_event(120.0, 180.0)])
       ), target_visibility_event(120.0, 180.0), [], zero_overlap_duration(),
       {:invalid_option, :scenario_id}},
      {"deep scenario id",
       deep_scenario_result(target_visibility_result([target_visibility_event(120.0, 180.0)])),
       target_visibility_event(120.0, 180.0), [], zero_overlap_duration(),
       {:invalid_option, :scenario_id}},
      {"oversized scenario id",
       oversized_scenario_result(
         target_visibility_result([target_visibility_event(120.0, 180.0)])
       ), target_visibility_event(120.0, 180.0), [], zero_overlap_duration(),
       {:container_limit_exceeded, :scenario_id}},
      {"malformed event",
       target_visibility_result([Map.delete(target_visibility_event(120.0, 180.0), :ends_at)]),
       Map.delete(target_visibility_event(120.0, 180.0), :ends_at), [], zero_overlap_duration(),
       {:invalid_option, :ends_at_s}},
      {"negative eclipse interval",
       target_visibility_result([target_visibility_event(120.0, 180.0)]),
       target_visibility_event(120.0, 180.0), [{180.0, 120.0}], zero_overlap_duration(),
       {:invalid_timing, :negative_eclipse_interval_duration_s}},
      {"overlap exceeds duration",
       target_visibility_result([target_visibility_event(120.0, 180.0)]),
       target_visibility_event(120.0, 180.0), [{120.0, 180.0}, {120.0, 180.0}],
       fn _interval, _intervals -> 120.0 end,
       {:invalid_timing, :eclipse_overlap_exceeds_duration_s}}
    ]
  end

  defp valid_event_results do
    [target_visibility_result([target_visibility_event(120.0, 180.0)])]
  end

  defp struct_metadata_route_event_results do
    [
      {"target metadata struct",
       [
         target_visibility_result([
           struct_metadata_event(target_visibility_event(120.0, 180.0), :activity_context)
         ])
       ]},
      {"eclipse metadata struct",
       [
         target_visibility_result([target_visibility_event(120.0, 180.0)]),
         eclipse_result([struct_metadata_event(eclipse_event(120.0, 180.0), :sun_direction)])
       ]},
      {"ground access metadata struct",
       [
         ground_station_access_result([
           struct_metadata_event(ground_station_access_event(130.0, 190.0), :activity_context)
         ])
       ]},
      {"ground access metadata tuple",
       [
         ground_station_access_result([
           tuple_metadata_event(
             ground_station_access_event(130.0, 190.0),
             :start_boundary_detail,
             {:caller, :tuple}
           )
         ])
       ]}
    ]
  end

  defp target_numeric_metadata_keys do
    [
      :target_priority,
      :max_elevation_deg,
      :minimum_elevation_deg,
      :sample_count,
      :max_sample_step_s,
      :earth_rotation_rate_rad_s,
      :start_sample_index,
      :end_sample_index,
      :event_time_tolerance_s,
      :estimated_storage_mb,
      :planned_data_volume_mb,
      :data_volume_mb,
      :estimated_data_volume_mb,
      :estimated_energy_used_wh,
      :battery_energy_consumed_wh,
      :battery_energy_generated_wh
    ]
  end

  defp target_visibility_result(events, scenario_id \\ :leo_1, target_id \\ :target_a) do
    %{
      scenario_id: scenario_id,
      event_type: :target_visibility,
      events: events,
      source: %{target_id: target_id}
    }
  end

  defp eclipse_result(events, scenario_id \\ :leo_1) do
    %{
      scenario_id: scenario_id,
      event_type: :eclipse,
      events: events,
      source: %{shadow_model: :cylindrical_central_body_shadow}
    }
  end

  defp ground_station_access_result(
         events,
         scenario_id \\ :leo_1,
         ground_station_id \\ :equator_prime
       ) do
    %{
      scenario_id: scenario_id,
      event_type: :ground_station_access,
      events: events,
      source: %{ground_station_id: ground_station_id}
    }
  end

  defp malformed_unrelated_result do
    %{
      scenario_id: :leo_1,
      event_type: :attitude_keepout,
      events: [%{type: :attitude_keepout, metadata: %{"note" => "not an observation"}} | :tail],
      source: %{"provider" => "ops"}
    }
  end

  defp target_visibility_event(starts_at_s, ends_at_s, target_id \\ :target_a) do
    %{
      type: :target_visibility,
      starts_at: epoch(starts_at_s),
      ends_at: epoch(ends_at_s),
      metadata: %{
        target_id: target_id,
        target_priority: 1.0,
        max_elevation_deg: 80.0,
        minimum_elevation_deg: 10.0
      }
    }
  end

  defp eclipse_event(starts_at_s, ends_at_s) do
    %{
      type: :eclipse,
      starts_at: epoch(starts_at_s),
      ends_at: epoch(ends_at_s),
      metadata: %{}
    }
  end

  defp ground_station_access_event(starts_at_s, ends_at_s) do
    %{
      type: :ground_station_access,
      starts_at: epoch(starts_at_s),
      ends_at: epoch(ends_at_s),
      metadata: %{
        max_elevation_deg: 55.0,
        minimum_elevation_deg: 8.0
      }
    }
  end

  defp wide_result(result), do: wide_map(result, "wide_result")

  defp deep_result(result), do: Map.put(result, :node, deep_map(9))

  defp wide_source_result(%{source: source} = result) do
    %{result | source: wide_map(source, "wide_source")}
  end

  defp deep_target_source_result(%{source: source} = result) do
    %{result | source: Map.put(source, :target_id, deep_map(9))}
  end

  defp struct_target_source_result(%{source: source} = result) do
    %{result | source: Map.put(source, :target_id, %StructProbe{value: :target})}
  end

  defp deep_eclipse_source_result(%{source: source} = result) do
    %{result | source: Map.put(source, :campaign_environment, deep_map(9))}
  end

  defp wide_metadata_event(%{metadata: metadata} = event) do
    %{event | metadata: wide_map(metadata, "wide_metadata")}
  end

  defp deep_metadata_event(%{metadata: metadata} = event) do
    %{event | metadata: Map.put(metadata, :activity_context, deep_map(9))}
  end

  defp deep_eclipse_metadata_event(%{metadata: metadata} = event) do
    %{event | metadata: Map.put(metadata, :sun_direction, deep_map(9))}
  end

  defp unsupported_metadata_event(%{metadata: metadata} = event) do
    %{event | metadata: Map.put(metadata, :unsupported_metadata, true)}
  end

  defp struct_metadata_event(%{metadata: metadata} = event, field) do
    %{event | metadata: Map.put(metadata, field, %StructProbe{value: field})}
  end

  defp tuple_metadata_event(%{metadata: metadata} = event, field, value) do
    %{event | metadata: Map.put(metadata, field, value)}
  end

  defp numeric_metadata_event(%{metadata: metadata} = event, field, value) do
    %{event | metadata: Map.put(metadata, field, value)}
  end

  defp unsupported_event_key_event(event), do: Map.put(event, {:unsupported, :event_key}, true)

  defp metadata_collision_event(%{metadata: metadata} = event) do
    %{event | metadata: Map.put(metadata, "target_id", :target_b)}
  end

  defp result_collision(result), do: Map.put(result, "scenario_id", :alias)

  defp improper_scenario_result(result), do: %{result | scenario_id: [:leo | :tail]}
  defp deep_scenario_result(result), do: %{result | scenario_id: deep_map(9)}

  defp oversized_scenario_result(result),
    do: %{result | scenario_id: String.duplicate("s", 1_025)}

  defp huge_integer, do: :erlang.bsl(1, 1_000_000)

  defp forged_epoch(seconds_since_j2000) do
    %{
      __struct__: Epoch,
      scale: :tdb,
      seconds_since_j2000: seconds_since_j2000,
      forged: true
    }
  end

  defp bogus_scale_epoch(seconds_since_j2000) do
    %Epoch{scale: :gps, seconds_since_j2000: seconds_since_j2000}
  end

  defp wide_map(map, prefix) do
    Enum.reduce(1..129, map, fn index, acc ->
      Map.put(acc, "#{prefix}_#{index}", index)
    end)
  end

  defp deep_map(depth) do
    Enum.reduce(1..depth, "leaf", fn _index, acc -> %{"next" => acc} end)
  end

  defp epoch(seconds_since_j2000)
       when is_integer(seconds_since_j2000) or is_float(seconds_since_j2000) do
    Epoch.new!(seconds_since_j2000, :tdb)
  end

  defp epoch(seconds_since_j2000) do
    %Epoch{seconds_since_j2000: seconds_since_j2000, scale: :tdb}
  end

  defp result_set(event_results) do
    ResultSet.new!(%{
      study_id: :lighting_summary_totality,
      trajectory_results: [],
      event_results: event_results,
      errors: [],
      assumptions: %{},
      metadata: %{}
    })
  end

  defp refresh_request(constraints) do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [%{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"}],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "cadence"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "test"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [
        %{"id" => "target_a", "priority" => 2.0},
        %{"id" => "target_b", "priority" => 2.0}
      ],
      "constraints" => constraints,
      "scoring_policy" => scoring_policy(),
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "resource_summaries" => [
        %{
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.9,
          "storage_capacity_mb" => 1000.0,
          "storage_used_mb" => 200.0
        }
      ]
    }
  end

  defp campaign(constraints) do
    %{
      "targets" => [
        %{"id" => "target_a", "priority" => 2.0},
        %{"id" => "target_b", "priority" => 2.0}
      ],
      "constraints" => constraints,
      "scoring_policy" => scoring_policy(),
      "resource_summaries" => [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "storage_capacity_mb" => 1000.0,
          "storage_used_mb" => 200.0,
          "downlink_capacity_mb" => 200.0,
          "downlink_margin" => 1.0
        }
      ]
    }
  end

  defp valid_constraints do
    %{"avoid_eclipse" => false, "min_activity_duration_s" => 0.0}
  end

  defp invalid_lighting_constraints do
    %{"avoid_eclipse" => false, "min_activity_duration_s" => -1.0e15}
  end

  defp scoring_policy do
    %{
      "target_value_weight" => 1.0,
      "eclipse_penalty_weight" => 1.0
    }
  end

  defp zero_overlap_duration, do: fn _interval, _intervals -> 0.0 end

  defp unexpected_overlap_callback_returns do
    callback_returns = [
      {"unsafe finite number", 1.0e16, ArgumentError},
      {"map", %{eclipse_overlap_s: 0.0}, CaseClauseError},
      {"malformed list", [0.0 | :tail], CaseClauseError},
      {"injected error tuple", {:error, :injected}, CaseClauseError},
      {"bad atom", :bad, CaseClauseError},
      {"empty list", [], CaseClauseError}
    ]

    callback_returns ++ constructed_nonfinite_callback_returns()
  end

  defp constructed_nonfinite_callback_returns do
    [
      {"constructed infinity", <<131, 70, 127, 240, 0, 0, 0, 0, 0, 0>>},
      {"constructed nan", <<131, 70, 127, 248, 0, 0, 0, 0, 0, 1>>}
    ]
    |> Enum.flat_map(fn {label, bytes} ->
      case construct_nonfinite_float(bytes) do
        {:ok, value} -> [{label, value, ArgumentError}]
        :error -> []
      end
    end)
  end

  defp expected_overlap_callback_domain_errors do
    [
      {"negative overlap", fn _interval, _intervals -> -1.0 end,
       {:invalid_timing, :negative_eclipse_overlap_s}},
      {"overlap exceeds duration", fn _interval, _intervals -> 120.0 end,
       {:invalid_timing, :eclipse_overlap_exceeds_duration_s}}
    ]
  end

  defp construct_nonfinite_float(bytes) do
    {:ok, :erlang.binary_to_term(bytes)}
  rescue
    _error in [ArgumentError] -> :error
  end

  defp direct_observe_callbacks(overlap_duration),
    do: campaign_activity_callbacks(overlap_duration)

  defp campaign_activity_callbacks(overlap_duration) do
    [
      encode_value: &ValueEncoding.encode_value/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      numeric_policy_value: &numeric_policy_value/3,
      boolean_policy_value: &boolean_policy_value/3,
      normalized_status_token: &ScalarValues.normalized_status_token/1,
      overlap_duration: overlap_duration,
      activity_id: &ActivityIdentity.activity_id/4,
      window_id: &ActivityIdentity.window_id/4,
      score: &score/1,
      compact_map: &ValueEncoding.compact_map/1
    ]
  end

  defp numeric_policy_value(policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key, default)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp boolean_policy_value(policy, key, default) do
    case ScalarValues.json_boolean_value(Map.get(policy, key, default)) do
      value when is_boolean(value) -> value
      _value -> default
    end
  end

  defp score(score_terms) do
    score_terms
    |> Map.values()
    |> Enum.sum()
  end

  defp lighting_summary_wrapper(source) do
    [_before_wrapper, wrapper_start] = String.split(source, "  defp lighting_summary", parts: 2)

    [wrapper | _after_wrapper] =
      String.split(wrapper_start, "  defp validate_lighting_inputs", parts: 2)

    wrapper
  end

  defp scoreable_observations(artifact, field) do
    artifact
    |> Map.get(field, [])
    |> Enum.filter(fn
      %{} = activity -> Map.get(activity, "type") == "observe" and Map.has_key?(activity, "score")
      _entry -> false
    end)
  end

  defp downlink_entries(artifact, field) do
    artifact
    |> Map.get(field, [])
    |> Enum.filter(fn
      %{} = activity -> Map.get(activity, "type") == "downlink"
      _entry -> false
    end)
  end

  defp error_tuple_entries(artifact, field) do
    artifact
    |> Map.get(field, [])
    |> Enum.filter(&match?({:error, _reason}, &1))
  end

  defp invalid_refreshed_eclipse_interval?(artifact) do
    artifact
    |> get_in(["refreshed_windows", "eclipse_intervals"])
    |> List.wrap()
    |> Enum.any?(fn interval ->
      case interval do
        %{} ->
          starts_at_s = Map.get(interval, "starts_at_s")
          ends_at_s = Map.get(interval, "ends_at_s")

          invalid_number?(starts_at_s) or invalid_number?(ends_at_s) or
            unsafe_duration?(starts_at_s, ends_at_s)

        _other ->
          true
      end
    end)
  end

  defp invalid_number?(value) when is_integer(value), do: abs(value) > 1.0e15

  defp invalid_number?(value) when is_float(value) do
    value != value or value - value != 0.0 or abs(value) > 1.0e15
  end

  defp invalid_number?(_value), do: true

  defp unsafe_duration?(starts_at_s, ends_at_s)
       when is_number(starts_at_s) and is_number(ends_at_s) do
    duration_s = ends_at_s - starts_at_s
    invalid_number?(duration_s) or duration_s < 0.0
  end

  defp unsafe_duration?(_starts_at_s, _ends_at_s), do: true

  defp encoded_tuple_probe?(["caller", "tuple"]), do: true

  defp encoded_tuple_probe?(%{} = map) do
    Enum.any?(map, fn {key, value} -> encoded_tuple_probe?(key) or encoded_tuple_probe?(value) end)
  end

  defp encoded_tuple_probe?(values) when is_list(values),
    do: Enum.any?(values, &encoded_tuple_probe?/1)

  defp encoded_tuple_probe?(_value), do: false

  defp observation_entries(artifact, field) do
    artifact
    |> Map.get(field, [])
    |> Enum.filter(fn
      %{} = activity -> Map.get(activity, "type") == "observe"
      {:error, {:invalid_observation_lighting, _reason}} -> true
      _entry -> false
    end)
  end

  defp common_observation_projection(candidate) do
    Map.take(candidate, Map.keys(valid_observation_projection()))
  end

  defp valid_observation_projection do
    %{
      "id" => "leo_1_observe_target_a_1",
      "type" => "observe",
      "scenario_id" => "leo_1",
      "target_id" => "target_a",
      "starts_at_s" => 120.0,
      "ends_at_s" => 180.0,
      "duration_s" => 60.0,
      "score" => 120.0,
      "eclipse_overlap_s" => 0.0,
      "eclipse_overlap_fraction" => 0.0,
      "lighting_condition" => "sunlit",
      "lighting_condition_detail" => "sunlit",
      "lighting_condition_model" => "sampled_eclipse_overlap_tag",
      "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
      "lighting_confidence" => "bounded_by_sampled_eclipse_overlap",
      "source_window_id" => "window:leo_1:target_visibility:target_a:1"
    }
  end
end
