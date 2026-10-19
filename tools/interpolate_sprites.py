"""Offline motion-aware inbetweening with RIFE 4.9, including warped alpha.

The neural network's same grids and occlusion mask warp color and alpha.
Large displacements can still produce ghosting; see docs/animation-v3.md.
Use the bundled Python 3.12 runtime; packages live in .tools/interpolation.
"""
from pathlib import Path
import sys, json, time, hashlib, argparse
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/interpolation'))
import numpy as np
import onnx
from onnx import helper, TensorProto
import onnxruntime as ort
from PIL import Image, ImageDraw

SOURCE=ROOT/'assets/animation_v2'
OUTPUT=ROOT/'assets/animation_v3'
TEMP=ROOT/'.tools/inbetween-cache'
SIZE=(384,320)

def rgba_model():
    target=ROOT/'.tools/models/rife49-rgba.onnx'
    if target.exists():return target
    model=onnx.load(ROOT/'.tools/models/rife49.onnx')
    nodes={n.name:n for n in model.graph.node}
    grid0=nodes['/GridSample_14'];grid1=nodes['/GridSample_15']
    for name in ['alpha0','alpha1']:
        model.graph.input.append(helper.make_tensor_value_info(name,TensorProto.FLOAT,[1,1,'height','width']))
    for i,node in enumerate([grid0,grid1]):
        attrs={a.name:helper.get_attribute_value(a) for a in node.attribute}
        model.graph.node.append(helper.make_node('GridSample',[f'alpha{i}',node.input[1]],[f'alpha_warp{i}'],name=f'AlphaWarp{i}',**attrs))
    model.graph.node.extend([
      helper.make_node('Mul',['alpha_warp0','/Sigmoid_output_0'],['alpha_mix0']),
      helper.make_node('Mul',['alpha_warp1','/Sub_17_output_0'],['alpha_mix1']),
      helper.make_node('Add',['alpha_mix0','alpha_mix1'],['alpha'])])
    model.graph.output.append(helper.make_tensor_value_info('alpha',TensorProto.FLOAT,[1,1,'height','width']))
    onnx.checker.check_model(model)
    onnx.save(model,target)
    return target

class Interpolator:
    def __init__(self):
        options=ort.SessionOptions()
        options.enable_mem_pattern=False
        options.execution_mode=ort.ExecutionMode.ORT_SEQUENTIAL
        options.intra_op_num_threads=4
        self.session=ort.InferenceSession(str(rgba_model()),sess_options=options,providers=['DmlExecutionProvider','CPUExecutionProvider'])
        print('RIFE providers:',self.session.get_providers(),flush=True)
        self.created=0
        TEMP.mkdir(parents=True,exist_ok=True)

    def between(self,a,b,t):
        digest=hashlib.sha256(a.tobytes()+b.tobytes()+f'{t:.5f}'.encode()).hexdigest()
        cached=TEMP/f'{digest}.png'
        if cached.exists():return Image.open(cached).convert('RGBA')
        a0=np.asarray(a,dtype=np.float32)/255
        a1=np.asarray(b,dtype=np.float32)/255
        inputs={
          'img0':np.ascontiguousarray((a0[:,:,:3]*a0[:,:,3:4]).transpose(2,0,1)[None]),
          'img1':np.ascontiguousarray((a1[:,:,:3]*a1[:,:,3:4]).transpose(2,0,1)[None]),
          'alpha0':np.ascontiguousarray(a0[:,:,3][None,None]),
          'alpha1':np.ascontiguousarray(a1[:,:,3][None,None]),
          'timestep':np.asarray([t],dtype=np.float32)}
        color,alpha=self.session.run(['output','alpha'],inputs)
        color=np.clip(color[0].transpose(1,2,0),0,1)
        alpha=np.clip(alpha[0,0],0,1)
        straight=np.clip(color/np.maximum(alpha[:,:,None],1/255),0,1)
        rgba=np.concatenate([straight,alpha[:,:,None]],axis=2)
        rgba[alpha<.007]=0
        image=Image.fromarray(np.rint(rgba*255).astype(np.uint8),'RGBA')
        image.save(cached)
        self.created+=1
        return image

