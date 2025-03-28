	SUBROUTINE SNDLYR ( tropht, delz, cldhgt, hlcl,
     +			    nlun, lun, nparms, nlevel, hdata,
     +			    uabs, vabs, iret )
C************************************************************************
C* SNDLYR								*
C*									*
C* This routine will compute the layer properties of the wind in the	*
C* layers:								*
C*	Surface    to Cloud base					*
C*	Cloud base to Cloud top						*
C*	Surface    to Surface + 6 km					*
C*	Surface    to Tropopause					*
C*	Layers 2 km thick starting at 1 km				*
C*									*
C* SNDLYR ( TROPHT, DELZ, CLDHGT, HLCL, NLUN, LUN, NPARMS, NLEVEL,	*
C*	    HDATA, UABS, VABS, IRET )					*
C*									*
C* Input parameters:							*
C*	TROPHT		CHAR*		Height of the tropopause	*
C*	DELZ		CHAR*		Height increment		*
C*	CLDHGT		CHAR*		Height of cloud base		*
C*	HLCL		REAL		Height of the LCL		*
C*	NLUN		INTEGER		Number of file numbers		*
C*	LUN (NLUN)	INTEGER		File numbers			*
C*	NPARMS		INTEGER		Number of parameters		*
C*	NLEVEL		INTEGER		Number of levels 		*
C*	HDATA (LLMXLV)	REAL		Interpolated data		*
C*	UABS (LLMXLV)	REAL		Absolute U wind components	*
C*	VABS (LLMXLV)	REAL		Absolute V wind components	*
C*									*
C* Output parameters:							*
C*	IRET		INTEGER		Return code			*
C*					  0 = normal			*
C**									*
C* Log:									*
C* S. Jacobs/SSAI	 4/92						*
C* J. Whistler/SSAI	 4/93		Cleaned up header		*
C* J. Whistler/SSAI	 6/93		Computed SKE vector		*
C************************************************************************
	INCLUDE		'GEMPRM.PRM'
	INCLUDE		'sndiag.prm'
C*
	CHARACTER*(*)	tropht, delz, cldhgt
	INTEGER		lun(*)
	REAL		hdata(*), uabs(*), vabs(*)
C*
	REAL		xlyr_shu(10), xlyr_shv(10), xlyr_shn(10)
C*
	INCLUDE		'ERMISS.FNC'
C------------------------------------------------------------------------
C*	Initialize sums.
C
	iret = 0
	sfc_cb_u   = 0.
	sfc_cb_v   = 0.
	sfc_cb_n   = 0.
	sfc_cb_sh  = 0.
	sfc_cb_shu = 0.
	sfc_cb_shv = 0.
	cb_ct_u   = 0.
	cb_ct_v   = 0.
	cb_ct_n   = 0.
	cb_ct_sh  = 0.
	cb_ct_shu = 0.
	cb_ct_shv = 0.
	sfc_6_sh  = 0.
	sfc_6_shu = 0.
	sfc_6_shv = 0.
	ske_6_sh  = 0.
	ske_6_shu = 0.
	ske_6_shv = 0.
	ske_S_sh  = 0.
	ske_S_shu = 0.
	ske_S_shv = 0.
	sfc_trp_sh  = 0.
	sfc_trp_shu = 0.
	sfc_trp_shv = 0.
	DO  i = 1, 10
	    xlyr_shu(i) = 0.
	    xlyr_shv(i) = 0.
	    xlyr_shn(i) = 0.
	END DO
C
C*	Get user input.
C
	CALL ST_CRNM ( tropht, trop, ier )
	IF  ( ier .ne. 0 )  trop = 10000.
	CALL ST_CRNM ( delz, deltaz, ier )
	IF  ( ier .ne. 0 )  deltaz = 500.
	CALL ST_CRNM ( cldhgt, cldz, ier )
	IF  ( ier .ne. 0 )  cldz = 8000.
C
C*	Loop through the levels.
C
	DO  i = 1, nlevel
	    IF  ( .not. ERMISS(uabs(i  )) .and.
     +		  .not. ERMISS(uabs(i+1)) .and.
     +		  .not. ERMISS(uabs(i-1)) .and.
     +		  .not. ERMISS(vabs(i  )) .and.
     +		  .not. ERMISS(vabs(i+1)) .and.
     +		  .not. ERMISS(vabs(i-1)) )  THEN
		pres = hdata((i-1)*nparms+IPRES)
		rmix = PR_MIXR ( hdata((i-1)*nparms+IDWPT),
     +				 hdata((i-1)*nparms+IPRES) )
		tmpk = PR_TVRK ( hdata((i-1)*nparms+ITEMP),
     +				 hdata((i-1)*nparms+IDWPT),
     +				 hdata((i-1)*nparms+IPRES) )
