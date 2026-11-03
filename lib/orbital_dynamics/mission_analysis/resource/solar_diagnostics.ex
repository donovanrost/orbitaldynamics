defmodule OrbitalDynamics.MissionAnalysis.Resource.SolarDiagnostics do
  @moduledoc "Observed solar-source samples and shadow brackets from completed resource reports."
  def annotate(report) do
    resources = get_in(report, ["attitude_planning", "resource_feasibility"])

    models =
      if is_map(resources),
        do:
          Enum.flat_map(Enum.sort(resources["assets"]), fn {asset, r} ->
            for m <- Map.get(r, "models", []),
                solar_model?(m) do
              %{
                "asset_id" => asset,
                "resource_id" => m["id"],
                "contact_search" => get_in(m, ["assumptions", "contact_search"]) || :null,
                "levels" => Enum.map(m["levels"], &level/1)
              }
            end
          end),
        else: []

    if models == [],
      do: report,
      else:
        Map.put(report, "solar_generation_diagnostics", %{
          "models" => models,
          "limits" =>
            "observed midpoint samples and shadow-change brackets only; no unique-crossing, root-time or continuous-power guarantee; a zero bracket count does not establish continuous sunlight"
        })
  end

  defp level(level) do
    samples =
      for sample <- Map.get(level, "samples", []),
          e = get_in(sample, ["metrics", "generation_evidence"]),
          is_map(e),
          e["model"] == "body_fixed_solar_array_v1" do
        %{
          "epoch_s" => sample["evaluated_at_s"],
          "sunlit" => e["spacecraft_sunlit"],
          "visible_fraction" => e["visible_fraction"],
          "occultation_regime" => e["occultation_regime"],
          "generation_w" => sample["metrics"]["generation_w"],
          "shadow_margin_km" => e["shadow_margin_km"]
        }
      end

    brackets =
      for [a, b] <- Enum.chunk_every(samples, 2, 1, :discard), a["sunlit"] != b["sunlit"] do
        %{
          "earlier_sample_s" => a["epoch_s"],
          "later_sample_s" => b["epoch_s"],
          "from_sunlit" => a["sunlit"],
          "to_sunlit" => b["sunlit"]
        }
      end

    %{
      "sample_step_s" => level["sample_step_s"],
      "status" => level["status"],
      "source_sample_count" => length(samples),
      "shadow_transition_brackets" => brackets,
      "observed_power_range_w" =>
        if(samples == [],
          do: :null,
          else: %{
            "min" => samples |> Enum.map(& &1["generation_w"]) |> Enum.min(),
            "max" => samples |> Enum.map(& &1["generation_w"]) |> Enum.max()
          }
        )
    }
  end

  defp solar_model?(m) do
    case get_in(m, ["assumptions", "generation_assumptions"]) do
      %{"model" => "body_fixed_solar_array_v1"} -> true
      _ -> false
    end
  end
end
