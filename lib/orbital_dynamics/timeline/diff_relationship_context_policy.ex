defmodule OrbitalDynamics.Timeline.DiffRelationshipContextPolicy do
  @moduledoc false

  def dependency(prefix, row) do
    %{
      "#{prefix}_dependency_activity_ids" => row["dependency_activity_ids"],
      "#{prefix}_dependency_timeline_ids" => row["dependency_timeline_ids"],
      "#{prefix}_timeline_integrity_status" => row["timeline_integrity_status"],
      "#{prefix}_timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
      "#{prefix}_timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
      "#{prefix}_timeline_integrity_issues" => row["timeline_integrity_issues"],
      "#{prefix}_missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
      "#{prefix}_missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
      "#{prefix}_self_dependency_activity_ids" => row["self_dependency_activity_ids"],
      "#{prefix}_self_dependency_timeline_ids" => row["self_dependency_timeline_ids"],
      "#{prefix}_dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
      "#{prefix}_dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
      "#{prefix}_dependency_order_violation_activity_ids" =>
        row["dependency_order_violation_activity_ids"],
      "#{prefix}_dependency_order_violation_timeline_ids" =>
        row["dependency_order_violation_timeline_ids"],
      "#{prefix}_exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
      "#{prefix}_exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
      "#{prefix}_exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
      "#{prefix}_exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
      "#{prefix}_exclusivity_violation_group" => row["exclusivity_violation_group"]
    }
  end

  def schedule(prefix, row) do
    %{
      "#{prefix}_allow_overlap" => row["allow_overlap"]
    }
  end
end