C		tmpv = PR_TMKC ( tmpk )
C		dens = rmix * .34838 * pres / ( tmpv + 273.3 )
 		dens = .34838 * pres / tmpk 
C
		IF  ( i .ne. 1 .and. i .ne. nlevel )  THEN
C
C*		    Compute the shears for the level.
C
		    IF  ( ERMISS(uabs(i+1)) .or.
     +			  ERMISS(uabs(i-1)) )  THEN
			duz = RMISSD
			ruz = RMISSD
		    ELSE
			duz = ( uabs(i+1)-uabs(i-1) ) / (2.*deltaz)
			ruz = ( uabs(i+1)+uabs(i-1) ) / 2.
		    END IF
		    IF  ( ERMISS(vabs(i+1)) .or.
     +			  ERMISS(vabs(i-1)) )  THEN
			dvz = RMISSD
			rvz = RMISSD
		    ELSE
			dvz = ( vabs(i+1)-vabs(i-1) ) / (2.*deltaz)
			rvz = ( vabs(i+1)+vabs(i-1) ) / 2.
		    END IF
		    IF  ( .not. ERMISS(duz) .and.
     +			  .not. ERMISS(dvz) )  THEN
C
C*	    	    	Find the sums for the appropriate areas
C*		    	of the sounding.
C
C*		    	Surface to Cloud base.
C
			IF  (hdata((i-1)*nparms+IHGHT).le.hlcl)  THEN
			    sfc_cb_shu = sfc_cb_shu + duz * dens
			    sfc_cb_shv = sfc_cb_shv + dvz * dens
			    sfc_cb_sh  = sfc_cb_sh  +       dens
			END IF
C
C*		    	Cloud base to Cloud top.
C
			IF  (hdata((i-1)*nparms+IHGHT).ge.hlcl .and.
     +			     hdata((i-1)*nparms+IHGHT).le.cldz)  THEN
			    cb_ct_shu = cb_ct_shu + duz * dens
			    cb_ct_shv = cb_ct_shv + dvz * dens
			    cb_ct_sh  = cb_ct_sh  +       dens
			END IF
C
C*		    	Surface to Surface + 6 km.
C
			IF  ( hdata((i-1)*nparms+IHGHT) .le. 
     +			      hdata(0*nparms+IHGHT) + 6000. )  THEN
			    sfc_6_shu = sfc_6_shu + duz * dens
			    sfc_6_shv = sfc_6_shv + dvz * dens
			    sfc_6_sh  = sfc_6_sh  +       dens
			END IF
C
C*			Compute average wind in Surface to 
C*			Surface + 6 km layer.
C
			IF  ( hdata((i-1)*nparms+IHGHT) .le. 
     +			      hdata(0*nparms+IHGHT) + 6000. )  THEN
			    ske_6_shu = ske_6_shu + 
     +			    		( dens * ruz * deltaz )
			    ske_6_shv = ske_6_shv + 
     +			    		( dens * rvz * deltaz )
			    ske_6_sh  = ske_6_sh  + ( dens * deltaz )
			END IF
C
C*			Compute average wind in Surface to 
C*			Surface + 500m layer.
C
			IF  ( ( hdata((i-1)*nparms+IHGHT) .le. 
     +			        hdata(0*nparms+IHGHT) + 500. ) .and.
     +			      ( i .lt. 3 ) )  THEN
			    ske_S_shu = ske_S_shu + 
     +			    		( dens * ruz * deltaz )
			    ske_S_shv = ske_S_shv + 
     +			    		( dens * rvz * deltaz )
			    ske_S_sh  = ske_S_sh  + ( dens * deltaz )
			END IF
C
C*		    	Surface to Tropopause.
C
			IF  (hdata((i-1)*nparms+IHGHT).le.trop)  THEN
			    sfc_trp_shu = sfc_trp_shu + duz * dens
			    sfc_trp_shv = sfc_trp_shv + dvz * dens
			    sfc_trp_sh  = sfc_trp_sh  +       dens
			END IF
C
C*		    	Layers every 2000 m.
C
			index = (hdata((i-1)*nparms+IHGHT)-1000.)/
     +							    2000.+1
			IF  ( index .ge. 1 .and. index .le. 10 )  THEN
			    xlyr_shu(index) = xlyr_shu(index)+duz*dens
			    xlyr_shv(index) = xlyr_shv(index)+dvz*dens
			    xlyr_shn(index) = xlyr_shn(index)+    dens
			END IF
		    END IF
		END IF
