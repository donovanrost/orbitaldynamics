package org.orbitaldynamics.validation;

import java.io.IOException;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import org.hipparchus.CalculusFieldElement;
import org.hipparchus.geometry.euclidean.threed.Rotation;
import org.hipparchus.geometry.euclidean.threed.RotationConvention;
import org.hipparchus.geometry.euclidean.threed.Vector3D;
import org.hipparchus.ode.nonstiff.ClassicalRungeKuttaIntegrator;
import org.orekit.bodies.OneAxisEllipsoid;
import org.orekit.forces.drag.DragForce;
import org.orekit.forces.drag.IsotropicDrag;
import org.orekit.forces.gravity.J2OnlyPerturbation;
import org.orekit.frames.FieldTransform;
import org.orekit.frames.Frame;
import org.orekit.frames.FramesFactory;
import org.orekit.frames.Transform;
import org.orekit.frames.TransformProvider;
import org.orekit.models.earth.atmosphere.SimpleExponentialAtmosphere;
import org.orekit.orbits.CartesianOrbit;
import org.orekit.orbits.OrbitType;
import org.orekit.propagation.BoundedPropagator;
import org.orekit.propagation.EphemerisGenerator;
import org.orekit.propagation.SpacecraftState;
import org.orekit.propagation.numerical.NumericalPropagator;
import org.orekit.time.AbsoluteDate;
import org.orekit.time.FieldAbsoluteDate;
import org.orekit.time.TimeScalesFactory;
import org.orekit.utils.PVCoordinates;

/** Generates the checked D3 J2-plus-drag envelope corpus with upstream Orekit. */
public final class OrekitJ2DragEnvelopeGenerator {

    private static final List<String> GLOBAL_KEYS = List.of(
        "corpus_id", "generated_at_utc", "orekit_version", "frame", "epoch",
        "time_scale", "integrator", "atmosphere_model", "earth_rotation_model",
        "orekit_data_revision", "eop_source", "output_float_format", "case_count"
    );

    private static final List<String> CASE_KEYS = List.of(
        "id", "force_branch", "duration_s", "output_step_s", "integrator_step_s",
        "mu_km3_s2", "equatorial_radius_km", "j2", "initial_position_km",
        "initial_velocity_km_s", "atmosphere_reference_altitude_km",
        "atmosphere_reference_density_kg_m3", "atmosphere_scale_height_km",
        "spacecraft_mass_kg", "spacecraft_drag_area_m2", "spacecraft_drag_coefficient",
        "earth_rotation_rate_rad_s"
    );

    private OrekitJ2DragEnvelopeGenerator() {
    }

    public static void main(final String[] args) throws Exception {
        Locale.setDefault(Locale.ROOT);
        if (args.length != 3) {
            throw new IllegalArgumentException(
                "usage: OrekitJ2DragEnvelopeGenerator CONFIG OUTPUT SOURCE_ID_SHA256");
        }

        final Map<String, String> config = readStrictProperties(Path.of(args[0]));
        final String sourceIdentity = requireSha256(args[2]);
        final List<CaseConfig> cases = validatePinnedConfiguration(config);
        final AbsoluteDate epoch = new AbsoluteDate(
            2000, 1, 1, 12, 0, 0.0, TimeScalesFactory.getTDB());
        final Frame inertial = FramesFactory.getEME2000();
        final List<CaseResult> results = new ArrayList<>();

        for (final CaseConfig caseConfig : cases) {
            results.add(propagate(caseConfig, epoch, inertial));
        }

        writeOutput(Path.of(args[1]), config, sourceIdentity, results);
    }

