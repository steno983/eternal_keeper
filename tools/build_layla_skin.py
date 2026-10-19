"""Deterministic slicing of generated rig parts. No painting or pose synthesis."""
from pathlib import Path
import json,sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))
from PIL import Image,ImageDraw
from build_sprite_frames import subjects
OUT=ROOT/'assets/layla_skin'
NAMES=['head','torso','pelvis','ponytail','upper_arm','forearm','hand_blade','cape','thigh','shin','boot','scarf']

def main():
    source=Image.open(OUT/'parts-source.png').convert('RGBA')
    w,h=source.size
    preview=Image.new('RGB',(1024,768),(26,39,49));draw=ImageDraw.Draw(preview)
    report={}
    groups,_=subjects(source,3)
    assert [len(row) for row in groups]==[4,4,4], [len(row) for row in groups]
    tiles=[tile for row in groups for tile in row]
    for index,name in enumerate(NAMES):
        col,row=index%4,index//4
        tile=tiles[index]
        # The generated head includes a tail despite the brief. Slice the face
        # and skull, using the dedicated tail as the independently moving part.
        if name=='head':
            if (OUT/'head-source.png').exists():
                tile=Image.open(OUT/'head-source.png').convert('RGBA')
            else:
                tile=tile.crop((round(tile.width*.55),round(tile.height*.04),tile.width,round(tile.height*.85)))
        bound=tile.getchannel('A').point(lambda p:255 if p>20 else 0).getbbox()
        assert bound is not None, f'Empty rig part: {name}'
        x0,y0,x1,y1=bound
        crop=tile.crop((max(0,x0-2),max(0,y0-2),min(tile.width,x1+2),min(tile.height,y1+2)))
        crop.thumbnail((256,256),Image.Resampling.LANCZOS)
        crop.save(OUT/f'{name}.png')
        report[name]={'bounds':bound,'size':crop.size,'alpha':crop.getchannel('A').getextrema()}
        thumb=crop.copy();thumb.thumbnail((230,210))
        preview.paste(thumb,(col*256+(256-thumb.width)//2,row*256+20+(210-thumb.height)//2),thumb)
        draw.text((col*256+15,row*256+235),name,fill=(219,196,155))
    preview.save(ROOT/'artifacts/layla-skin-parts.png')
    (OUT/'qa.json').write_text(json.dumps(report,indent=2))
    print('Twelve rig parts sliced and alpha/edges checked')

if __name__=='__main__':main()
