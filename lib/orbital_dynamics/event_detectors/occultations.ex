defmodule OrbitalDynamics.EventDetectors.Occultations do
  @moduledoc "Finite spherical-source/occulter contact functions and uniform angular-disk lighting fraction."
  alias OrbitalDynamics.Vector3, as: V
  alias OrbitalDynamics.EventSearch.{Function, Source}
  alias OrbitalDynamics.EventDetectors.Geometry
  alias OrbitalDynamics.MissionAnalysis.Input

  def functions(
        id,
        %Source{} = luminary,
        luminary_radius_km,
        %Source{} = occulter,
        occulter_radius_km,
        opts
      ) do
    Input.id!(id)
    Input.positive!(luminary_radius_km, "luminary radius")
    Input.positive!(occulter_radius_km, "occulter radius")

    assumptions = %{
      "model" => "spherical_finite_source_occultation",
      "luminary" => Source.describe(luminary),
      "occulter" => Source.describe(occulter),
      "luminary_radius_km" => luminary_radius_km,
      "occulter_radius_km" => occulter_radius_km,
      "limits" => [
        "simultaneous geometric positions; no light-time, aberration, refraction, flattening or atmosphere",
        "requires nonoverlapping spheres with resolved near/far depth ordering",
        "visible fraction uses uniform angular-circle overlap; no limb darkening or radiance-weighted panel/beam integration"
      ]
    }

    Enum.map([:any, :umbra, :antumbra, :penumbra], fn kind ->
      Function.new!(
        id <> "." <> Atom.to_string(kind),
        fn observer ->
          with {:ok, g} <-
                 geometry(observer, luminary, luminary_radius_km, occulter, occulter_radius_km) do
            {value, rate} =
              case kind do
                :any -> {g.outer, g.outer_rate}
                :umbra -> {g.umbra, g.umbra_rate}
                :antumbra -> {g.antumbra, g.antumbra_rate}
                :penumbra -> {min(-g.outer, min(g.umbra, g.antumbra)), nil}
              end

            {:ok, value, rate, g.metadata}
          end
        end,
        [
          units: "1",
          condition: if(kind == :penumbra, do: :nonnegative, else: :nonpositive),
          assumptions: assumptions,
          labels: %{
            increasing:
              if(kind == :penumbra, do: "penumbra_entry", else: Atom.to_string(kind) <> "_exit"),
            decreasing:
              if(kind == :penumbra, do: "penumbra_exit", else: Atom.to_string(kind) <> "_entry")
          }
        ] ++ opts
      )
    end)
  end

  def geometry(observer, luminary, luminary_radius_km, occulter, occulter_radius_km) do
    Input.positive!(luminary_radius_km, "luminary radius")
    Input.positive!(occulter_radius_km, "occulter radius")

    with {:ok, s} <- Geometry.secondary(luminary, observer),
         {:ok, b} <- Geometry.secondary(occulter, observer) do
      geometry_states(observer, s, luminary_radius_km, b, occulter_radius_km)
    end
  end

  @doc "The same finite-source geometry for three simultaneous states in one explicit frame."
  def geometry_states(observer, s, luminary_radius_km, b, occulter_radius_km) do
    Input.positive!(luminary_radius_km, "luminary radius")
    Input.positive!(occulter_radius_km, "occulter radius")

    unless Enum.all?(
             [s, b],
             &(OrbitalDynamics.Frame.compatible?(&1.frame, observer.frame) and
                 &1.epoch == observer.epoch)
           ),
           do: raise(ArgumentError, "occultation states must share frame and epoch")

    l = V.subtract(s.position_km, observer.position_km)
    c = V.subtract(b.position_km, observer.position_km)
    dl = V.norm(l)
    dc = V.norm(c)

    cond do
      dl <= luminary_radius_km or dc <= occulter_radius_km ->
        {:error, :observer_inside_occultation_body}

      V.norm(V.subtract(s.position_km, b.position_km)) <=
          luminary_radius_km + occulter_radius_km ->
        {:error, :overlapping_occultation_bodies}

      dc - occulter_radius_km > dl + luminary_radius_km ->
        {:ok,
         %{
           outer: 1.0,
           outer_rate: 0.0,
           umbra: 1.0,
           umbra_rate: 0.0,
           antumbra: 1.0,
           antumbra_rate: 0.0,
           metadata: %{
             "regime" => "none",
             "visible_fraction" => 1.0,
             "depth_order" => "occulter_behind_source"
           }
         }}

      dc + occulter_radius_km >= dl - luminary_radius_km ->
        {:unknown, :occultation_depth_order_unresolved}

      true ->
        lv = V.subtract(s.velocity_km_s, observer.velocity_km_s)
        cv = V.subtract(b.velocity_km_s, observer.velocity_km_s)
        lu = V.scale(l, 1 / dl)
        cu = V.scale(c, 1 / dc)
        lrate = V.dot(lu, lv)
        crate = V.dot(cu, cv)
        alpha = :math.asin(luminary_radius_km / dl)
        beta = :math.asin(occulter_radius_km / dc)

        arate =
          -luminary_radius_km * lrate /
            (dl * dl * :math.sqrt(1 - :math.pow(luminary_radius_km / dl, 2)))

        brate =
          -occulter_radius_km * crate /
            (dc * dc * :math.sqrt(1 - :math.pow(occulter_radius_km / dc, 2)))

        dot = max(-1.0, min(1.0, V.dot(lu, cu)))

        dotrate =
          V.dot(V.scale(V.subtract(lv, V.scale(lu, lrate)), 1 / dl), cu) +
            V.dot(lu, V.scale(V.subtract(cv, V.scale(cu, crate)), 1 / dc))

        separation = :math.atan2(V.norm(V.cross(lu, cu)), dot)
        outer = :math.cos(alpha + beta) - dot
        # Continuous conjunction margins, including the equal-angular-size
        # transition. An inactive branch must not jump to an arbitrary constant.
        contact = :math.cos(beta - alpha) - dot
        contact_rate = -:math.sin(beta - alpha) * (brate - arate) - dotrate
        umbra = max(alpha - beta, contact)
        antumbra = max(beta - alpha, contact)
        umbra_rate = branch_rate(alpha - beta, arate - brate, contact, contact_rate)
        antumbra_rate = branch_rate(beta - alpha, brate - arate, contact, contact_rate)

        regime =
          cond do
            separation >= alpha + beta -> "none"
            beta >= alpha and separation <= beta - alpha -> "umbra"
            alpha > beta and separation <= alpha - beta -> "antumbra"
            true -> "penumbra"
          end

        {:ok,
         %{
           outer: outer,
           outer_rate: -:math.sin(alpha + beta) * (arate + brate) - dotrate,
           umbra: umbra,
           umbra_rate: umbra_rate,
           antumbra: antumbra,
           antumbra_rate: antumbra_rate,
           metadata: %{
             "regime" => regime,
             "visible_fraction" => visible_fraction(alpha, beta, separation),
             "source_angular_radius_rad" => alpha,
             "occulter_angular_radius_rad" => beta,
             "angular_separation_rad" => separation
           }
         }}
    end
  end

  defp branch_rate(a, da, b, db) do
    cond do
      a > b -> da
      b > a -> db
      true -> nil
    end
  end

  @doc "Uniform apparent angular-circle overlap, including annular containment; not a radiance integral."
  def visible_fraction(a, b, d) do
    Input.positive!(a, "apparent source radius")
    Input.positive!(b, "apparent occulting radius")
    Input.number!(d, "apparent separation", 0, :math.pi())

    cond do
      d >= a + b ->
        1.0

      d <= abs(a - b) ->
        max(0.0, 1 - :math.pow(min(a, b) / a, 2))

      true ->
        x = max(-1.0, min(1.0, (d * d + a * a - b * b) / (2 * d * a)))
        y = max(-1.0, min(1.0, (d * d + b * b - a * a) / (2 * d * b)))
        product = max(0.0, (-d + a + b) * (d + a - b) * (d - a + b) * (d + a + b))
        overlap = a * a * :math.acos(x) + b * b * :math.acos(y) - 0.5 * :math.sqrt(product)
        max(0.0, min(1.0, 1 - overlap / (:math.pi() * a * a)))
    end
  end
end
