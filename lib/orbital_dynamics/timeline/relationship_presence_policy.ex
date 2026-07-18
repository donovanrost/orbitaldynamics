defmodule OrbitalDynamics.Timeline.RelationshipPresencePolicy do
  @moduledoc false

  def has_dependencies?(row) do
    non_empty_list?(row["dependency_activity_ids"]) or
      non_empty_list?(row["dependency_timeline_ids"])
  end

  def has_exclusivity?(row) do
    non_empty_list?(row["exclusive_with_activity_ids"]) or
      non_empty_list?(row["exclusive_with_timeline_ids"])
  end

  defp non_empty_list?(value), do: is_list(value) and value != []
end