    private static CaseResult propagate(final CaseConfig config, final AbsoluteDate epoch,
                                        final Frame inertial) {
        final Vector3D position = config.initialPositionKm().scalarMultiply(1000.0);
        final Vector3D velocity = config.initialVelocityKmS().scalarMultiply(1000.0);
        final double muM3S2 = config.muKm3S2() * 1.0e9;
        final double radiusM = config.equatorialRadiusKm() * 1000.0;
        final CartesianOrbit initialOrbit = new CartesianOrbit(
            new PVCoordinates(position, velocity), inertial, epoch, muM3S2);
        final Frame rotating = constantRateBodyFrame(
            inertial, epoch, config.earthRotationRateRadS());
        final OneAxisEllipsoid body = new OneAxisEllipsoid(radiusM, 0.0, rotating);
        final SimpleExponentialAtmosphere atmosphere = new SimpleExponentialAtmosphere(
            body,
            config.atmosphereReferenceDensityKgM3(),
            config.atmosphereReferenceAltitudeKm() * 1000.0,
            config.atmosphereScaleHeightKm() * 1000.0);

        final NumericalPropagator propagator = new NumericalPropagator(
            new ClassicalRungeKuttaIntegrator(config.integratorStepS()));
        propagator.setOrbitType(OrbitType.CARTESIAN);
        propagator.setInitialState(
            new SpacecraftState(initialOrbit).withMass(config.spacecraftMassKg()));
        propagator.addForceModel(new J2OnlyPerturbation(
            muM3S2, radiusM, config.j2(), inertial));
        propagator.addForceModel(new DragForce(
            atmosphere,
            new IsotropicDrag(
                config.spacecraftDragAreaM2(), config.spacecraftDragCoefficient())));

        final EphemerisGenerator ephemerisGenerator = propagator.getEphemerisGenerator();
        propagator.propagate(epoch.shiftedBy(config.durationS()));
        final BoundedPropagator ephemeris = ephemerisGenerator.getGeneratedEphemeris();
        final int stateCount = stateCount(config);
        final List<StateRow> states = new ArrayList<>(stateCount);

        for (int index = 0; index < stateCount; index++) {
            final double offset = index * config.outputStepS();
            final SpacecraftState state = ephemeris.propagate(epoch.shiftedBy(offset));
            states.add(new StateRow(offset, state.getPosition(), state.getVelocity()));
        }

        return new CaseResult(config, states);
    }

    private static Frame constantRateBodyFrame(final Frame inertial, final AbsoluteDate epoch,
                                                final double rate) {
        final Rotation initialRotation = new Rotation(
            Vector3D.PLUS_K, 0.0, RotationConvention.VECTOR_OPERATOR);
        final Transform initial = new Transform(
            epoch, initialRotation, new Vector3D(0.0, 0.0, rate));
        return new Frame(inertial, new ShiftedTransformProvider(epoch, initial),
            "constant-rate-spherical-earth", false);
    }

    private static List<CaseConfig> validatePinnedConfiguration(
            final Map<String, String> config) {
        exact(config, "orekit_version", "13.1.7");
        exact(config, "frame", "EME2000");
        exact(config, "epoch", "2000-01-01T12:00:00_TDB");
        exact(config, "time_scale", "TDB_J2000_RELATIVE_SECONDS");
        exact(config, "integrator", "ClassicalRungeKuttaIntegrator");
        exact(config, "atmosphere_model", "SimpleExponentialAtmosphere");
        exact(config, "earth_rotation_model",
            "constant_z_axis_rotation_from_zero_angle_at_case_epoch");
        exact(config, "orekit_data_revision", "none");
        exact(config, "eop_source", "none");
        exact(config, "output_float_format", "%.17e");

        final int count = integer(config, "case_count");
        if (count != 8) {
            throw new IllegalArgumentException("case_count must equal 8");
        }

        final Set<String> required = new HashSet<>(GLOBAL_KEYS);
        final List<CaseConfig> cases = new ArrayList<>();
        final Set<String> ids = new HashSet<>();
        for (int index = 1; index <= count; index++) {
            final String prefix = "case." + index + ".";
            for (final String key : CASE_KEYS) {
                required.add(prefix + key);
            }
            final CaseConfig parsed = parseCase(config, prefix);
            validateCase(parsed);
            if (!ids.add(parsed.id())) {
                throw new IllegalArgumentException("duplicate case id: " + parsed.id());
            }
            cases.add(parsed);
        }

        if (!config.keySet().equals(required)) {
            final Set<String> missing = new HashSet<>(required);
            missing.removeAll(config.keySet());
            final Set<String> unknown = new HashSet<>(config.keySet());
            unknown.removeAll(required);
            throw new IllegalArgumentException("configuration keys mismatch; missing=" + missing
                + ", unknown=" + unknown);
        }
        return cases;
    }

