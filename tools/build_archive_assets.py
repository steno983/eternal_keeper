"""Keep generated originals and slice equal comic gutters; no painted postprocessing."""
from pathlib import Path
import json, shutil, sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))
from PIL import Image
OUT=ROOT/'assets/archive'
(OUT/'sources').mkdir(parents=True,exist_ok=True)
(OUT/'sources'/'.gdignore').touch()
spec=json.loads((ROOT/'tools/archive_sources.json').read_text(encoding='utf-8-sig'))
report={}
for key,entry in spec.items():
    source=OUT/'sources'/f'{key}.png'
    if Path(entry['source']).exists(): shutil.copy2(entry['source'],source)
    shutil.copy2(source,OUT/f'{key}.png')
    im=Image.open(source).convert('RGB')
    width,height=im.size
    if key in ('temple','daleal','inn'):
        pixels=im.load()
        cuts=[]
        for low,high in ((.29,.38),(.62,.72)):
            scores=[(sum(sum(pixels[x,y])<260 for y in range(12,height-12,2)),x) for x in range(int(width*low),int(width*high))]
            peak=max(n for n,x in scores)
            candidates=[x for n,x in scores if n>=peak*.97]
            cuts.append(candidates[len(candidates)//2])
        edges=[4,*cuts,width-4]
        for i in range(3): im.crop((edges[i]+4,4,edges[i+1]-4,height-4)).save(OUT/f'{key}-panel-{i+1}.png')
        report[key]={'size':im.size,'gutters':cuts}
    else: report[key]={'size':im.size}
(OUT/'provenance.json').write_text(json.dumps({'tool':'built-in imagegen','reference':'assets/interludes/bridge-comic-1.png (character identity and drawing style)','preparation':'Originals preserved. Triptychs cropped at actual ink gutters. No character repaints or interpolation.','assets':spec},ensure_ascii=False,indent=2),encoding='utf-8')
(OUT/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
