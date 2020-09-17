      SUBROUTINE erosion(I,J,NHW,NHE,NVN,NVS)
C
C     THIS SUBROUTINE CALCULATES DETACHMENT AND OVERLAND TRANSPORT
C     OF SURFACE SEDIMENT FROM PRECIPITATION IN WEATHER FILE AND
C     FROM RUNOFF IN 'WATSUB'
C
      include "parameters.h"
      include "blkc.h"
      include "blk2a.h"
      include "blk5.h"
      include "blk8a.h"
      include "blk8b.h"
      include "blk10.h"
      include "blk11a.h"
      include "blk13a.h"
      include "blk13b.h"
      include "blk13c.h"
      include "blk19a.h"
      include "blk19b.h"
      include "blk19c.h"
      include "blk20f.h"
      PARAMETER(VLS=2.5E-02)
      DIMENSION SED2(JY,JX),RERSED(2,JV,JH),TERSED(JY,JX),RDTSED(JY,JX)
      DO 9995 NX=NHW,NHE
      DO 9990 NY=NVN,NVS
      IF(IERSNG.NE.0)THEN
      SED2(NY,NX)=SED(NY,NX)
      ENDIF
9990  CONTINUE
9995  CONTINUE
C
C     INTERNAL TIME STEP AT WHICH SEDIMENT DETACHMENT AND TRANSPORT
C     IS CALCULATED. DETACHMENT IS THE SUM OF THAT BY RAINFALL AND
C     OVERLAND FLOW


C
      DO 30 M=1,NPH
      DO 9895 NX=NHW,NHE
      DO 9890 NY=NVN,NVS
      IF(IERSNG.NE.0)THEN
      TERSED(NY,NX)=0.0
      N1=NX
      N2=NY
C
C     DETACHMENT WHEN SURFACE WATER IS ABSENT BUT RESIDUAL
C     SEDIMENT IS PRESENT
C
      IF(VOLGM(M,N2,N1).LE.0.0)THEN
      RDTSED(N2,N1)=-SED2(N2,N1)*XNPH
      XDTSED(N2,N1)=XDTSED(N2,N1)-SED2(N2,N1)*XNPH
      ELSE
      RDTSED(N2,N1)=0.0
      ENDIF
C
C     DETACHMENT BY RAINFALL WHEN SURFACE WATER IS PRESENT
C
      IF(PRECD(N2,N1)+PRECB(N2,N1).GT.0.0
     2.AND.VOLGM(M,N2,N1).GT.ZEROS(N2,N1))THEN
      PRECD2=PRECD(N2,N1)*1.0E+03
      PRECB2=PRECB(N2,N1)*1.0E+03
C
C     KINETIC ENERGY OF DIRECT RAINFALL AND THROUGHFALL
C
      IF(PRECD2.GT.ZERO)THEN
      ENGKD=AMAX1(0.0,8.95+8.44*LOG(PRECD2))
      ELSE
      ENGKD=0.0
      ENDIF
      IF(PRECB2.GT.ZERO)THEN
      ENGKB=AMAX1(0.0,15.8*SQRT(ZT(N2,N1))-5.87)
      ELSE
      ENGKB=0.0
      ENDIF
C
C     DETACHMENT OF SEDIMENT FROM SURFACE SOIL DEPENDS ON RAINFALL
C     KINETIC ENERGY AND FROM DETACHMENT COEFFICIENT IN 'HOUR1',
C     ATTENUATED BY DEPTH OF SURFACE WATER
C
      IF(ENGKD.GT.0.0.OR.ENGKB.GT.0.0)THEN
      DETX=1.0E-06*DETS(N2,N1)*(ENGKD*PRECD2+ENGKB*PRECB2)*XNPH
      H=VOLGM(M,N2,N1)/AREA(3,NU(N2,N1),N2,N1)
      DETR=AMIN1(BKVL(NU(N2,N1),N2,N1)*XNPH
     2,DETX*AREA(3,NU(N2,N1),N2,N1)*EXP(-2.0E+03*H)
     3*FMPR(NU(N2,N1),N2,N1))
      RDTSED(N2,N1)=RDTSED(N2,N1)+DETR
      XDTSED(N2,N1)=XDTSED(N2,N1)+DETR
C     WRITE(*,1117)'RAIN',I,J,M,N1,N2,RDTSED(N2,N1),XDTSED(N2,N1)
C    2,DETR,DETZ,DETX,H,PRECD2,PRECB2,ENGKD,ENGKB,SED2(N2,N1)
1117  FORMAT(A8,5I4,20E12.4)
      ENDIF
      ENDIF
      DO 4310 N=1,2
      IF(N.EQ.1)THEN
      N4=NX+1
      N5=NY
      ELSEIF(N.EQ.2)THEN
      N4=NX
      N5=NY+1
      ENDIF
