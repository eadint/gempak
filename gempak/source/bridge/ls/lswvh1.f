        SUBROUTINE  LS_WVH1( lsfrpt, ipt, iret )
C************************************************************************
C* LS_WVH1                                                              *
C*                                                                      *
C* This subroutine decodes the wave height to the nearest tenth of a    *
C* meter given in the group 70H(wa)H(wa)H(wa).  The wave height value   *
C* from this group will replace the wave height value from the 2-group, *
C* since it is more accurate.                                           *
C*                                                                      *
C* LS_WVH1  ( LSFRPT, IPT, IRET )                                       *
C*                                                                      *
C* Input parameters:                                                    *
C*      LSFRPT          CHAR*           Report array                    *
C*					                                *
C* Input and Output parameters:                                         *
C*	IPT		INTEGER		On input, points to first 'H' in*
C*					the group 70H(wa)H(wa)H(wa); on *
C*					output, points to last 'H'      *
C*					                                *
C* Output parameters:                                                   *
C*      XWVHGT          REAL            Wave height in meters           *
C*	IRET            INTEGER         Return code                     *
C*				   	  0 = normal return 	        *
C*                                        1 = problems                  *
C*                                                                      *
C**								        *
C* Log:							                *
C* R. Hollern/NCEP      6/96                                            *
C* R. Hollern/NCEP     12/96    Replaced ST_C2R with ST_INTG            *
C* R. Hollern/NCEP      1/98    Changes based on MA_WVH1                *
C* A. Hardy/GSC         1/98    Added GEMINC                            *
C************************************************************************
        INCLUDE  	'GEMPRM.PRM'
        INCLUDE  	'lscmn.cmn'
C*
        CHARACTER*(*)   lsfrpt
C*
        CHARACTER     	fld3*3
C------------------------------------------------------------------------
        iret = 0
C
C*      Get wave height in meters. 
C
        IF ( lsfrpt ( ipt:ipt+2 ) .ne. '///' ) THEN
            fld3 = lsfrpt ( ipt:ipt+2 )
            CALL  ST_INTG ( fld3, ival, ier )
            IF ( ier .eq. 0 ) xwvhgt = .1 * FLOAT ( ival )
        END IF
C
        ipt = ipt + 2
C*
        RETURN
        END
