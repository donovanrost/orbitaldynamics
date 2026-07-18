defmodule OrbitalDynamics.Timeline.PublicationSourceSummaryPolicy do
  @moduledoc false

  def publication_dependency_impact_summary(%{} = summary, stringify_keys, schema_contract) do
    summary
    |> stringify_keys.()
    |> case do
      %{"schema_contract" => ^schema_contract} = summary -> summary
      %{"model" => "artifact_only_timeline_dependency_impact_summary"} = summary -> summary
      _summary -> %{}
    end
  end

  def publication_dependency_impact_summary(_summary, _stringify_keys, _schema_contract), do: %{}

  def publication_optional_source_timeline_dependency_impact_summary(%{} = summary)
      when map_size(summary) > 0,
      do: summary

  def publication_optional_source_timeline_dependency_impact_summary(_summary), do: nil

  def publication_timeline_diff_summary(%{} = summary, stringify_keys, schema_contract) do
    summary
    |> stringify_keys.()
    |> case do
      %{"schema_contract" => ^schema_contract} = summary -> summary
      %{"model" => "artifact_only_timeline_diff_summary"} = summary -> summary
      _summary -> %{}
    end
  end

  def publication_timeline_diff_summary(_summary, _stringify_keys, _schema_contract), do: %{}

  def publication_optional_source_timeline_diff_summary(summary) when summary == %{}, do: nil

  def publication_optional_source_timeline_diff_summary(summary), do: summary
end