C
C     DETACHMENT-DEPOSITION IN SURFACE WATER FROM OVERLAND WATER
C     VELOCITY FROM 'WATSUB' USED TO CALCULATE STREAM POWER,
C     AND FROM SEDIMENT TRANSPORT CAPACITY VS. CURRENT SEDIMENT
C     CONCENTRATION IN SURFACE WATER, MODIFIED BY SOIL COHESION
C     FROM 'HOUR1'
C
      IF(QRV(M,N,N5,N4).GT.0.0)THEN
      STPR=1.0E+02*QRV(M,N,N5,N4)*ABS(SLOPE(N,N2,N1))
      CSEDX=2.65*CER(N2,N1)*AMAX1(0.0,STPR-0.4)**XER(N2,N1)
      IF(VOLGM(M,N2,N1).GT.ZEROS(N2,N1))THEN
      CSEDD=AMAX1(0.0,SED2(N2,N1)/VOLGM(M,N2,N1))
      ELSE
      CSEDD=0.0
      ENDIF
      IF(CSEDD.GT.CSEDX)THEN
      EDET=1.0
      ELSE
      EDET=1.0/(0.89+0.56*COHS(N2,N1))
      ENDIF
      DETI=XNPH*AMAX1(-SED2(N2,N1),AMIN1(BKVL(NU(N2,N1),N2,N1)
     2,EDET*AREA(3,NU(N2,N1),N2,N1)*VLS*(CSEDX-CSEDD)))
      RDTSED(N2,N1)=RDTSED(N2,N1)+DETI
      XDTSED(N2,N1)=XDTSED(N2,N1)+DETI
C     WRITE(*,1112)'CSED',I,J,M,N1,N2,N,RDTSED(N2,N1),XDTSED(N2,N1)
C    2,SED2(N2,N1),DETR,DETI,DETZ,DETX,QRM(M,N,N5,N4)
C    3,QRV(M,N,N5,N4),VOLGM(M,N2,N1),H,SLOPE(N,N2,N1),STPR,CSEDX
C    4,CSEDD,EDET,ZM(N2,N1)
1112  FORMAT(A8,6I4,30E12.4)
      ENDIF
C
C     TRANSPORT OF SEDIMENT IN OVERLAND FLOW FROM SEDIMENT
C     CONCENTRATION TIMES OVERLAND WATER FLUX FROM 'WATSUB'
C
      IF((N.EQ.1.AND.NX.NE.NHE).OR.(N.EQ.2.AND.NY.NE.NVS))THEN
      IF(QRM(M,N,N5,N4).EQ.0.0)THEN
      RERSED(N,N5,N4)=0.0
      ELSE
      IF(QRM(M,N,N5,N4).GT.0.0)THEN
      IF(VOLGM(M,N2,N1).GT.ZEROS(N2,N1))THEN
      CSEDE=AMAX1(0.0,SED2(N2,N1)/VOLGM(M,N2,N1))
      ELSE
      CSEDE=0.0
      ENDIF
      RERSED(N,N5,N4)=AMIN1(SED2(N2,N1)*XNPH,CSEDE*QRM(M,N,N5,N4))
      ELSEIF(QRM(M,N,N5,N4).LT.0.0)THEN
      IF(VOLGM(M,N5,N4).GT.ZEROS(N5,N4))THEN
      CSEDE=AMAX1(0.0,SED2(N5,N4)/VOLGM(M,N5,N4))
      ELSE
      CSEDE=0.0
      ENDIF
      RERSED(N,N5,N4)=AMAX1(-SED2(N5,N4)*XNPH,CSEDE*QRM(M,N,N5,N4))
      ENDIF
      XSEDER(N,N5,N4)=XSEDER(N,N5,N4)+RERSED(N,N5,N4)
C     WRITE(*,1113)'INTL',I,J,M,N1,N2,N,RERSED(N,N5,N4),XSEDER(N,N5,N4)
C    2,SED2(N2,N1),SED2(N5,N4),CSEDE,QRM(M,N,N5,N4),QRV(M,N,N5,N4)
C    3,VOLGM(M,N2,N1)
1113  FORMAT(A8,6I4,30E12.4)
      ENDIF
      ENDIF
4310  CONTINUE
      ENDIF
9890  CONTINUE
9895  CONTINUE
C
C     BOUNDARY SEDIMENT FLUXES
C
      DO 9595 NX=NHW,NHE
      DO 9590 NY=NVN,NVS
      IF(IERSNG.NE.0)THEN
      N1=NX
      N2=NY
C
C     LOCATE EXTERNAL BOUNDARIES
C
      DO 9580 N=1,2
      DO 9575 NN=1,2
      IF(N.EQ.1)THEN
      N4=NX+1
      N5=NY
      IF(NN.EQ.1)THEN
      IF(NX.EQ.NHE)THEN
      M1=NX
      M2=NY
      M4=NX+1
      M5=NY
      XN=-1.0
      ELSE
      GO TO 9575
      ENDIF
      ELSEIF(NN.EQ.2)THEN
      IF(NX.EQ.NHW)THEN
      M1=NX
      M2=NY
      M4=NX
      M5=NY
      XN=1.0
      ELSE
      GO TO 9575
      ENDIF
      ENDIF
      ELSEIF(N.EQ.2)THEN
      N4=NX
      N5=NY+1
      IF(NN.EQ.1)THEN
      IF(NY.EQ.NVS)THEN
      M1=NX
      M2=NY
      M4=NX
      M5=NY+1
      XN=-1.0
      ELSE
      GO TO 9575
      ENDIF
      ELSEIF(NN.EQ.2)THEN
      IF(NY.EQ.NVN)THEN
      M1=NX
      M2=NY
      M4=NX
      M5=NY
      XN=1.0
      ELSE
      GO TO 9575
      ENDIF
      ENDIF
      ENDIF
