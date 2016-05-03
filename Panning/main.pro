@paths.pro
RESTORE, PATH_TO_LOAD_MS
sizes = SIZE(MS) ;[N_DIM,DIM1,DIM2,DIM3,..,N_ELEM]
PANIMAGE4 = INTARR(sizes(1),sizes(2),sizes(3)) 
PANIMAGE4(*,*,0) = IM1CROPPAN
PANIMAGE4(*,*,1) = IM1CROPPAN
PANIMAGE4(*,*,2) = IM1CROPPAN
PANIMAGE4(*,*,3) = IM1CROPPAN
N = 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Histogram Matching ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;M1_HIST =  histogram(MS(*,*,0), NBINS=256)
;M2_HIST =  histogram(MS(*,*,1), NBINS=256)
;M3_HIST =  histogram(MS(*,*,2), NBINS=256)
;M4_HIST =  histogram(MS(*,*,3), NBINS=256)
;PANIMAGERIC_H = INTARR(sizes(1),sizes(2), sizes(3))
;
;PANIMAGERIC_H(*,*,0) = histomatch(PANIMAGERIC(*,*,0), M1_HIST)
;PANIMAGERIC_H(*,*,1) = histomatch(PANIMAGERIC(*,*,1), M2_HIST)
;PANIMAGERIC_H(*,*,2) = histomatch(PANIMAGERIC(*,*,2), M3_HIST)
;PANIMAGERIC_H(*,*,3) = histomatch(PANIMAGERIC(*,*,3), M4_HIST)

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;       MTF      ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
MTF_PANIMAGE = INTARR(sizes(1),sizes(2),sizes(3))
Z = FLTARR(50,100,24)  ;R-G-B-UV
fcut = 1./N;
NBands = sizes(3)
NFILTER=41.
MTF_Nyq =  [0.29, 0.29, 0.28, 0.30]
kaiser = [0.9403,0.9460,0.9515,0.9567,0.9616,0.9662,0.9705,0.9746,0.9783,0.9817,0.9849,0.9878,0.9903,0.9926,0.9946,0.9962,$
          0.9976,0.9986,0.9994,0.9998,1.0000,0.9998,0.9994,0.9986,0.9976,0.9962,0.9946,0.9926,0.9903,0.9878,0.9849,0.9817,$
          0.9783,0.9746,0.9705,0.9662,0.9616,0.9567,0.9515,0.9460,0.9403]
         
FOR i=0,NBands-1 DO BEGIN
  sigma = SQRT( ((NFILTER*(fcut/2.))^2) / (-2.*alog(MTF_Nyq(i))) ) 
