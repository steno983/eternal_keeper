"""Corrupt disposable copies, never the project's live content."""
import importlib.util
import json
import shutil
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('mission_validator', ROOT / 'tools/check_missions.py')
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class MissionValidation(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="mission-validation-", dir=ROOT / "tmp")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        shutil.copytree(ROOT / 'data', self.root / 'data')
        # The validator checks resource existence, not raster decoding/import.
        # Populate resource paths only; no large art copies are necessary.
        for source in (self.root / 'data').rglob('*.json'):
            def resources(value):
                if isinstance(value, dict):
                    for child in value.values(): resources(child)
                elif isinstance(value, list):
                    for child in value: resources(child)
                elif isinstance(value, str) and value.startswith('res://'):
                    target = self.root / value[6:]
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.touch()
            resources(json.loads(source.read_text(encoding='utf-8-sig')))

    def change(self, path, edit):
        target = self.root / path
        data = json.loads(target.read_text(encoding='utf-8-sig'))
        edit(data)
        target.write_text(json.dumps(data), encoding='utf-8')

    def rejected(self, fragment):
        errors = validator.validate(self.root)
        self.assertTrue(any(fragment in error for error in errors), errors)

    def test_valid_content(self):
        self.assertEqual(validator.validate(self.root), [])

    def test_missing_duration(self):
        self.change('data/stage/archivio_passaggio.json', lambda d: d.pop('duration'))
        self.rejected('duration')

    def test_missing_comic(self):
        self.change('data/stage/archivio_scale.json', lambda d: d['interludes']['after'].append('inesistente'))
        self.rejected('intermezzo inesistente')

    def test_missing_image(self):
        self.change('data/ambienti/archivio.json', lambda d: d['layers'][0].update(texture='res://assets/inesistente.png'))
        self.rejected('risorsa mancante')

    def test_invalid_lane(self):
        self.change('data/stage/archivio_passaggio.json', lambda d: d['waves'][0]['entries'][0].update(lane=9))
        self.rejected('side/lane/archetype')

    def test_unknown_type(self):
        self.change('data/stage/archivio_scale.json', lambda d: d.update(type='boss_magico'))
        self.rejected('tipo non supportato')

    def test_unknown_level(self):
        self.change('data/missioni/archivio.json', lambda d: d['levels'].append('inesistente'))
        self.rejected('inesistente.json')

    def test_unknown_stage(self):
        self.change('data/livelli/fuga_archivio.json', lambda d: d['stages'].append('inesistente'))
        self.rejected('data/stage/inesistente.json')

    def test_empty_level(self):
        self.change('data/livelli/fuga_archivio.json', lambda d: d.update(stages=[]))
        self.rejected('stages deve contenere')

    def test_late_spawn(self):
        self.change('data/stage/archivio_passaggio.json', lambda d: d['waves'][-1].update(at=25))
        self.rejected('dopo la fine')

    def test_invalid_entrance_duration(self):
        self.change('data/missioni/archivio.json', lambda d: d.update(entrance={'style': 'pencil', 'erase': 0}))
        self.rejected('entrance.erase')

    def test_unknown_entrance_style(self):
        self.change('data/livelli/fuga_archivio.json', lambda d: d.update(entrance={'style': 'inesistente'}))
        self.rejected('style:')


if __name__ == '__main__':
    unittest.main()
