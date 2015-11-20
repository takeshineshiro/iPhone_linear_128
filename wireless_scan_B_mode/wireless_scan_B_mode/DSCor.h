//
//  DSCor.hpp
//  wireless_scan_B_mode
//
//  Created by wong on 15/11/19.
//  Copyright © 2015年 lepumedical. All rights reserved.
//

#ifndef __DSCOR_H__
#define __DSCOR_H__
class CDSCor
{
protected:
    CDSCor(void);
    virtual ~CDSCor(void);
    static CDSCor* s_pInst;
public:
    static CDSCor* GetInstance();
    static void ClearInstance();
    
public:
    enum {
        PROBE_SECTORSCAN	=	0,
        PROBE_SECTORARRAY	=	1,
        PROBE_LINEARARRAY   =   2,
    };
    
    enum {
        DSC_WIDTH	=	640,
        DSC_HEIGHT	=	480,
    };
    
    enum {
        RAWDATA_SAMPLE_IN_LINE	=	512,
        RAWDATA_LINE_IN_FRAME	=	256,
    };
    
protected:
    //	ÕºœÒDSC
    typedef struct _tagDSC_INDEX{
        bool bIn;
        unsigned long	ulLine;
        unsigned long	ulPixel;
        unsigned long	ulPartLine;
        unsigned long	ulPartPixel;
    } DSC_INDEX;
    DSC_INDEX* m_pDscIndex;
    unsigned char* m_pDSCImage;
    
    //  gama map table
    float m_fGama;
    unsigned int m_unGama[256];
    
    //	µ±«∞ÃΩÕ∑¿‡–Õ”ÎZoomÀ˜“˝
    int	m_nProbeType;
    int m_nZoomIndex;
public:
    //	≥ı ºªØDSCœµ ˝
    bool InitDSC(int nProbeType,int nZoom);
    
    //  Init gama map table
    bool InitGama(float gama);
    //  Get gama data
    unsigned int* GetGama();
    
    
    //	DSCÕºœÒ
    unsigned char* DSCImage(unsigned char* pRawData);
    
    //	ªÒ»°DSC∫ÛÕºœÒµƒ±»¿˝≥ﬂ£¨µ•Œª£∫ mm/pixel
    static double GetScale(int nProbeType,int nZoom);
    
    
    
};

#endif //__DSCOR_H__