C
C*		Surface to Cloud base.
C
		IF  ( hdata((i-1)*nparms+IHGHT) .le. hlcl )  THEN
		    sfc_cb_u = sfc_cb_u + uabs(i) * dens
		    sfc_cb_v = sfc_cb_v + vabs(i) * dens
		    sfc_cb_n = sfc_cb_n +           dens
		END IF
C
C*		Cloud base to Cloud top.
C
		IF  ( hdata((i-1)*nparms+IHGHT) .ge. hlcl .and.
     +		      hdata((i-1)*nparms+IHGHT) .le. cldz )  THEN
		    cb_ct_u = cb_ct_u + uabs(i) * dens
		    cb_ct_v = cb_ct_v + vabs(i) * dens
		    cb_ct_n = cb_ct_n +           dens
		END IF
	    END IF
	END DO
C
C*	Compute the average winds and shears.
C
	IF  ( sfc_cb_n .ne. 0. )  THEN
	    sfc_cb_um = sfc_cb_u / sfc_cb_n
	    sfc_cb_vm = sfc_cb_v / sfc_cb_n
	    sfc_cb_spd = PR_SPED ( sfc_cb_um, sfc_cb_vm )
	    sfc_cb_dir = PR_DRCT ( sfc_cb_um, sfc_cb_vm )
	END IF
	IF  ( sfc_cb_sh .ne. 0. )  THEN
	    sfc_cb_wtduz = sfc_cb_shu / sfc_cb_sh
	    sfc_cb_wtdvz = sfc_cb_shv / sfc_cb_sh
	    sfc_cb_shspd = PR_SPED ( sfc_cb_wtduz, sfc_cb_wtdvz )
	    sfc_cb_shdir = PR_DRCT ( sfc_cb_wtduz, sfc_cb_wtdvz )
	END IF
	IF  ( cb_ct_n .ne. 0. )  THEN
	    cb_ct_um = cb_ct_u / cb_ct_n
	    cb_ct_vm = cb_ct_v / cb_ct_n
	    cb_ct_spd = PR_SPED ( cb_ct_um, cb_ct_vm )
	    cb_ct_dir = PR_DRCT ( cb_ct_um, cb_ct_vm )
	END IF
	IF  ( cb_ct_sh .ne. 0. )  THEN
	    cb_ct_wtduz = cb_ct_shu / cb_ct_sh
	    cb_ct_wtdvz = cb_ct_shv / cb_ct_sh
	    cb_ct_shspd = PR_SPED ( cb_ct_wtduz, cb_ct_wtdvz )
	    cb_ct_shdir = PR_DRCT ( cb_ct_wtduz, cb_ct_wtdvz )
	END IF
	IF  ( sfc_6_sh .ne. 0. )  THEN
	    sfc_6_wtduz = sfc_6_shu / sfc_6_sh
	    sfc_6_wtdvz = sfc_6_shv / sfc_6_sh
	    sfc_6_shspd = PR_SPED ( sfc_6_wtduz, sfc_6_wtdvz )
	    sfc_6_shdir = PR_DRCT ( sfc_6_wtduz, sfc_6_wtdvz )
	END IF
	IF  ( ske_6_sh .ne. 0. )  THEN
	    ske_6_wtduz = ske_6_shu / ske_6_sh
	    ske_6_wtdvz = ske_6_shv / ske_6_sh
	    IF ( ske_S_sh .ne. 0 ) THEN
	        ske_S_wtduz = ske_S_shu / ske_S_sh
	        ske_S_wtdvz = ske_S_shv / ske_S_sh
	    ELSE
	        ske_S_wtduz = 0.
	        ske_S_wtdvz = 0.
	    END IF
	    ske_6S_wtduz = ( ske_6_wtduz - ske_S_wtduz ) / 6000.
	    ske_6S_wtdvz = ( ske_6_wtdvz - ske_S_wtdvz ) / 6000.
	    ske_6_shspd = PR_SPED ( ske_6S_wtduz, ske_6S_wtdvz )
	    ske_6_shdir = PR_DRCT ( ske_6S_wtduz, ske_6S_wtdvz )
	    ske = ( ( ( ske_6_wtduz - ske_S_wtduz ) * 
     +		      ( ske_6_wtduz - ske_S_wtduz ) ) +
     +	            ( ( ske_6_wtdvz - ske_S_wtdvz ) * 
     +		      ( ske_6_wtdvz - ske_S_wtdvz ) ) ) / 2.
	END IF
	IF  ( sfc_trp_sh .ne. 0. )  THEN
	    sfc_trp_wtduz = sfc_trp_shu / sfc_trp_sh
	    sfc_trp_wtdvz = sfc_trp_shv / sfc_trp_sh
	    sfc_trp_shspd = PR_SPED ( sfc_trp_wtduz, sfc_trp_wtdvz )
	    sfc_trp_shdir = PR_DRCT ( sfc_trp_wtduz, sfc_trp_wtdvz )
	END IF
	DO  k = 1, nlun
	    WRITE ( lun(k), 2000 )
	END DO
	DO  j = 1, 10
	    xlyru = 0.
	    xlyrv = 0.
	    IF  ( xlyr_shn(j) .ne. 0. )  THEN
		xlyru = xlyr_shu(j) / xlyr_shn(j)
		xlyrv = xlyr_shv(j) / xlyr_shn(j)
	    END IF
	    xlyrspd = PR_SPED ( xlyru, xlyrv )
	    xlyrdir = PR_DRCT ( xlyru, xlyrv )
	    xlyrbot = (j-1) * 2000. + 1000.
	    xlyrtop = xlyrbot + 2000.
	    DO  k = 1, nlun
		WRITE ( lun(k), 2010 )  xlyrbot, xlyrtop,
     +					xlyrspd, xlyrdir
	    END DO
	END DO