C
C     SEDIMENT TRANSPORT ACROSS BOUNDARY FROM BOUNDARY RUNOFF
C     IN 'WATSUB' TIMES BOUNDARY SEDIMENT CONCENTRATION IN
C     SURFACE WATER
C
      IF(QRM(M,N,N5,N4).EQ.0.0)THEN
      RERSED(N,M5,M4)=0.0
      ELSEIF(NN.EQ.1.AND.QRM(M,N,N5,N4).GT.0.0
     2.OR.NN.EQ.2.AND.QRM(M,N,N5,N4).LT.0.0)THEN
      IF(VOLGM(M,N2,N1).GT.ZEROS(N2,N1))THEN
      CSEDE=AMAX1(0.0,SED2(N2,N1)/VOLGM(M,N2,N1))
      ELSE
      CSEDE=0.0
      ENDIF
      RERSED(N,M5,M4)=CSEDE*QRM(M,N,N5,N4)
      XSEDER(N,M5,M4)=XSEDER(N,M5,M4)+RERSED(N,M5,M4)
      FSEDER=AMIN1(1.0,RERSED(N,M5,M4)/BKVL(NU(N2,N1),N2,N1))
C
C     TRANSPORT OF EXCHANGEABLE, PRECIPITATED AND ORGANIC P IN SEDIMENT
C
C     XH1PEX=FSEDER*XH1P(NU(N2,N1),N2,N1)*31.0
C     XH2PEX=FSEDER*XH2P(NU(N2,N1),N2,N1)*31.0
C     XPRPEX=FSEDER*(PALPO(NU(N2,N1),N2,N1)*31.0
C    2+PFEPO(NU(N2,N1),N2,N1)*31.0+PCAPD(NU(N2,N1),N2,N1)*31.0
C    3+PCAPH(NU(N2,N1),N2,N1)*93.0+PCAPM(NU(N2,N1),N2,N1)*62.0)
C     XORGEX=0.0
C     DO 380 K=0,5
C     DO 380 NNN=1,7
C     DO 380 MM=1,2
C     XORGEX=XORGEX+FSEDER*OMP(MM,NNN,K,NU(N2,N1), N2,N1)
380   CONTINUE
C     DO 375 K=0,4
C     DO 370 MM=1,2
C     XORGEX=XORGEX+FSEDER*ORP(MM,K,NU(N2,N1),N2,N1)
370   CONTINUE
C     XORGEX=XORGEX+FSEDER*OHP(K,NU(N2,N1), N2,N1)
C     DO 365 MM=1,4
C     XORGEX=XORGEX+FSEDER*OSP(MM,K,NU(N2,N1),N2,N1)
365   CONTINUE
375   CONTINUE
C     WRITE(20,1114)'ERSN',I,J,M,N1,N2,NU(N2,N1),N,QRM(M,N,N5,N4)
C    2,RERSED(N,M5,M4),XH1PEX+XH2PEX,XPRPEX,XORGEX,DETS(N2,N1)
C    3,COHS(N2,N1),CSEDX
1114  FORMAT(A8,7I4,30E12.4)
      ELSE
      RERSED(N,M5,M4)=0.0
      ENDIF
9575  CONTINUE
C
C     NET SEDIMENT FLUXES
C
      TERSED(N2,N1)=TERSED(N2,N1)+RERSED(N,N2,N1)-RERSED(N,N5,N4)
9580  CONTINUE
      ENDIF
9590  CONTINUE
9595  CONTINUE
C
C     UPDATE STATE VARIABLES FOR SEDIMENT TRANSPORT
C
      DO 9695 NX=NHW,NHE
      DO 9690 NY=NVN,NVS
      IF(IERSNG.NE.0)THEN
      SED2(NY,NX)=SED2(NY,NX)+TERSED(NY,NX)+RDTSED(NY,NX)
      ENDIF
9690  CONTINUE
9695  CONTINUE
30    CONTINUE
C
C     INTERNAL BOUNDARY FLUXES
C
      DO 9495 NX=NHW,NHE
      DO 9490 NY=NVN,NVS
      IF(IERSNG.NE.0)THEN
      N1=NX
      N2=NY
      DO 9485 N=1,2
      IF(N.EQ.1)THEN
      IF(NX.EQ.NHE)THEN
      GO TO 9485
      ELSE
      N4=NX+1
      N5=NY
      ENDIF
      ELSEIF(N.EQ.2)THEN
      IF(NY.EQ.NVS)THEN
      GO TO 9485
      ELSE
      N4=NX
      N5=NY+1
      ENDIF
      ENDIF
C
C     FLUXES OF ALL SOLID MATERIALS IN SEDIMENT ARE CALCULATED
C     FROM VALUES OF THEIR CURRENT STATE VARIABLES MULTIPLIED
C     BY THE FRACTION OF THE TOTAL SURFACE LAYER MASS THAT IS
C     TRANSPORTED IN SEDIMENT
C
C
C     IF TRANSPORT IS FROM CURRENT TO ADJACENT GRID CELL
C
      IF(XSEDER(N,N5,N4).GT.0.0)THEN
      FSEDER=AMIN1(1.0,XSEDER(N,N5,N4)/BKVL(NU(N2,N1),N2,N1))