def load_frames(key):
    source=Image.open(SOURCE/f'{key}-atlas.png').convert('RGBA')
    count=24 if key.startswith('hero') else 12 if key=='enemy_1' else 16
    frames=[source.crop((i%4*384,i//4*320,i%4*384+384,i//4*320+320)) for i in range(count)]
    return frames

def source_clips(key):
    hero=key.startswith('hero');index=int(key[-1])
    if hero:
        attack_length=[.48,.36,.42][index];ranged_length=[.42,.30,.34][index]
        return {
          'idle':(list(range(4)),[.23]*4,True),
          'run':(list(range(4,12)),[.065]*8,True),
          'attack':(list(range(12,20)),[w*attack_length for w in [.12,.12,.10,.08,.13,.12,.16,.17]],False),
          'ranged':(list(range(20,24)),[w*ranged_length for w in [.22,.24,.19,.35]],False),
          'special':([20,21,22,23],[.10,.10,.15,.15],False),
          'guard':([20,21,20],[.36,.12,.36],True) if index==0 else ([0,1],[.3,.3],True),
          'hurt':([17,18],[.11,.11],False),
          'dodge':([7,8,9],[.06,.07,.06],False)}
    run=list(range(2,8)) if index==1 else list(range(2,10))
    attack=list(range(8,12)) if index==1 else list(range(10,16))
    durations=[.12,.12,.10,.18] if index==1 else [.09,.09,.07,.07,.10,.12]
    return {'idle':([0,1],[.34,.34],True),'run':(run,[.1]*len(run),True),
      'attack':(attack,durations,False),'ranged':(attack,durations,False),
      'windup':([attack[0],attack[1]],[.35,.35],False),'hurt':([attack[-2],attack[-1]],[.10,.12],False)}

def dense_clip(engine,frames,ids,durations,loop,steps):
    images=[];times=[]
    for i,(index,duration) in enumerate(zip(ids,durations)):
        start=frames[index]
        end=frames[ids[(i+1)%len(ids)]] if loop or i<len(ids)-1 else frames[0]
        for sub in range(steps):
            images.append(start.copy() if sub==0 else engine.between(start,end,sub/steps))
            times.append(duration/steps)
    return images,times

def save_resource(key,clips):
    # Separate strip atlases keep texture dimensions modest and imports inspectable.
    subresources=[];entries=[];external=[];resource_id=0
    for clip,(images,times,loop) in clips.items():
        cols=8;rows=(len(images)+cols-1)//cols
        atlas=Image.new('RGBA',(384*cols,320*rows))
        for i,img in enumerate(images):atlas.alpha_composite(img,(i%cols*384,i//cols*320))
        file=f'{key}-{clip}.png';atlas.save(OUTPUT/file)
        external.append(f'[ext_resource type="Texture2D" path="res://assets/animation_v3/{file}" id="{clip}"]')
        data=[]
        for i,seconds in enumerate(times):
            resource_id+=1;rid=f'f{resource_id}'
            subresources.append(f'[sub_resource type="AtlasTexture" id="{rid}"]\natlas = ExtResource("{clip}")\nregion = Rect2({i%cols*384}, {i//cols*320}, 384, 320)')
            data.append('{"duration": %.9f, "texture": SubResource("%s")}' % (seconds,rid))
        entries.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": 1.0}'%(', '.join(data),str(loop).lower(),clip))
    text=f'[gd_resource type="SpriteFrames" load_steps={1+len(external)+resource_id} format=3]\n\n'
    text+='\n\n'.join(external+subresources)+'\n\n[resource]\nanimations = [\n'+',\n'.join(entries)+'\n]\n'
    (OUTPUT/f'{key}.tres').write_text(text,encoding='utf8')

def preview(key,clip,old,new,times,old_times):
    # Equal-duration before/after playback, with the old side sampled at its own
    # original timestamps. No skipped frames or slowed-down comparison.
    palette=None;images=[];fps=60;duration=sum(times)
    for n in range(round(duration*fps)):
        t=n/fps
        def at(seq,durations):
            cursor=t
            for im,sec in zip(seq,durations):
                if cursor<sec:return im
                cursor-=sec
            return seq[-1]
        bg=Image.new('RGB',(768,350),(20,35,44));d=ImageDraw.Draw(bg)
        d.text((20,10),'PRIMA - pose distanti',fill=(225,190,135));d.text((404,10),'DOPO - intermedi RIFE',fill=(125,215,210))
        for x,im in [(0,at(old,old_times)),(384,at(new,times))]:bg.paste(im,(x,24),im)
        images.append(bg)
    path=ROOT/f'artifacts/{key}-{clip}-motion-comparison.gif'
    path.parent.mkdir(exist_ok=True)
    # GIF centisecond timestamps cannot represent 60 Hz exactly. Alternate 10/20ms.
    delays=[20 if n%3!=0 else 10 for n in range(len(images))]
    images[0].save(path,save_all=True,append_images=images[1:],duration=delays,loop=0,disposal=2)

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--probe',action='store_true');parser.add_argument('--keys',nargs='*');parser.add_argument('--steps',type=int,default=4)
    args=parser.parse_args();OUTPUT.mkdir(parents=True,exist_ok=True)
    engine=Interpolator();report={};started=time.time()
    keys=args.keys or (['hero_0'] if args.probe else [f'{k}_{i}' for k in ['hero','enemy'] for i in range(3)])
    for key in keys:
        frames=load_frames(key);clips={}
        for clip,(ids,durations,loop) in source_clips(key).items():
            if args.probe and clip not in ['run','attack']:continue
            images,times=dense_clip(engine,frames,ids,durations,loop,args.steps)
            clips[clip]=(images,times,loop)
            if key=='hero_0' and clip in ['run','attack']:
                preview(key,clip,[frames[i] for i in ids],images,times,durations)
            print(f'{key}/{clip}: {len(ids)} -> {len(images)} frames, {sum(times):.3f}s, elapsed {time.time()-started:.1f}s',flush=True)
        save_resource(key,clips)
        report[key]={name:{'frames':len(images),'seconds':sum(times),'loop':loop} for name,(images,times,loop) in clips.items()}
    (OUTPUT/'qa-probe.json' if args.probe else OUTPUT/'qa.json').write_text(json.dumps(report,indent=2),encoding='utf8')
    print(f'RIFE inference done: {engine.created} new intermediates, {time.time()-started:.1f}s',flush=True)

if __name__=='__main__':main()