2000	FORMAT ( /, '          LAYER SHEARS',/ )
2010	FORMAT ( ' Layer from ',F10.2,' m to ',F10.2,' m',/,
     +           '       Shear Magnitude : ',E10.3,' /s',/,
     +           '       Shear Direction : ',F10.2,' degrees' )
C
C*	Write the remaining output.
C
	DO  k = 1, nlun
	    WRITE ( lun(k), 1000 ) trop, cldz, sfc_cb_spd, sfc_cb_dir, 
     +		sfc_cb_shspd, sfc_cb_shdir
	    WRITE ( lun(k), 1001 ) cb_ct_spd, cb_ct_dir, cb_ct_shspd, 
     +		cb_ct_shdir
	    WRITE ( lun(k), 1002 ) sfc_6_wtduz, sfc_6_wtdvz, 
     +		sfc_6_shspd, sfc_6_shdir,
     +		ske, ske_6_shspd, ske_6_shdir
	    WRITE ( lun(k), 1003 ) sfc_trp_wtduz, sfc_trp_wtdvz, 
     +		sfc_trp_shspd, sfc_trp_shdir
	END DO
1000	FORMAT ( /, '   WIND VECTORS AND SHEAR VECTORS',/,/,
     +              ' Tropopause Height : ',F10.2,' m',/,
     +              ' Cloud Top Height  : ',F10.2,' m',/,/,
     +              ' Sub-cloud layer (Surface --> LCL)',/,
     +              '     Wind Speed      : ',F10.2,' m/s',/,
     +              '     Wind Direction  : ',F10.2,' degrees',/,
     +              '     Shear Magnitude : ',E10.3,' /s',/,
     +              '     Shear Direction : ',F10.2,' degrees',/ )
1001	FORMAT (    ' Cloud layer (LCL --> Cloud Top)',/,
     +              '     Wind Speed      : ',F10.2,' m/s',/,
     +              '     Wind Direction  : ',F10.2,' degrees',/,
     +              '     Shear Magnitude : ',E10.3,' /s',/,
     +              '     Shear Direction : ',F10.2,' degrees',/ )
1002	FORMAT (    ' Surface --> 6 km',/,
     +              '     U - Component       : ',E10.3,' /s',/,
     +              '     V - Component       : ',E10.3,' /s',/,
     +              '     Shear Magnitude     : ',E10.3,' /s',/,
     +              '     Shear Direction     : ',F10.2,' degrees',/,
     +              '     SKE                 : ',E10.3,' /s',/,
     +              '     SKE Shear Magnitude : ',E10.3,' /s',/,
     +              '     SKE Shear Direction : ',F10.2,' degrees',/ )
1003	FORMAT (    ' Surface --> Tropopause',/,
     +              '     U - Component   : ',E10.3,' /s',/,
     +              '     V - Component   : ',E10.3,' /s',/,
     +              '     Shear Magnitude : ',E10.3,' /s',/,
     +              '     Shear Direction : ',F10.2,' degrees' )
C*
	RETURN
	END
