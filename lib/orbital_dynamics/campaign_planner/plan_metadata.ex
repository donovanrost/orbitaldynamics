defmodule OrbitalDynamics.CampaignPlanner.PlanMetadata do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ValueEncoding
  alias OrbitalDynamics.ResultSet

  def warnings(
        campaign,
        candidates,
        timelines,
        result_set,
        resource_filter_report,
        contact_filter_report
      ) do
    []
    |> maybe_warn(campaign_targets(campaign) == [], "campaign has no targets")
    |> maybe_warn(candidates == [], "no candidate activities were generated")
    |> maybe_warn(timelines == [], "no candidate timelines were ranked")
    |> maybe_warn(
      not Enum.any?(candidates, &(&1["type"] == "downlink")),
      "no contact activities proposed"
    )
    |> maybe_warn(
      Map.get(resource_filter_report || %{}, "suppressed_candidate_count", 0) > 0,
      "resource summary filters suppressed campaign candidates"
    )
    |> maybe_warn(
      Map.get(contact_filter_report || %{}, "suppressed_candidate_count", 0) > 0,
      "contact filters suppressed campaign contacts"
    )
    |> maybe_warn(result_set.errors != [], "study completed with propagation or event errors")
    |> Enum.reverse()
  end

  def warnings(
        campaign,
        candidates,
        timelines,
        result_set,
        resource_filter_report,
        contact_filter_report,
        _callbacks
      ) do
    warnings(
      campaign,
      candidates,
      timelines,
      result_set,
      resource_filter_report,
      contact_filter_report
    )
  end

  def assumptions(campaign) do
    %{
      "activity_builder" => "windows_to_observe_and_downlink_candidates",
      "timeline_selector" => "per_spacecraft_greedy_non_overlapping",
      "resource_filter" => "resource_summary_availability_and_margin_filter",
      "contact_filter" => "ground_network_availability_filter_before_ranking",
      "cadence_integration" => "artifact_only_no_api_or_database_writes",
      "constraints" => Map.get(campaign, "constraints", %{}),
      "scoring_policy" => Map.get(campaign, "scoring_policy", %{})
    }
  end

  def provenance(%ResultSet{} = result_set) do
    run = Map.get(result_set.metadata, :run) || Map.get(result_set.metadata, "run") || %{}
    run_metadata = Map.get(run, "metadata") || Map.get(run, :metadata) || %{}

    %{
      "run_id" => ValueEncoding.encode_value(Map.get(run, "id") || Map.get(run, :id)),
      "manifest" =>
        ValueEncoding.encode_value(
          Map.get(run_metadata, "manifest") || Map.get(run_metadata, :manifest)
        ),
      "git_revision" =>
        ValueEncoding.encode_value(
          Map.get(run_metadata, "git_revision") || Map.get(run_metadata, :git_revision)
        ),
      "propagator" => ValueEncoding.encode_value(get_in(result_set.assumptions, [:propagator])),
      "propagator_opts" =>
        ValueEncoding.encode_value(get_in(result_set.assumptions, [:propagator_opts]))
    }
  end

  def provenance(%ResultSet{} = result_set, _callbacks), do: provenance(result_set)

  def ranking_explanation(policy) do
    %{
      "objective" => "maximize weighted observation value and contact value",
      "formula" =>
        "sum(target_priority * duration_s * target_value_weight) + sum(contact_duration_s * contact_value_weight) - eclipse_overlap_s * eclipse_penalty_weight - activity_count * activity_count_penalty",
      "policy" => policy
    }
  end

  defp maybe_warn(warnings, true, message), do: [message | warnings]
  defp maybe_warn(warnings, false, _message), do: warnings

  defp campaign_targets(campaign), do: Map.get(campaign, "targets", [])
end