    private static CaseConfig parseCase(final Map<String, String> config, final String prefix) {
        return new CaseConfig(
            config.get(prefix + "id"),
            config.get(prefix + "force_branch"),
            number(config, prefix + "duration_s"),
            number(config, prefix + "output_step_s"),
            number(config, prefix + "integrator_step_s"),
            number(config, prefix + "mu_km3_s2"),
            number(config, prefix + "equatorial_radius_km"),
            number(config, prefix + "j2"),
            vector(config, prefix + "initial_position_km"),
            vector(config, prefix + "initial_velocity_km_s"),
            number(config, prefix + "atmosphere_reference_altitude_km"),
            number(config, prefix + "atmosphere_reference_density_kg_m3"),
            number(config, prefix + "atmosphere_scale_height_km"),
            number(config, prefix + "spacecraft_mass_kg"),
            number(config, prefix + "spacecraft_drag_area_m2"),
            number(config, prefix + "spacecraft_drag_coefficient"),
            number(config, prefix + "earth_rotation_rate_rad_s"));
    }

    private static void validateCase(final CaseConfig config) {
        if (!config.id().matches("[a-z0-9_]+")) {
            throw new IllegalArgumentException("invalid case id: " + config.id());
        }
        if (!Set.of("point_mass_j2_drag", "point_mass_j2_zero_density_drag",
                    "point_mass_zero_j2_drag").contains(config.forceBranch())) {
            throw new IllegalArgumentException("invalid force branch: " + config.forceBranch());
        }
        if (config.durationS() < 3600.0 || config.durationS() > 86400.0
                || config.integratorStepS() < 5.0 || config.integratorStepS() > 30.0
                || config.outputStepS() <= 0.0 || config.spacecraftMassKg() <= 0.0
                || config.spacecraftDragAreaM2() < 0.0
                || config.spacecraftDragCoefficient() < 0.0
                || config.atmosphereReferenceDensityKgM3() < 0.0
                || config.atmosphereScaleHeightKm() <= 0.0) {
            throw new IllegalArgumentException("case outside pinned finite bounds: " + config.id());
        }
        final double altitudeKm = config.initialPositionKm().getNorm()
            - config.equatorialRadiusKm();
        if (altitudeKm < 249.999999 || altitudeKm > 800.000001) {
            throw new IllegalArgumentException("initial altitude outside corpus envelope: "
                + config.id());
        }
        if (config.forceBranch().equals("point_mass_j2_drag")
                && !(config.j2() > 0.0 && config.atmosphereReferenceDensityKgM3() > 0.0)) {
            throw new IllegalArgumentException("combined branch must enable J2 and drag");
        }
        if (config.forceBranch().equals("point_mass_j2_zero_density_drag")
                && !(config.j2() > 0.0 && config.atmosphereReferenceDensityKgM3() == 0.0)) {
            throw new IllegalArgumentException("J2-only branch must use zero density");
        }
        if (config.forceBranch().equals("point_mass_zero_j2_drag")
                && !(config.j2() == 0.0 && config.atmosphereReferenceDensityKgM3() > 0.0)) {
            throw new IllegalArgumentException("drag-only branch must use zero J2");
        }
        stateCount(config);
    }

    private static int stateCount(final CaseConfig config) {
        final double intervals = config.durationS() / config.outputStepS();
        final long rounded = Math.round(intervals);
        if (intervals != rounded || rounded != 24L
                || config.outputStepS() % config.integratorStepS() != 0.0) {
            throw new IllegalArgumentException(
                "each case must contain 25 aligned full-horizon samples: " + config.id());
        }
        return Math.toIntExact(rounded + 1L);
    }

