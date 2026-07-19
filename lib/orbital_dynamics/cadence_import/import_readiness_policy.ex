defmodule OrbitalDynamics.CadenceImport.ImportReadinessPolicy do
  @moduledoc false

  def cadence_import_present?(%{"has_cadence_import" => value}, _status)
      when is_boolean(value),
      do: value

  def cadence_import_present?(_row, "missing"), do: false

  def cadence_import_present?(row, _status) do
    present_string?(row["cadence_import_id"]) ||
      present_string?(row["cadence_import_type"]) ||
      is_map(row["cadence_import"])
  end

  def adapter_import_status("invalid", _approval_status), do: "review_required_before_import"
  def adapter_import_status("missing", _approval_status), do: "blocked_missing_cadence_import"
  def adapter_import_status("not_applicable", _approval_status), do: "not_applicable"

  def adapter_import_status(_status, approval_status)
      when approval_status in ["operator_review_required", "blocked_by_policy"] do
    "review_required_before_import"
  end

  def adapter_import_status("present", _approval_status), do: "ready_for_import"
  def adapter_import_status(_status, _approval_status), do: "review_required_before_import"

  defp present_string?(value), do: is_binary(value) and value != ""
end