C
C     SOIL MINERALS
C
      XSANER(N,N5,N4)=FSEDER*SAND(NU(N2,N1),N2,N1)
      XSILER(N,N5,N4)=FSEDER*SILT(NU(N2,N1),N2,N1)
      XCLAER(N,N5,N4)=FSEDER*CLAY(NU(N2,N1),N2,N1)
      XCECER(N,N5,N4)=FSEDER*XCEC(NU(N2,N1),N2,N1)
      XAECER(N,N5,N4)=FSEDER*XAEC(NU(N2,N1),N2,N1)
C
C     FERTILIZER POOLS
C
      XNH4ER(N,N5,N4)=FSEDER*ZNH4FA(NU(N2,N1),N2,N1)
      XNH3ER(N,N5,N4)=FSEDER*ZNH3FA(NU(N2,N1),N2,N1)
      XNHUER(N,N5,N4)=FSEDER*ZNHUFA(NU(N2,N1),N2,N1)
      XNO3ER(N,N5,N4)=FSEDER*ZNO3FA(NU(N2,N1),N2,N1)
      XNH4EB(N,N5,N4)=FSEDER*ZNH4FB(NU(N2,N1),N2,N1)
      XNH3EB(N,N5,N4)=FSEDER*ZNH3FB(NU(N2,N1),N2,N1)
      XNHUEB(N,N5,N4)=FSEDER*ZNHUFB(NU(N2,N1),N2,N1)
      XNO3EB(N,N5,N4)=FSEDER*ZNO3FB(NU(N2,N1),N2,N1)
C
C     EXCHANGEABLE CATIONS AND ANIONS
C
      XN4ER(N,N5,N4)=FSEDER*XN4(NU(N2,N1),N2,N1)
      XNBER(N,N5,N4)=FSEDER*XNB(NU(N2,N1),N2,N1)
      XHYER(N,N5,N4)=FSEDER*XHY(NU(N2,N1),N2,N1)
      XALER(N,N5,N4)=FSEDER*XAL(NU(N2,N1),N2,N1)
      XFEER(N,N5,N4)=FSEDER*XFE(NU(N2,N1),N2,N1)
      XCAER(N,N5,N4)=FSEDER*XCA(NU(N2,N1),N2,N1)
      XMGER(N,N5,N4)=FSEDER*XMG(NU(N2,N1),N2,N1)
      XNAER(N,N5,N4)=FSEDER*XNA(NU(N2,N1),N2,N1)
      XKAER(N,N5,N4)=FSEDER*XKA(NU(N2,N1),N2,N1)
      XHCER(N,N5,N4)=FSEDER*XHC(NU(N2,N1),N2,N1)
      XAL2ER(N,N5,N4)=FSEDER*XALO2(NU(N2,N1),N2,N1)
      XFE2ER(N,N5,N4)=FSEDER*XFEO2(NU(N2,N1),N2,N1)
      XOH0ER(N,N5,N4)=FSEDER*XOH0(NU(N2,N1),N2,N1)
      XOH1ER(N,N5,N4)=FSEDER*XOH1(NU(N2,N1),N2,N1)
      XOH2ER(N,N5,N4)=FSEDER*XOH2(NU(N2,N1),N2,N1)
      XH1PER(N,N5,N4)=FSEDER*XH1P(NU(N2,N1),N2,N1)
      XH2PER(N,N5,N4)=FSEDER*XH2P(NU(N2,N1),N2,N1)
      XOH0EB(N,N5,N4)=FSEDER*XOH0B(NU(N2,N1),N2,N1)
      XOH1EB(N,N5,N4)=FSEDER*XOH1B(NU(N2,N1),N2,N1)
      XOH2EB(N,N5,N4)=FSEDER*XOH2B(NU(N2,N1),N2,N1)
      XH1PEB(N,N5,N4)=FSEDER*XH1PB(NU(N2,N1),N2,N1)
      XH2PEB(N,N5,N4)=FSEDER*XH2PB(NU(N2,N1),N2,N1)
C
C     PRECIPITATES
C
      PALOER(N,N5,N4)=FSEDER*PALOH(NU(N2,N1),N2,N1)
      PFEOER(N,N5,N4)=FSEDER*PFEOH(NU(N2,N1),N2,N1)
      PCACER(N,N5,N4)=FSEDER*PCACO(NU(N2,N1),N2,N1)
      PCASER(N,N5,N4)=FSEDER*PCASO(NU(N2,N1),N2,N1)
      PALPER(N,N5,N4)=FSEDER*PALPO(NU(N2,N1),N2,N1)
      PFEPER(N,N5,N4)=FSEDER*PFEPO(NU(N2,N1),N2,N1)
      PCPDER(N,N5,N4)=FSEDER*PCAPD(NU(N2,N1),N2,N1)
      PCPHER(N,N5,N4)=FSEDER*PCAPH(NU(N2,N1),N2,N1)
      PCPMER(N,N5,N4)=FSEDER*PCAPM(NU(N2,N1),N2,N1)
      PALPEB(N,N5,N4)=FSEDER*PALPB(NU(N2,N1),N2,N1)
      PFEPEB(N,N5,N4)=FSEDER*PFEPB(NU(N2,N1),N2,N1)
      PCPDEB(N,N5,N4)=FSEDER*PCPDB(NU(N2,N1),N2,N1)
      PCPHEB(N,N5,N4)=FSEDER*PCPHB(NU(N2,N1),N2,N1)
      PCPMEB(N,N5,N4)=FSEDER*PCPMB(NU(N2,N1),N2,N1)