;  filter = GAUSSIAN_FUNCTION([sigma,sigma], WIDTH = NFILTER)
;  filter = filter/total(filter)
;  filter = FLOAT(filter/max(filter))
 ; filter = FLOAT(filter*(kaiser#kaiser))
 MTF_PANIMAGE(*,*,i)= GAUSS_SMOOTH(PANIMAGE4(*,*,i),/EDGE_MIRROR, WIDTH=NFILTER)
  ;MTF_PANIMAGE(*,*,i) = CONVOL(PANIMAGE4(*,*,i),filter,/EDGE_MIRROR)
endfor
;MTF_PANIMAGE = PANIMAGE4
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Blurring PAN Image ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
PANIMAGERIC = INTARR(sizes(1), sizes(2), sizes(3))
PANIMAGERIC(*,*,0) = fresize(MTF_PANIMAGE(*,*,0), N)
PANIMAGERIC(*,*,1) = fresize(MTF_PANIMAGE(*,*,1), N)
PANIMAGERIC(*,*,2) = fresize(MTF_PANIMAGE(*,*,2), N)
PANIMAGERIC(*,*,3) = fresize(MTF_PANIMAGE(*,*,3), N)
PANIMAGERIC_H = PANIMAGERIC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Compute Gains Gk ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
var_pl1 = variance(PANIMAGERIC_H(*,*,0))
var_pl2 = variance(PANIMAGERIC_H(*,*,1))
var_pl3 = variance(PANIMAGERIC_H(*,*,2))
var_pl4 = variance(PANIMAGERIC_H(*,*,3))

ms1pl_cov = correlate(MS(*,*,0),PANIMAGERIC_H(*,*,0),/covariance) ;
ms2pl_cov = correlate(MS(*,*,1),PANIMAGERIC_H(*,*,1),/covariance) ;
ms3pl_cov = correlate(MS(*,*,2),PANIMAGERIC_H(*,*,2),/covariance) ;
ms4pl_cov = correlate(MS(*,*,3),PANIMAGERIC_H(*,*,3),/covariance) ;

G1 = ms1pl_cov/var_pl1
G2 = ms2pl_cov/var_pl2
G3 = ms3pl_cov/var_pl3
G4 = ms4pl_cov/var_pl4
;mean_pl1 = mean(PANIMAGERIC_H(*,*,0))
;mean_pl2 = mean(PANIMAGERIC_H(*,*,1))
;mean_pl3 = mean(PANIMAGERIC_H(*,*,2))
;mean_pl4 = mean(PANIMAGERIC_H(*,*,3))
;
;mean_ms1 = mean(MS(*,*,0))
;mean_ms2 = mean(MS(*,*,1))
;mean_ms3 = mean(MS(*,*,2))
;mean_ms4 = mean(MS(*,*,3))

;ms1pl_cov = mean((MS(*,*,0) - mean_ms1)*(PANIMAGERIC_H(*,*,0) - mean_pl1)) ;
;ms2pl_cov = mean((MS(*,*,1) - mean_ms2)*(PANIMAGERIC_H(*,*,1) - mean_pl2)) ;
;ms3pl_cov = mean((MS(*,*,2) - mean_ms3)*(PANIMAGERIC_H(*,*,2) - mean_pl3)) ;
;ms4pl_cov = mean((MS(*,*,3) - mean_ms4)*(PANIMAGERIC_H(*,*,3) - mean_pl4)) ;


;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;       Fuse     ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELTA_PAN = PANIMAGE4 - PANIMAGERIC_H

GAIN_PAN = INTARR(sizes(1),sizes(2), sizes(3))
GAIN_PAN(*, *,0) = G1*DELTA_PAN(*,*,0)
GAIN_PAN(*, *,1) = G2*DELTA_PAN(*,*,1)
GAIN_PAN(*, *,2) = G3*DELTA_PAN(*,*,2)
GAIN_PAN(*, *,3) = G4*DELTA_PAN(*,*,3)

FUSED_MS = GAIN_PAN + MS

;DELTA_PAN = PANIMAGE4 - PANIMAGERIC_H
;blockSize = 32
;threshold = 0 ;per disattivare <-1
;FUSED_MS = INTARR(sizes(1),sizes(2),sizes(3)) 
;FOR b=0,sizes(3)-1 DO BEGIN
;  FOR y=0,sizes(1)-1 DO BEGIN
;    FOR x=0,sizes(2)-1 DO BEGIN
;
;      startx = x - floor(blockSize/2)
;      starty = y - floor(blockSize/2)
;      endy = y + floor(blockSize/2)
;      endx = x + floor(blockSize/2)
;
;      IF endy GT (sizes(1)-1) THEN BEGIN
;        endy = sizes(1)-1
;      ENDIF
;
;      IF endx GT (sizes(2)-1) THEN BEGIN
;        endx = sizes(2)-1
;      ENDIF
;
;      IF starty LT 0 THEN BEGIN
;        starty = 0
;      ENDIF
;
;      IF startx LT 0  THEN BEGIN
;        startx = 0
;      ENDIF
;
;      BlockMS = MS(starty:endy,startx:endx,b)
;      BlockPan = PANIMAGERIC(starty:endy,startx:endx,b)
;      StdMS = STDDEV(BlockMS)
;      StdPan = STDDEV(BlockPan)
;      Correlation = CORRELATE(BlockMS,BlockPan)
;      
;      IF Correlation GT threshold THEN BEGIN
;        LG = StdMS/StdPan;
;      ENDIF ELSE BEGIN
;        LG = 0;
;      ENDELSE
;
;      BlockDetails = DELTA_PAN(y,x,b)
;      Details2Add = LG*BlockDetails
;      FusedBlock = MS(y,x,b) + Details2Add
;      FUSED_MS(y,x,b) = FusedBlock
;    ENDFOR
;  ENDFOR
;ENDFOR

im = image(IM1CROPPAN)
im = image(MS[*,*,0:2])
im = image(FUSED_MS[*,*,0:2])

end