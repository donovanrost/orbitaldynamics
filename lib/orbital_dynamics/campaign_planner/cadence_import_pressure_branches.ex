defmodule OrbitalDynamics.CampaignPlanner.CadenceImportPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    CadenceImportDirectPressureBranches,
    CadenceImportSourceReports,
    OperatorReviewPressureBranches,
    ValueEncoding
  }

  def from_prior_plan(prior_plan, policy) do
    prior_plan
    |> CadenceImportSourceReports.prior_plan_cadence_import_manifests()
    |> CadenceImportSourceReports.pressure_rows_with_source()
    |> from_rows(policy)
  end

  def from_mission_state(mission_state, policy) do
    mission_state
    |> CadenceImportSourceReports.cadence_import_manifests()
    |> CadenceImportSourceReports.pressure_rows_with_source()
    |> from_rows(policy)
  end

  defp from_rows(rows, policy) do
    Enum.flat_map(rows, fn {row, source_prefix, index} ->
      from_row(row, index, policy, source_prefix)
    end)
  end

  defp from_row(row, index, policy, source_prefix) do
    source_review_row =
      case Map.get(row, "source_review_row") do
        %{} = source ->
          source
          |> ValueEncoding.stringify_keys()
          |> Map.put_new("approval_status", row["approval_status"])
          |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)

        _source ->
          %{}
      end

    source_review_branches =
      if source_review_row == %{} do
        []
      else
        OperatorReviewPressureBranches.from_row(
          source_review_row,
          index,
          policy,
          "#{source_prefix}.source_review_row"
        )
      end

    if source_review_branches != [] do
      source_review_branches
    else
      CadenceImportDirectPressureBranches.branches(
        row,
        source_review_row,
        index,
        policy,
        source_prefix
      )
    end
  end
end
