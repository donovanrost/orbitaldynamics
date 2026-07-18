defmodule OrbitalDynamics.Timeline.DiffPresentationPolicy do
  @moduledoc false

  def required_operator_action("unchanged", _requires_review), do: "none"
  def required_operator_action("changed", true), do: "review_timeline_change"
  def required_operator_action("changed", false), do: "record_timeline_change"

  def reason("unchanged", source, _replacement, _changed_fields),
    do: "timeline activity #{source["activity_id"]} is unchanged"

  def reason("changed", source, replacement, changed_fields) do
    "timeline activity #{source["activity_id"]} changes to #{replacement["activity_id"]}: #{Enum.join(changed_fields, ",")}"
  end
end
