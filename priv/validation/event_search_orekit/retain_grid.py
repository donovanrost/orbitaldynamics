"""Retain exact 10-second anchors; never interpolate or compute reference values."""
import json
import sys
from pathlib import Path

raw = json.loads(Path(sys.argv[1]).read_text())
assert raw['model']['integrator_step_s'] == 2.5
raw['states'] = [s for s in raw['states'] if s['epoch_s'] % 10 == 0]
assert len(raw['states']) == 2161
raw['retained_state_grid_s'] = 10
Path(sys.argv[2]).write_text(json.dumps(raw, separators=(',', ':')) + '\n')