C
C     ORGANIC MATTER
C
      DO 9480 K=0,5
      DO 9480 NN=1,7
      DO 9480 M=1,3
      OMCER(M,NN,K,N,N5,N4)=FSEDER*OMC(M,NN,K,NU(N2,N1),N2,N1)
      OMNER(M,NN,K,N,N5,N4)=FSEDER*OMN(M,NN,K,NU(N2,N1),N2,N1)
      OMPER(M,NN,K,N,N5,N4)=FSEDER*OMP(M,NN,K,NU(N2,N1),N2,N1)
9480  CONTINUE
      DO 9475 K=0,4
      DO 9470 M=1,2
      ORCER(M,K,N,N5,N4)=FSEDER*ORC(M,K,NU(N2,N1),N2,N1)
      ORNER(M,K,N,N5,N4)=FSEDER*ORN(M,K,NU(N2,N1),N2,N1)
      ORPER(M,K,N,N5,N4)=FSEDER*ORP(M,K,NU(N2,N1),N2,N1)
9470  CONTINUE
      OHCER(K,N,N5,N4)=FSEDER*OHC(K,NU(N2,N1),N2,N1)
      OHNER(K,N,N5,N4)=FSEDER*OHN(K,NU(N2,N1),N2,N1)
      OHPER(K,N,N5,N4)=FSEDER*OHP(K,NU(N2,N1),N2,N1)
      OHAER(K,N,N5,N4)=FSEDER*OHA(K,NU(N2,N1),N2,N1)
      DO 9465 M=1,4
      OSCER(M,K,N,N5,N4)=FSEDER*OSC(M,K,NU(N2,N1),N2,N1)
      OSAER(M,K,N,N5,N4)=FSEDER*OSA(M,K,NU(N2,N1),N2,N1)
      OSNER(M,K,N,N5,N4)=FSEDER*OSN(M,K,NU(N2,N1),N2,N1)
      OSPER(M,K,N,N5,N4)=FSEDER*OSP(M,K,NU(N2,N1),N2,N1)
9465  CONTINUE
9475  CONTINUE
C     WRITE(*,1115)'SPLIT',I,J,N1,N2,N,XSEDER(N,N5,N4),FSEDER
C    2,XSANER(N,N5,N4),SAND(NU(N2,N1),N2,N1)
C    3,DLYR(3,NU(N2,N1),N2,N1),BKVL(NU(N2,N1),N2,N1)
1115  FORMAT(A8,5I4,30E12.4)
C
C     IF TRANSPORT IS TO CURRENT FROM ADJACENT GRID CELL
C
      ELSEIF(XSEDER(N,N5,N4).LT.0.0)THEN
      FSEDER=AMAX1(-1.0,XSEDER(N,N5,N4)/BKVL(NU(N5,N4),N5,N4))
C
C     SOIL MINERALS
C
      XSANER(N,N5,N4)=FSEDER*SAND(NU(N5,N4),N5,N4)
      XSILER(N,N5,N4)=FSEDER*SILT(NU(N5,N4),N5,N4)
      XCLAER(N,N5,N4)=FSEDER*CLAY(NU(N5,N4),N5,N4)
      XCECER(N,N5,N4)=FSEDER*XCEC(NU(N5,N4),N5,N4)
      XAECER(N,N5,N4)=FSEDER*XAEC(NU(N5,N4),N5,N4)
C
C     FERTILIOZER POOLS
C
      XNH4ER(N,N5,N4)=FSEDER*ZNH4FA(NU(N5,N4),N5,N4)
      XNH3ER(N,N5,N4)=FSEDER*ZNH3FA(NU(N5,N4),N5,N4)
      XNHUER(N,N5,N4)=FSEDER*ZNHUFA(NU(N5,N4),N5,N4)
      XNO3ER(N,N5,N4)=FSEDER*ZNO3FA(NU(N5,N4),N5,N4)
      XNH4EB(N,N5,N4)=FSEDER*ZNH4FB(NU(N5,N4),N5,N4)
      XNH3EB(N,N5,N4)=FSEDER*ZNH3FB(NU(N5,N4),N5,N4)
      XNHUEB(N,N5,N4)=FSEDER*ZNHUFB(NU(N5,N4),N5,N4)
      XNO3EB(N,N5,N4)=FSEDER*ZNO3FB(NU(N5,N4),N5,N4)
