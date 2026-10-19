"""Slice the authored 3x2 transition comic into two native three-panel pages."""
import json
import shutil
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))
from PIL import Image
spec=json.loads((ROOT/'tools/route_comics_source.json').read_text(encoding='utf-8'))
out=ROOT/'assets/orologio'
shutil.copy2(spec['source'],out/'sources/route-comics.png')
image=Image.open(spec['source'])
w,h=image.size
pixels=image.convert('RGB').load()
cuts=[]
for low,high in [(.29,.38),(.62,.72)]:
    scores=[(sum(sum(pixels[x,y])<260 for y in range(10,h-10,3)),x) for x in range(int(w*low),int(w*high))]
    peak=max(n for n,x in scores)
    candidates=[x for n,x in scores if n>=peak*.97]
    cuts.append(candidates[len(candidates)//2])
scores=[(sum(sum(pixels[x,y])<260 for x in range(10,w-10,3)),y) for y in range(int(h*.43),int(h*.57))]
peak=max(n for n,y in scores)
candidates=[y for n,y in scores if n>=peak*.97]
middle=candidates[len(candidates)//2]
xs=[0,*cuts,w]
ys=[0,middle,h]
for row,name in enumerate(['seal','chamber']):
    for column in range(3):
        image.crop((xs[column]+4,ys[row]+4,xs[column+1]-4,ys[row+1]-4)).save(out/f'route-{name}-panel-{column+1}.png')
spec.update(size=[w,h],gutters={'x':cuts,'y':middle},preparation='Six complete drawn panels cropped at measured 3x2 gutters, no repaint.')
(out/'route-comics-provenance.json').write_text(json.dumps(spec,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('ROUTE COMICS: six panels, two manual pages.')
