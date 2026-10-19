from PIL import Image,ImageDraw
from pathlib import Path
out=Path('assets/animation_v4')
im=Image.new('RGB',(1200,680),(240,240,240));d=ImageDraw.Draw(im)
near=[[(155,150),(200,195),(230,250)],[(155,150),(155,200),(135,250)],[(155,150),(115,190),(75,245)],[(155,150),(100,175),(110,135)],[(155,150),(100,200),(75,250)],[(155,150),(190,170),(175,210)],[(155,150),(205,160),(220,205)],[(155,150),(220,195),(255,240)]]
far=[[(145,150),(100,190),(75,240)],[(145,150),(185,165),(175,210)],[(145,150),(195,155),(205,205)],[(145,150),(210,200),(250,240)],[(145,150),(200,195),(230,250)],[(145,150),(155,200),(135,250)],[(145,150),(115,190),(75,245)],[(145,150),(100,175),(110,135)]]
for i in range(8):
 x=i%4*300;y=i//4*340
 def p(coords):return [(x+a,y+b) for a,b in coords]
 d.rectangle((x,y,x+299,y+339),outline=(150,150,150));d.line(p([(20,265),(280,265)]),fill=(140,140,140),width=2)
 d.text((x+12,y+12),str(i+1)+' - facing RIGHT',fill=(20,20,20))
 d.ellipse((x+143,y+45,x+183,y+85),outline=(60,60,60),width=4)
 d.line(p([(163,85),(150,150)]),fill=(60,60,60),width=8)
 for coords,c in [(far[i],(170,30,130)),(near[i],(0,130,180))]:
  d.line(p(coords),fill=c,width=13)
  for a,b in p(coords):d.ellipse((a-8,b-8,a+8,b+8),fill=c)
  a,b=coords[-1];d.line(p([(a-5,b),(a+17,b)]),fill=c,width=9)
 d.text((x+10,y+285),'CYAN = NEAR leg, continuous identity',fill=(0,100,160))
 d.text((x+10,y+305),'MAGENTA = FAR leg, continuous identity',fill=(150,30,120))
im.save(out/'gait-pose-guide.png')
