"""Preserve generated source art and split actual ink gutters into panel textures."""
from pathlib import Path
import json,shutil,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'.tools/python'))
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/interludes'
(OUT/'sources').mkdir(parents=True,exist_ok=True)
spec=json.loads((ROOT/'tools/interlude_sources.json').read_text(encoding='utf-8-sig'))
report={}
for key,entry in spec.items():
 source=OUT/'sources'/f'{key}.png'
 if Path(entry['source']).exists():shutil.copy2(entry['source'],source)
 im=Image.open(source).convert('RGB')
 target=OUT/f'bridge-{key}.png'
 shutil.copy2(source,target)
 if key.startswith('comic'):
  width,height=im.size
  pixels=im.load()
  cuts=[]
  for low,high in [(0.28,0.40),(0.61,0.75)]:
   scores=[]
   for x in range(int(width*low),int(width*high)):
    count=sum(sum(pixels[x,y])<260 for y in range(12,height-12,2))
    scores.append((count,x))
   peak=max(count for count,x in scores)
   candidates=[x for count,x in scores if count>=peak*0.97]
   cuts.append(candidates[len(candidates)//2])
  edges=[4,*cuts,width-4]
  panels=[]
  for i in range(3):
   box=(edges[i]+4,4,edges[i+1]-4,height-4)
   assert box[2]>box[0]+width*0.20
   im.crop(box).save(OUT/f'bridge-{key}-panel-{i+1}.png')
   panels.append(box)
  report[key]={'size':im.size,'gutters':cuts,'panels':panels}
 else:report[key]={'size':im.size}
(OUT/'provenance.json').write_text(json.dumps({'tool':'built-in imagegen','reference':'artifacts/run-title.png: characters, bridge and pencil direction only','preparation':'original full scenes retained; comic panels sliced at their ink gutters without painting or generative postprocessing','assets':spec},indent=2),encoding='utf-8')
(OUT/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
