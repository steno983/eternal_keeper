"""Slice generated sheets, align pivots and preserve authored startup-frame growth."""
from pathlib import Path
import sys, json, shutil, statistics
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'.tools/python'))
from PIL import Image, ImageOps
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/magic'
OUT.mkdir(exist_ok=True)
(OUT/'sources').mkdir(exist_ok=True)
spec=json.loads((ROOT/'tools/magic_sources.json').read_text(encoding='utf-8'))
report={}
for key,entry in spec.items():
 source=OUT/'sources'/f'{key}.png'
 if Path(entry['source']).exists(): shutil.copy2(entry['source'],source)
 im=Image.open(source).convert('RGBA')
 if key=='icons':
  for i in range(4):
   cell=im.crop((round((i%2)*im.width/2),round((i//2)*im.height/2),round((i%2+1)*im.width/2),round((i//2+1)*im.height/2)))
   bbox=cell.getchannel('A').point(lambda a:255 if a>35 else 0).getbbox()
   cell=cell.crop(bbox)
   cell.thumbnail((112,112),Image.Resampling.LANCZOS)
   tile=Image.new('RGBA',(128,128))
   tile.alpha_composite(cell,((128-cell.width)//2,(128-cell.height)//2))
   tile.save(OUT/f'icon-{i}.png')
   grey=ImageOps.grayscale(tile).convert('RGBA')
   grey.putalpha(tile.getchannel('A'))
   grey.save(OUT/f'icon-{i}-grey.png')
  continue
 cells=[]
 boxes=[]
 for i in range(8):
  cell=im.crop((round(i%4*im.width/4),round(i//4*im.height/2),round((i%4+1)*im.width/4),round((i//4+1)*im.height/2)))
  box=cell.getchannel('A').point(lambda a:255 if a>70 else 0).getbbox()
  assert box, (key,i,'empty frame')
  cells.append(cell); boxes.append(box)
 size=(384,256) if key=='projectile' else (384,512)
 atlas=Image.new('RGBA',(size[0]*4,size[1]*2))
 if key=='projectile':
  ref_width=max(b[2]-b[0] for b in boxes)
  sx=344/ref_width; sy=sx
 elif key=='impact':
  sx=336/max(b[2]-b[0] for b in boxes)
  sy=424/max(b[3]-b[1] for b in boxes)
 else:
  ref=boxes[6:] if key.endswith('_birth') else boxes
  height=statistics.median(b[3]-b[1] for b in ref)
  sy=440/height
  sx=332/max(b[2]-b[0] for b in boxes)
 frame_heights=[]
 for i,(cell,box) in enumerate(zip(cells,boxes)):
  rendered=cell.resize((round(cell.width*sx),round(cell.height*sy)),Image.Resampling.LANCZOS)
  if key=='projectile':
   dx=round(354-box[2]*sx)
   dy=round(128-(box[1]+box[3])*0.5*sy)
  elif key=='impact':
   dx=round(192-(box[0]+box[2])*0.5*sx)
   dy=round(256-(box[1]+box[3])*0.5*sy)
  else:
   # Detect the broad grounded foot, ignoring loose droplets below it.
   alpha=cell.getchannel('A')
   foot=box[3]
   for y in range(cell.height-1,cell.height//2,-1):
    count=sum(a>90 for a in list(alpha.crop((0,y,cell.width,y+1)).getdata()))
    if count>cell.width*0.30:
     foot=y+1; break
   dx=round(192-(box[0]+box[2])*0.5*sx)
   dy=round(480-foot*sy)
  tile=Image.new('RGBA',size)
  tile.alpha_composite(rendered,(dx,dy))
  bbox=tile.getchannel('A').point(lambda a:255 if a>70 else 0).getbbox()
  frame_heights.append(bbox[3]-bbox[1])
  atlas.alpha_composite(tile,((i%4)*size[0],(i//4)*size[1]))
 atlas.save(OUT/f'{key}.png')
 report[key]={'frames':8,'cell_size':size,'heights':frame_heights,'pivot':[0.922,0.5] if key=='projectile' else [0.5,0.5] if key=='impact' else [0.5,0.9375]}
 if key.endswith('_birth'): assert frame_heights[0]<frame_heights[-1]*0.35, (key,'startup must grow from ground')
(OUT/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(OUT/'provenance.json').write_text(json.dumps({'tool':'built-in imagegen','normalization':'grid slicing, fixed canvas, foot pivots, constant scale per clip, preserved alpha; grayscale UI variants','assets':spec},indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