C
C     EXCHANGEABLE CATIONS AND ANIONS
C
      XN4ER(N,N5,N4)=FSEDER*XN4(NU(N5,N4),N5,N4)
      XNBER(N,N5,N4)=FSEDER*XNB(NU(N5,N4),N5,N4)
      XHYER(N,N5,N4)=FSEDER*XHY(NU(N5,N4),N5,N4)
      XALER(N,N5,N4)=FSEDER*XAL(NU(N5,N4),N5,N4)
      XFEER(N,N5,N4)=FSEDER*XFE(NU(N5,N4),N5,N4)
      XCAER(N,N5,N4)=FSEDER*XCA(NU(N5,N4),N5,N4)
      XMGER(N,N5,N4)=FSEDER*XMG(NU(N5,N4),N5,N4)
      XNAER(N,N5,N4)=FSEDER*XNA(NU(N5,N4),N5,N4)
      XKAER(N,N5,N4)=FSEDER*XKA(NU(N5,N4),N5,N4)
      XHCER(N,N5,N4)=FSEDER*XHC(NU(N5,N4),N5,N4)
      XAL2ER(N,N5,N4)=FSEDER*XALO2(NU(N5,N4),N5,N4)
      XFE2ER(N,N5,N4)=FSEDER*XFEO2(NU(N5,N4),N5,N4)
      XOH0ER(N,N5,N4)=FSEDER*XOH0(NU(N5,N4),N5,N4)
      XOH1ER(N,N5,N4)=FSEDER*XOH1(NU(N5,N4),N5,N4)
      XOH2ER(N,N5,N4)=FSEDER*XOH2(NU(N5,N4),N5,N4)
      XH1PER(N,N5,N4)=FSEDER*XH1P(NU(N5,N4),N5,N4)
      XH2PER(N,N5,N4)=FSEDER*XH2P(NU(N5,N4),N5,N4)
      XOH0EB(N,N5,N4)=FSEDER*XOH0B(NU(N5,N4),N5,N4)
      XOH1EB(N,N5,N4)=FSEDER*XOH1B(NU(N5,N4),N5,N4)
      XOH2EB(N,N5,N4)=FSEDER*XOH2B(NU(N5,N4),N5,N4)
      XH1PEB(N,N5,N4)=FSEDER*XH1PB(NU(N5,N4),N5,N4)
      XH2PEB(N,N5,N4)=FSEDER*XH2PB(NU(N5,N4),N5,N4)
C
C     PRECIPITATES
C
      PALOER(N,N5,N4)=FSEDER*PALOH(NU(N5,N4),N5,N4)
      PFEOER(N,N5,N4)=FSEDER*PFEOH(NU(N5,N4),N5,N4)
      PCACER(N,N5,N4)=FSEDER*PCACO(NU(N5,N4),N5,N4)
      PCASER(N,N5,N4)=FSEDER*PCASO(NU(N5,N4),N5,N4)
      PALPER(N,N5,N4)=FSEDER*PALPO(NU(N5,N4),N5,N4)
      PFEPER(N,N5,N4)=FSEDER*PFEPO(NU(N5,N4),N5,N4)
      PCPDER(N,N5,N4)=FSEDER*PCAPD(NU(N5,N4),N5,N4)
      PCPHER(N,N5,N4)=FSEDER*PCAPH(NU(N5,N4),N5,N4)
      PCPMER(N,N5,N4)=FSEDER*PCAPM(NU(N5,N4),N5,N4)
      PALPEB(N,N5,N4)=FSEDER*PALPB(NU(N5,N4),N5,N4)
      PFEPEB(N,N5,N4)=FSEDER*PFEPB(NU(N5,N4),N5,N4)
      PCPDEB(N,N5,N4)=FSEDER*PCPDB(NU(N5,N4),N5,N4)
      PCPHEB(N,N5,N4)=FSEDER*PCPHB(NU(N5,N4),N5,N4)
      PCPMEB(N,N5,N4)=FSEDER*PCPMB(NU(N5,N4),N5,N4)
C
C     ORGANIC MATTER
C
      DO 9380 K=0,5
      DO 9380 NN=1,7
      DO 9380 M=1,3
      OMCER(M,NN,K,N,N5,N4)=FSEDER*OMC(M,NN,K,NU(N5,N4),N5,N4)
      OMNER(M,NN,K,N,N5,N4)=FSEDER*OMN(M,NN,K,NU(N5,N4),N5,N4)
      OMPER(M,NN,K,N,N5,N4)=FSEDER*OMP(M,NN,K,NU(N5,N4),N5,N4)
9380  CONTINUE
      DO 9375 K=0,4
      DO 9370 M=1,2
      ORCER(M,K,N,N5,N4)=FSEDER*ORC(M,K,NU(N5,N4),N5,N4)
      ORNER(M,K,N,N5,N4)=FSEDER*ORN(M,K,NU(N5,N4),N5,N4)
      ORPER(M,K,N,N5,N4)=FSEDER*ORP(M,K,NU(N5,N4),N5,N4)
9370  CONTINUE
      OHCER(K,N,N5,N4)=FSEDER*OHC(K,NU(N5,N4),N5,N4)
      OHNER(K,N,N5,N4)=FSEDER*OHN(K,NU(N5,N4),N5,N4)
      OHPER(K,N,N5,N4)=FSEDER*OHP(K,NU(N5,N4),N5,N4)
      OHAER(K,N,N5,N4)=FSEDER*OHA(K,NU(N5,N4),N5,N4)
      DO 9365 M=1,4
      OSCER(M,K,N,N5,N4)=FSEDER*OSC(M,K,NU(N5,N4),N5,N4)
      OSAER(M,K,N,N5,N4)=FSEDER*OSA(M,K,NU(N5,N4),N5,N4)
      OSNER(M,K,N,N5,N4)=FSEDER*OSN(M,K,NU(N5,N4),N5,N4)
      OSPER(M,K,N,N5,N4)=FSEDER*OSP(M,K,NU(N5,N4),N5,N4)