    private static void writeOutput(final Path output, final Map<String, String> sourceConfig,
                                    final String sourceIdentity,
                                    final List<CaseResult> results) throws IOException {
        try (PrintWriter writer = new PrintWriter(
                Files.newBufferedWriter(output, StandardCharsets.UTF_8))) {
            writer.println("{");
            field(writer, 1, "schema", "orekit_j2_drag_envelope_raw.v1", true);
            field(writer, 1, "corpus_id", sourceConfig.get("corpus_id"), true);
            field(writer, 1, "source_identity_sha256", sourceIdentity, true);
            field(writer, 1, "generated_at_utc", sourceConfig.get("generated_at_utc"), true);
            writer.println("  \"tool\": {");
            field(writer, 2, "name", "Apache Orekit", true);
            field(writer, 2, "version", sourceConfig.get("orekit_version"), true);
            field(writer, 2, "java_runtime", System.getProperty("java.runtime.version"), false);
            writer.println("  },");
            writer.println("  \"identity\": {");
            field(writer, 2, "frame", sourceConfig.get("frame"), true);
            field(writer, 2, "epoch", sourceConfig.get("epoch"), true);
            field(writer, 2, "time_scale", sourceConfig.get("time_scale"), true);
            field(writer, 2, "orekit_data_revision", sourceConfig.get("orekit_data_revision"), true);
            field(writer, 2, "eop_source", sourceConfig.get("eop_source"), false);
            writer.println("  },");
            writer.println("  \"model\": {");
            field(writer, 2, "propagator", "NumericalPropagator", true);
            field(writer, 2, "orbit_type", "CARTESIAN", true);
            field(writer, 2, "integrator", sourceConfig.get("integrator"), true);
            field(writer, 2, "gravity", "NewtonianAttraction_plus_J2OnlyPerturbation", true);
            field(writer, 2, "drag",
                "DragForce_plus_SimpleExponentialAtmosphere_plus_IsotropicDrag", true);
            field(writer, 2, "earth_rotation", sourceConfig.get("earth_rotation_model"), false);
            writer.println("  },");
            writer.println("  \"units\": {");
            field(writer, 2, "epoch", "second_since_case_epoch", true);
            field(writer, 2, "position", "meter", true);
            field(writer, 2, "velocity", "meter_per_second", true);
            field(writer, 2, "mu", "kilometer_cubed_per_second_squared", true);
            field(writer, 2, "density", "kilogram_per_cubic_meter", false);
            writer.println("  },");
            writer.println("  \"cases\": [");
            for (int index = 0; index < results.size(); index++) {
                writeCase(writer, results.get(index), index + 1 == results.size());
            }
            writer.println("  ]");
            writer.println("}");
        }
    }

    private static void writeCase(final PrintWriter writer, final CaseResult result,
                                  final boolean lastCase) {
        final CaseConfig config = result.config();
        writer.println("    {");
        field(writer, 3, "id", config.id(), true);
        field(writer, 3, "force_branch", config.forceBranch(), true);
        writer.println("      \"inputs\": {");
        numberField(writer, 4, "duration_s", config.durationS(), true);
        numberField(writer, 4, "output_step_s", config.outputStepS(), true);
        numberField(writer, 4, "integrator_step_s", config.integratorStepS(), true);
        numberField(writer, 4, "mu_km3_s2", config.muKm3S2(), true);
        numberField(writer, 4, "equatorial_radius_km", config.equatorialRadiusKm(), true);
        numberField(writer, 4, "j2", config.j2(), true);
        vectorField(writer, 4, "initial_position_km", config.initialPositionKm(), true);
        vectorField(writer, 4, "initial_velocity_km_s", config.initialVelocityKmS(), true);
        numberField(writer, 4, "atmosphere_reference_altitude_km",
            config.atmosphereReferenceAltitudeKm(), true);
        numberField(writer, 4, "atmosphere_reference_density_kg_m3",
            config.atmosphereReferenceDensityKgM3(), true);
        numberField(writer, 4, "atmosphere_scale_height_km",
            config.atmosphereScaleHeightKm(), true);
        numberField(writer, 4, "spacecraft_mass_kg", config.spacecraftMassKg(), true);
        numberField(writer, 4, "spacecraft_drag_area_m2", config.spacecraftDragAreaM2(), true);
        numberField(writer, 4, "spacecraft_drag_coefficient",
            config.spacecraftDragCoefficient(), true);
        numberField(writer, 4, "earth_rotation_rate_rad_s",
            config.earthRotationRateRadS(), false);
        writer.println("      },");
        writer.println("      \"states\": [");
        for (int index = 0; index < result.states().size(); index++) {
            final StateRow state = result.states().get(index);
            writer.println("        {");
            numberField(writer, 5, "epoch_s", state.epochSeconds(), true);
            vectorField(writer, 5, "position_m", state.position(), true);
            vectorField(writer, 5, "velocity_m_s", state.velocity(), false);
            writer.print("        }");
            writer.println(index + 1 == result.states().size() ? "" : ",");
        }
        writer.println("      ]");
        writer.print("    }");
        writer.println(lastCase ? "" : ",");
    }

    private static void field(final PrintWriter writer, final int indent, final String key,
                              final String value, final boolean comma) {
        writer.print("  ".repeat(indent));
        writer.print("\"");
        writer.print(jsonEscape(key));
        writer.print("\": \"");
        writer.print(jsonEscape(value));
        writer.print("\"");
        writer.println(comma ? "," : "");
    }

