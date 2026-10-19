"""Normalize sixteen complete authored drawings; no body-part reconstruction."""
import json
import shutil
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))
from PIL import Image
spec=json.loads((ROOT/'tools/caster_source.json').read_text(encoding='utf-8'))
out=ROOT/'assets/pencil'
shutil.copy2(spec['source'],out/'sources/enemy_3.png')
source=Image.open(spec['source']).convert('RGBA')
assert source.getchannel('A').getextrema()==(0,255)
w,h=source.size
tiles=[source.crop((round(c*w/4),round(r*h/4),round((c+1)*w/4),round((r+1)*h/4))) for r in range(4) for c in range(4)]
bounds=[tile.getchannel('A').point(lambda v:255 if v>20 else 0).getbbox() for tile in tiles]
assert all(bounds)
factor=min(280/(bounds[0][3]-bounds[0][1]),490/max(tile.width for tile in tiles),390/max(b[3] for b in bounds))
baseline=max(b[3] for b in bounds)
atlas=Image.new('RGBA',(2048,1664))
report=[]
for i,tile in enumerate(tiles):
    resized=tile.resize((round(tile.width*factor),round(tile.height*factor)),Image.Resampling.LANCZOS)
    frame=Image.new('RGBA',(512,416))
    frame.alpha_composite(resized,(round(256-tile.width*factor/2),round(400-baseline*factor)))
    atlas.alpha_composite(frame,(i%4*512,i//4*416))
    report.append({'frame':i,'bounds':frame.getchannel('A').getbbox()})
atlas.save(out/'enemy_3-keys.png')
parts=['[gd_resource type="SpriteFrames" load_steps=18 format=3]','[ext_resource type="Texture2D" path="res://assets/pencil/enemy_3-keys.png" id="atlas"]']
for i in range(16):
    parts.append(f'[sub_resource type="AtlasTexture" id="f{i}"]\natlas = ExtResource("atlas")\nregion = Rect2({i%4*512}, {i//4*416}, 512, 416)')
animations={'idle':([0,1,2,3],[.24]*4,True),'run':([4,5,6,7],[.12]*4,True),'windup':([0,8,9],[.2,.6,.5],False),'attack':([8,9,10,11],[.10,.14,.10,.20],False),'hurt':([12,13,14,15],[.055]*4,False)}
records=[]
for name,(frames,times,loop) in animations.items():
    entries=', '.join('{"duration": %.5f, "texture": SubResource("f%d")}'%(t,i) for i,t in zip(frames,times))
    records.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": 1.0}'%(entries,str(loop).lower(),name))
parts.append('[resource]\nanimations = [\n'+',\n'.join(records)+'\n]')
(out/'enemy_3.tres').write_text('\n\n'.join(parts)+'\n',encoding='utf-8')
spec.update({'original_size':source.size,'runtime_cell':[512,416],'pivot':[256,400],'preparation':'Fixed 4x4 grid, one common scale and baseline, alpha preserved; whole figures only.','frames':report})
(out/'enemy_3-provenance.json').write_text(json.dumps(spec,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('CASTER: 16 complete drawings normalized, 5 native animations.')
