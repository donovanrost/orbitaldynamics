defmodule OrbitalDynamics.Timeline.RowStateClassificationPolicy do
  @moduledoc false

  def approved?(row), do: row["approval_status"] in ["approved", "auto_approvable"]

  def executed?(row, executed_statuses), do: row["status"] in executed_statuses

  def integrity_review?(row), do: row["timeline_integrity_status"] == "review_required"
end