9365  CONTINUE
9375  CONTINUE
      ENDIF
9485  CONTINUE
      ENDIF
9490  CONTINUE
9495  CONTINUE
C
C     EXTERNAL BOUNDARY SEDIMENT FLUXES
C
      DO 8995 NX=NHW,NHE
      DO 8990 NY=NVN,NVS
      IF(IERSNG.NE.0)THEN
      DO 8980 N=1,2
      DO 8975 NN=1,2
      IF(N.EQ.1)THEN
      IF(NN.EQ.1)THEN
      IF(NX.EQ.NHE)THEN
      N1=NX
      N2=NY
      N4=NX+1
      N5=NY
      XN=-1.0
      ELSE
      GO TO 8975
      ENDIF
      ELSEIF(NN.EQ.2)THEN
      IF(NX.EQ.NHW)THEN
      N1=NX
      N2=NY
      N4=NX
      N5=NY
      XN=1.0
      ELSE
      GO TO 8975
      ENDIF
      ENDIF
      ELSEIF(N.EQ.2)THEN
      IF(NN.EQ.1)THEN
      IF(NY.EQ.NVS)THEN
      N1=NX
      N2=NY
      N4=NX
      N5=NY+1
      XN=-1.0
      ELSE
      GO TO 8975
      ENDIF
      ELSEIF(NN.EQ.2)THEN
      IF(NY.EQ.NVN)THEN
      N1=NX
      N2=NY
      N4=NX
      N5=NY
      XN=1.0
      ELSE
      GO TO 8975
      ENDIF
      ENDIF
      ENDIF
      IF(NN.EQ.1.AND.XSEDER(N,N5,N4).GT.0.0
     2.OR.NN.EQ.2.AND.XSEDER(N,N5,N4).LT.0.0)THEN
      FSEDER=AMIN1(1.0,XSEDER(N,N5,N4)/BKVL(NU(N2,N1),N2,N1))
C
C     SOIL MINERALS
C
      XSANER(N,N5,N4)=FSEDER*SAND(NU(N2,N1),N2,N1)
      XSILER(N,N5,N4)=FSEDER*SILT(NU(N2,N1),N2,N1)
      XCLAER(N,N5,N4)=FSEDER*CLAY(NU(N2,N1),N2,N1)
      XCECER(N,N5,N4)=FSEDER*XCEC(NU(N2,N1),N2,N1)
      XAECER(N,N5,N4)=FSEDER*XAEC(NU(N2,N1),N2,N1)
C
C     FERTILIZER POOLS
C
      XNH4ER(N,N5,N4)=FSEDER*ZNH4FA(NU(N2,N1),N2,N1)
      XNH3ER(N,N5,N4)=FSEDER*ZNH3FA(NU(N2,N1),N2,N1)
      XNHUER(N,N5,N4)=FSEDER*ZNHUFA(NU(N2,N1),N2,N1)
      XNO3ER(N,N5,N4)=FSEDER*ZNO3FA(NU(N2,N1),N2,N1)
      XNH4EB(N,N5,N4)=FSEDER*ZNH4FB(NU(N2,N1),N2,N1)
      XNH3EB(N,N5,N4)=FSEDER*ZNH3FB(NU(N2,N1),N2,N1)
      XNHUEB(N,N5,N4)=FSEDER*ZNHUFB(NU(N2,N1),N2,N1)
      XNO3EB(N,N5,N4)=FSEDER*ZNO3FB(NU(N2,N1),N2,N1)
C
C     EXCHANGEABLE CATIONS AND ANIONS
C
      XN4ER(N,N5,N4)=FSEDER*XN4(NU(N2,N1),N2,N1)
      XNBER(N,N5,N4)=FSEDER*XNB(NU(N2,N1),N2,N1)
      XHYER(N,N5,N4)=FSEDER*XHY(NU(N2,N1),N2,N1)
      XALER(N,N5,N4)=FSEDER*XAL(NU(N2,N1),N2,N1)
      XFEER(N,N5,N4)=FSEDER*XFE(NU(N2,N1),N2,N1)
      XCAER(N,N5,N4)=FSEDER*XCA(NU(N2,N1),N2,N1)
      XMGER(N,N5,N4)=FSEDER*XMG(NU(N2,N1),N2,N1)
      XNAER(N,N5,N4)=FSEDER*XNA(NU(N2,N1),N2,N1)
      XKAER(N,N5,N4)=FSEDER*XKA(NU(N2,N1),N2,N1)
      XHCER(N,N5,N4)=FSEDER*XHC(NU(N2,N1),N2,N1)
      XAL2ER(N,N5,N4)=FSEDER*XALO2(NU(N2,N1),N2,N1)
      XFE2ER(N,N5,N4)=FSEDER*XFEO2(NU(N2,N1),N2,N1)
      XOH0ER(N,N5,N4)=FSEDER*XOH0(NU(N2,N1),N2,N1)
      XOH1ER(N,N5,N4)=FSEDER*XOH1(NU(N2,N1),N2,N1)
      XOH2ER(N,N5,N4)=FSEDER*XOH2(NU(N2,N1),N2,N1)
      XH1PER(N,N5,N4)=FSEDER*XH1P(NU(N2,N1),N2,N1)
      XH2PER(N,N5,N4)=FSEDER*XH2P(NU(N2,N1),N2,N1)
      XOH0EB(N,N5,N4)=FSEDER*XOH0B(NU(N2,N1),N2,N1)
      XOH1EB(N,N5,N4)=FSEDER*XOH1B(NU(N2,N1),N2,N1)
      XOH2EB(N,N5,N4)=FSEDER*XOH2B(NU(N2,N1),N2,N1)
      XH1PEB(N,N5,N4)=FSEDER*XH1PB(NU(N2,N1),N2,N1)

      XH2PEB(N,N5,N4)=FSEDER*XH2PB(NU(N2,N1),N2,N1)
