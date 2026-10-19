"""Slice the dwarf/elf rig kits; preserve generated sources and alpha."""
from pathlib import Path
import sys,json,argparse
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))
from PIL import Image,ImageDraw
from build_sprite_frames import subjects

BASE=['head','torso','pelvis','ponytail','upper_arm','forearm','hand_blade','cape','thigh','shin','boot','scarf']
ALIASES={'tholgrin':{'ponytail':'shield','hand_blade':'mace_hand','scarf':'shield_hand'},
         'lupinor':{'ponytail':'hair','hand_blade':'scimitar_hand','scarf':'crossbow_hand'}}

def build(hero):
    folder=ROOT/f'assets/{hero}_skin'
    source=Image.open(folder/'parts-source.png').convert('RGBA')
    assert source.getchannel('A').getextrema()[0]==0, f'{hero}: source must have transparent alpha'
    groups,_=subjects(source,3)
    assert [len(row) for row in groups]==[4,4,4], (hero,[len(row) for row in groups])
    tiles=[tile for row in groups for tile in row]
    preview=Image.new('RGB',(1024,768),(26,39,49));draw=ImageDraw.Draw(preview)
    report={}
    for index,(slot,tile) in enumerate(zip(BASE,tiles)):
        name=ALIASES[hero].get(slot,slot)
        bound=tile.getchannel('A').point(lambda p:255 if p>20 else 0).getbbox()
        assert bound, (hero,name)
        crop=tile.crop(bound)
        crop.thumbnail((256,256),Image.Resampling.LANCZOS)
        crop.save(folder/f'{name}.png')
        report[name]={'slot':slot,'size':crop.size,'alpha':crop.getchannel('A').getextrema()}
        thumb=crop.copy();thumb.thumbnail((230,210))
        col,row=index%4,index//4
        preview.paste(thumb,(col*256+(256-thumb.width)//2,row*256+20+(210-thumb.height)//2),thumb)
        draw.text((col*256+15,row*256+235),name,fill=(219,196,155))
    preview.save(ROOT/f'artifacts/{hero}-skin-parts.png')
    (folder/'qa.json').write_text(json.dumps(report,indent=2))
    print(f'{hero}: twelve complete isolated parts; alpha verified')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('heroes',nargs='*',default=['tholgrin','lupinor'])
    for hero in parser.parse_args().heroes:build(hero)