    private static void numberField(final PrintWriter writer, final int indent, final String key,
                                    final double value, final boolean comma) {
        writer.print("  ".repeat(indent));
        writer.print("\"");
        writer.print(key);
        writer.print("\": ");
        writer.print(String.format(Locale.ROOT, "%.17e", value));
        writer.println(comma ? "," : "");
    }

    private static void vectorField(final PrintWriter writer, final int indent, final String key,
                                    final Vector3D value, final boolean comma) {
        writer.print("  ".repeat(indent));
        writer.printf(Locale.ROOT, "\"%s\": [%.17e, %.17e, %.17e]%s%n",
            key, value.getX(), value.getY(), value.getZ(), comma ? "," : "");
    }

    private static String jsonEscape(final String value) {
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static void exact(final Map<String, String> config, final String key,
                              final String expected) {
        if (!expected.equals(config.get(key))) {
            throw new IllegalArgumentException(key + " must equal " + expected);
        }
    }

    private static Map<String, String> readStrictProperties(final Path path) throws IOException {
        final Map<String, String> values = new LinkedHashMap<>();
        int lineNumber = 0;
        for (final String line : Files.readAllLines(path, StandardCharsets.UTF_8)) {
            lineNumber++;
            if (line.isBlank()) {
                continue;
            }
            final int separator = line.indexOf('=');
            if (separator <= 0 || separator == line.length() - 1) {
                throw new IllegalArgumentException("malformed configuration line " + lineNumber);
            }
            final String key = line.substring(0, separator);
            final String value = line.substring(separator + 1);
            if (!key.equals(key.trim()) || !value.equals(value.trim())) {
                throw new IllegalArgumentException("configuration whitespace at line " + lineNumber);
            }
            if (values.putIfAbsent(key, value) != null) {
                throw new IllegalArgumentException("duplicate configuration key: " + key);
            }
        }
        return values;
    }

    private static double number(final Map<String, String> config, final String key) {
        final double value = Double.parseDouble(config.get(key));
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException(key + " must be finite");
        }
        return value;
    }

    private static int integer(final Map<String, String> config, final String key) {
        return Integer.parseInt(config.get(key));
    }

    private static Vector3D vector(final Map<String, String> config, final String key) {
        final double[] values = Arrays.stream(config.get(key).split(",", -1))
            .mapToDouble(Double::parseDouble)
            .peek(value -> {
                if (!Double.isFinite(value)) {
                    throw new IllegalArgumentException(key + " must contain finite numbers");
                }
            })
            .toArray();
        if (values.length != 3) {
            throw new IllegalArgumentException(key + " must contain three numbers");
        }
        return new Vector3D(values[0], values[1], values[2]);
    }

    private static String requireSha256(final String value) {
        if (!value.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException("source identity must be lowercase SHA-256");
        }
        return value;
    }

    private record CaseConfig(
        String id,
        String forceBranch,
        double durationS,
        double outputStepS,
        double integratorStepS,
        double muKm3S2,
        double equatorialRadiusKm,
        double j2,
        Vector3D initialPositionKm,
        Vector3D initialVelocityKmS,
        double atmosphereReferenceAltitudeKm,
        double atmosphereReferenceDensityKgM3,
        double atmosphereScaleHeightKm,
        double spacecraftMassKg,
        double spacecraftDragAreaM2,
        double spacecraftDragCoefficient,
        double earthRotationRateRadS
    ) {
    }

    private record StateRow(double epochSeconds, Vector3D position, Vector3D velocity) {
    }

    private record CaseResult(CaseConfig config, List<StateRow> states) {
    }

    private static final class ShiftedTransformProvider implements TransformProvider {
        private final AbsoluteDate epoch;
        private final Transform transformAtEpoch;

        private ShiftedTransformProvider(final AbsoluteDate epoch,
                                         final Transform transformAtEpoch) {
            this.epoch = epoch;
            this.transformAtEpoch = transformAtEpoch;
        }

        @Override
        public Transform getTransform(final AbsoluteDate date) {
            return transformAtEpoch.shiftedBy(date.durationFrom(epoch));
        }

        @Override
        public <T extends CalculusFieldElement<T>> FieldTransform<T> getTransform(
                final FieldAbsoluteDate<T> date) {
            return new FieldTransform<>(date.getField(), getTransform(date.toAbsoluteDate()));
        }
    }
}
