defmodule OrbitalDynamics.CampaignPlanner.StrategySourceReportRegistryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  alias OrbitalDynamics.CampaignPlanner.{
    MissionStateCandidateRefreshSourceReports,
    StrategyCandidateSource
  }

  test "branch refresh source report registry matches the mission-state request builder" do
    duplicate_keys = fn keys ->
      keys
      |> Enum.frequencies()
      |> Enum.filter(fn {_key, count} -> count > 1 end)
      |> Enum.map(fn {key, _count} -> key end)
      |> Enum.sort()
    end

    builder_keys = MissionStateCandidateRefreshSourceReports.candidate_refresh_source_input_keys()

    registry_keys =
      StrategyCandidateSource.source_report_input_fields()
      |> Enum.flat_map(fn {source_key, canonical_key} -> [source_key, canonical_key] end)

    registry_canonical_keys =
      registry_keys
      |> Enum.chunk_every(2)
      |> Enum.map(&List.last/1)
      |> MapSet.new()

    accepted_report_summary_inputs =
      CandidateRefresh.capabilities().inputs
      |> Enum.map(&Atom.to_string/1)
      |> Enum.filter(&String.ends_with?(&1, ["_report", "_summary"]))
      |> MapSet.new()

    assert duplicate_keys.(builder_keys) == []
    assert duplicate_keys.(registry_keys) == []

    assert MapSet.difference(accepted_report_summary_inputs, registry_canonical_keys) ==
             MapSet.new()

    top_level_request_keys =
      MapSet.new([
        "source_timeline_feedback_report",
        "timeline_feedback_report",
        "source_operational_timeline_report",
        "operational_timeline_report"
      ])

    synthetic_builder_keys =
      MapSet.new([
        "source_result_artifact",
        "result_artifact"
      ])

    builder_key_set = MapSet.new(builder_keys)
    registry_key_set = MapSet.new(registry_keys)

    assert Enum.sort(MapSet.to_list(MapSet.difference(registry_key_set, builder_key_set))) ==
             Enum.sort(MapSet.to_list(top_level_request_keys))

    assert Enum.sort(MapSet.to_list(MapSet.difference(builder_key_set, registry_key_set))) ==
             Enum.sort(MapSet.to_list(synthetic_builder_keys))

    assert Enum.sort(MapSet.to_list(MapSet.difference(registry_key_set, top_level_request_keys))) ==
             Enum.sort(MapSet.to_list(MapSet.difference(builder_key_set, synthetic_builder_keys)))
  end
end