C
C     PRECIPITATES
C
      PALOER(N,N5,N4)=FSEDER*PALOH(NU(N2,N1),N2,N1)
      PFEOER(N,N5,N4)=FSEDER*PFEOH(NU(N2,N1),N2,N1)
      PCACER(N,N5,N4)=FSEDER*PCACO(NU(N2,N1),N2,N1)
      PCASER(N,N5,N4)=FSEDER*PCASO(NU(N2,N1),N2,N1)
      PALPER(N,N5,N4)=FSEDER*PALPO(NU(N2,N1),N2,N1)
      PFEPER(N,N5,N4)=FSEDER*PFEPO(NU(N2,N1),N2,N1)
      PCPDER(N,N5,N4)=FSEDER*PCAPD(NU(N2,N1),N2,N1)
      PCPHER(N,N5,N4)=FSEDER*PCAPH(NU(N2,N1),N2,N1)
      PCPMER(N,N5,N4)=FSEDER*PCAPM(NU(N2,N1),N2,N1)
      PALPEB(N,N5,N4)=FSEDER*PALPB(NU(N2,N1),N2,N1)
      PFEPEB(N,N5,N4)=FSEDER*PFEPB(NU(N2,N1),N2,N1)
      PCPDEB(N,N5,N4)=FSEDER*PCPDB(NU(N2,N1),N2,N1)
      PCPHEB(N,N5,N4)=FSEDER*PCPHB(NU(N2,N1),N2,N1)
      PCPMEB(N,N5,N4)=FSEDER*PCPMB(NU(N2,N1),N2,N1)
C
C     ORGANIC MATTER
C
      DO 8880 K=0,5
      DO 8880 NO=1,7
      DO 8880 M=1,3
      OMCER(M,NO,K,N,N5,N4)=FSEDER*OMC(M,NO,K,NU(N2,N1),N2,N1)
      OMNER(M,NO,K,N,N5,N4)=FSEDER*OMN(M,NO,K,NU(N2,N1),N2,N1)
      OMPER(M,NO,K,N,N5,N4)=FSEDER*OMP(M,NO,K,NU(N2,N1),N2,N1)
8880  CONTINUE
      DO 8875 K=0,4
      DO 8870 M=1,2
      ORCER(M,K,N,N5,N4)=FSEDER*ORC(M,K,NU(N2,N1),N2,N1)
      ORNER(M,K,N,N5,N4)=FSEDER*ORN(M,K,NU(N2,N1),N2,N1)
      ORPER(M,K,N,N5,N4)=FSEDER*ORP(M,K,NU(N2,N1),N2,N1)
8870  CONTINUE
      OHCER(K,N,N5,N4)=FSEDER*OHC(K,NU(N2,N1),N2,N1)
      OHNER(K,N,N5,N4)=FSEDER*OHN(K,NU(N2,N1),N2,N1)
      OHPER(K,N,N5,N4)=FSEDER*OHP(K,NU(N2,N1),N2,N1)
      OHAER(K,N,N5,N4)=FSEDER*OHA(K,NU(N2,N1),N2,N1)
      DO 8865 M=1,4
      OSCER(M,K,N,N5,N4)=FSEDER*OSC(M,K,NU(N2,N1),N2,N1)
      OSAER(M,K,N,N5,N4)=FSEDER*OSA(M,K,NU(N2,N1),N2,N1)
      OSNER(M,K,N,N5,N4)=FSEDER*OSN(M,K,NU(N2,N1),N2,N1)
      OSPER(M,K,N,N5,N4)=FSEDER*OSP(M,K,NU(N2,N1),N2,N1)
8865  CONTINUE
8875  CONTINUE
C     WRITE(*,1116)'EDGE',I,J,N1,N2,N,XSEDER(N,N5,N4),FSEDER
C    2,XSANER(N,N5,N4),SAND(NU(N2,N1),N2,N1),SILT(NU(N2,N1),N2,N1)
C    3,CLAY(NU(N2,N1),N2,N1),ORGC(NU(N2,N1),N2,N1)
C    3,DLYR(3,NU(N2,N1),N2,N1),BKVL(NU(N2,N1),N2,N1)
1116  FORMAT(A8,5I4,30E12.4)
      ENDIF
8975  CONTINUE
8980  CONTINUE
      ENDIF
8990  CONTINUE
8995  CONTINUE
      RETURN
      END
