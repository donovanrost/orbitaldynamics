defmodule OrbitalDynamics.CampaignPlanner.ContactAllocationReportPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ContactAllocationPressureFanout, ValueEncoding}

  def build(reports, callbacks \\ default_callbacks()) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    pressure_branch = Keyword.fetch!(callbacks, :pressure_branch)

    Enum.flat_map(reports, fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys.(&1))
      |> Enum.flat_map(fn row ->
        row
        |> Map.put("_source_report_trust_boundary", trust_boundary)
        |> pressure_branch.(source_path)
      end)
    end)
  end

  defp default_callbacks do
    [
      pressure_branch: &ContactAllocationPressureFanout.branches/2,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end
end
