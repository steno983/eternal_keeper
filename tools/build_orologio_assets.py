"""Preserve generated sources, slice comic gutters and normalize authored atlas regions."""
import json
import shutil
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/python'))
from PIL import Image

OUT = ROOT / 'assets/orologio'
spec = json.loads((ROOT / 'tools/orologio_sources.json').read_text(encoding='utf-8'))
(OUT / 'sources').mkdir(parents=True, exist_ok=True)
(OUT / 'sources/.gdignore').touch()
report = {}
for key, entry in spec.items():
    source = OUT / 'sources' / f'{key}.png'
    shutil.copy2(entry['source'], source)
    image = Image.open(source)
    w, h = image.size
    report[key] = {'size': [w, h], 'mode': image.mode}
    if key in ('comic_entry', 'comic_end'):
        rgb = image.convert('RGB')
        pixels = rgb.load()
        cuts = []
        for low, high in ((.29, .38), (.62, .72)):
            scores = [(sum(sum(pixels[x, y]) < 260 for y in range(12, h-12, 2)), x) for x in range(int(w*low), int(w*high))]
            peak = max(n for n, x in scores)
            candidates = [x for n, x in scores if n >= peak*.97]
            cuts.append(candidates[len(candidates)//2])
        edges = [4, *cuts, w-4]
        for index in range(3):
            image.crop((edges[index]+4, 4, edges[index+1]-4, h-4)).save(OUT / f'{key}-panel-{index+1}.png')
        report[key]['gutters'] = cuts
    elif key == 'terrain':
        box = [0, round(h*.61), w, round(h*.988)]
        image.crop(tuple(box)).save(OUT / 'floor.png')
        report[key]['floor_crop'] = box
    elif key == 'pillar':
        assert image.mode == 'RGBA', 'Parallax pillar must have real alpha'
        alpha = image.getchannel('A')
        assert alpha.getextrema() == (0, 255), 'Pillar requires opaque drawing and transparent exterior'
        report[key]['alpha_extrema'] = list(alpha.getextrema())
        box = image.getchannel('A').point(lambda value: 255 if value > 8 else 0).getbbox()
        cropped = image.crop(box)
        cropped.save(OUT / f'{key}.png')
        report[key]['alpha_crop'] = list(box)
        report[key]['runtime_size'] = list(cropped.size)
    elif key == 'floor':
        image.save(OUT / 'floor.png')
    else:
        shutil.copy2(source, OUT / f'{key}.png')

pillar_size = report['pillar']['runtime_size']
for name, plate in [('orologio_discesa', 'descent'), ('orologio_sigillo', 'seal'), ('orologio_camera', 'chamber')]:
    layers = [
        {'kind': 'texture', 'texture': f'res://assets/orologio/{plate}.png', 'depth': .12, 'rect': [-200, -145, 2240, 1035], 'alpha': .66},
        {'kind': 'pillars', 'texture': 'res://assets/orologio/pillar.png', 'depth': .48, 'anchors': [-240, 780, 1800], 'region': [0, 0, *pillar_size], 'rect': [0, -20, 155, 620], 'alpha': .43},
        {'kind': 'tiles', 'texture': 'res://assets/orologio/floor.png', 'depth': 1.0, 'rect': [0, 432, 1024, 342], 'tiles': [-1, 4]},
        {'kind': 'pillars', 'texture': 'res://assets/orologio/pillar.png', 'depth': 1.22, 'anchors': [-10, 1580], 'region': [0, 0, *pillar_size], 'rect': [0, -145, 245, 980], 'alpha': .96, 'foreground': True}
    ]
    for layer in layers:
        if layer['kind'] == 'texture': layer['repeat_x'] = True
        elif layer['kind'] == 'pillars': layer['repeat_step'] = 2400 if layer.get('foreground') else 1800
    environment = {'schema_version': 1, 'id': name, 'shader': 'res://assets/archive/graphite.gdshader', 'layers': layers}
    (ROOT / f'data/ambienti/{name}.json').write_text(json.dumps(environment, indent=2)+'\n', encoding='utf-8')

(OUT / 'report.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
(OUT / 'provenance.json').write_text(json.dumps({
    'tool': 'built-in imagegen',
    'source_report': "docs/sessioni/D&D i Custodi dell'Eterno - Sessione 2.pdf, page 6, report 217-A",
    'preparation': 'Generated originals preserved. Comic panels cropped at measured ink gutters; pillar cropped to its alpha silhouette without repainting. The atlas floor was superseded by a separately generated foreshortened floor after native-scale visual QA. No procedural replacement of generated art.',
    'references': ['assets/interludes/bridge-comic-1.png for protagonist identity and drawing style only'],
    'assets': spec,
    'parallax': {'background': .12, 'architecture': .48, 'floor': 1.0, 'foreground': 1.22}
}, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report))
