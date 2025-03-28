#include "df.h"

#define DEG            57.3

void df_ncle ( int *iret )
/************************************************************************
 * df_ncle								*
 *									*
 * This subroutine computes NCLE (S,T,ROI), the neighborhood count      *
 * coverage of a scalar field (S) less than or equal to some            *
 * threshold (T) within some radius of influence (ROI; meters).         *
 *									*
 * df_ncle ( iret )							*
 *									*
 * Output parameters:							*
 *	*iret		int		Return code			*
 *					As for DG_GETS			*
 **									*
 * Log:									*
 * C. Melick/SPC	09/16						*
 ************************************************************************/
{
    int num1, num2, num3, num4, num5, num, kxd, kyd, ksub1, ksub2, zero, indx, ier;
    int ixmscl, iymscl, jgymin, jgymax, jgxmin, jgxmax, idglat, idglon;
    int row, col, ibeg, iend, jbeg, jend, ibox, jbox, boxindx, nval;
    int kgxmin, kgymin, kgxmax, kgymax;
    float  gddx, gddy, gdspdx, gdspdy, radius, thresh;
    float *gnum1, *gnumt, *gnumn, *gkxms, *gkyms, *gnumroi, *glat, *glon, *dist;   
    float *nearby, rmin, rmax, ravg, rdev;
/*----------------------------------------------------------------------*/
    *iret = 0;
    zero = 0;

    dg_ssub ( iret );

    /*
     * Compute map scale factors.
     */
    dg_mscl ( iret );
    if ( *iret != 0 ) return;

    /*
     * Query DGCMN.CMN idglat/idglon.
    */
     
    nval = 1;
    dg_iget ( "IDGLAT", &nval, &idglat, iret );
    if ( *iret != 0 ) return;
    dg_iget ( "IDGLON", &nval, &idglon, iret );
    if ( *iret != 0 ) return;

    /*
     * Get the grids from the stack.
     */
    dg_gets ( &num1, iret );
    if ( *iret != 0 ) return;
    dg_gets ( &num2, iret );
    if ( *iret != 0 ) return;
    dg_gets ( &num3, iret );
    if ( *iret != 0 ) return;

    /*
     * Get new grid numbers.
     */
    dg_nxts ( &num4, iret );
    if ( *iret != 0 ) return; 
    dg_nxts ( &num5, iret );
    if ( *iret != 0 ) return; 
    dg_nxts ( &num, iret );
    if ( *iret != 0 ) return;

    dg_qmsl ( &ixmscl, &iymscl, &gddx, &gddy, &ier );
    dg_qbnd ( &jgxmin, &jgxmax, &jgymin, &jgymax, &ier );   
    dg_getg ( &num1, &gnum1, &kxd, &kyd, &ksub1, &ksub2, &ier );
    dg_getg ( &num,  &gnumn,  &kxd, &kyd, &ksub1, &ksub2, &ier );
    dg_getg ( &ixmscl, &gkxms, &kxd, &kyd, &ksub1, &ksub2, &ier );
    dg_getg ( &iymscl, &gkyms, &kxd, &kyd, &ksub1, &ksub2, &ier );
    dg_getg ( &num2, &gnumt, &kxd, &kyd, &ksub1, &ksub2, &ier ); 
    dg_getg ( &idglat, &glat, &kxd, &kyd, &ksub1, &ksub2, &ier );
    dg_getg ( &idglon, &glon, &kxd, &kyd, &ksub1, &ksub2, &ier ); 
    dg_getg ( &num3, &gnumroi, &kxd, &kyd, &ksub1, &ksub2, &ier );
    dg_getg ( &num4, &dist, &kxd, &kyd, &ksub1, &ksub2, &ier ); 
    dg_getg ( &num5, &nearby, &kxd, &kyd, &ksub1, &ksub2, &ier ); 

    radius = gnumroi[0];
    thresh = gnumt[0];

    /*  QC check on lower and upper bounds of radius of influence.  */

    if ( radius < 0 ) {
         radius = 0.0;
         printf ("\n WARNING : RADIUS value less than zero.  "
                 "Resetting to zero.\n");
    }

    if ( radius > 0.5*gddx*(float)(kxd)) {
         radius = 0.5*gddx*(float)(kxd);
         printf ("\n WARNING : RADIUS value too high.  "
                 "Resetting to half the distance in X (%f meters).\n",radius);
    } 


    /*
     * Use GR_STAT to find the grid maximum and minimum.
     */
    dg_iget ( "KGXMIN", &nval, &kgxmin, iret );
    dg_iget ( "KGYMIN", &nval, &kgymin, iret );
    dg_iget ( "KGXMAX", &nval, &kgxmax, iret );
    dg_iget ( "KGYMAX", &nval, &kgymax, iret );

    grc_stat ( gnum1, &kxd, &kyd, &kgxmin, &kgymin, &kgxmax, &kgymax,
              &rmin, &rmax, &ravg, &rdev, &ier );


    /*
     * Loop over all grid points to initialize output grid.
     */
    for ( row = jgymin; row <= jgymax; row++ ) {
	for ( col = jgxmin; col <= jgxmax; col++ ) {
            indx=(row-1)*kxd+(col-1);
            nearby[indx] = 0;
            if ( ERMISS ( gnum1[indx] ) || ( thresh >= rmax ) ) {
		gnumn[indx] = RMISSD;
            } else {
                gnumn[indx] = 0.0;
            }
        }
    }

    /*
     * Loop over all grid points to determine neighborhood count coverage if threshold falls between rmin and rmax. 
     */

if ( ( thresh >= rmin ) && ( thresh < rmax ) ) {
    for ( row = jgymin; row <= jgymax; row++ ) {
       for ( col = jgxmin; col <= jgxmax; col++ ) {
         indx=(row-1)*kxd+(col-1);
         if ( ! ERMISS ( gnum1[indx] ) ) {
            if ( gnum1[indx] <= thresh ) {
                gdspdx= gddx / gkxms[indx];
                gdspdy= gddy / gkyms[indx];
    
       /*  Constructing box for each grid point */
                ibeg = col- G_NINT(radius / gdspdx);
                iend = col+ G_NINT(radius / gdspdx);
                jbeg = row- G_NINT(radius / gdspdy);
                jend = row+ G_NINT(radius / gdspdy);
                if (ibeg < jgxmin) {
                   ibeg = jgxmin;
                }
                if (iend > jgxmax) {
                   iend = jgxmax;
                }
                if (jbeg < jgymin) {
                   jbeg = jgymin;
                }
                if (jend > jgymax) {
                   jend = jgymax;
                }
                for ( ibox = ibeg; ibox <= iend; ibox++ ) {
                    for ( jbox = jbeg; jbox <= jend; jbox++ ) {
                        boxindx=(jbox-1)*kxd+(ibox-1);
                        if ((glat[indx] == glat[boxindx]) && (glon[indx] == glon[boxindx])) {
                            dist[boxindx]=0.0;
                        } else {
        /* Great Circle Distance calculation */
                            dist[boxindx] = acos(sin(glat[boxindx])*sin(glat[indx]) + cos(glat[boxindx])*cos(glat[indx])*cos((glon[boxindx])-(glon[indx])));
                            dist[boxindx] = RADIUS * dist[boxindx];
                        }
/* Calculate count if neighboring point is defined and within radius of influence. */
                        if ( (dist[boxindx] <= radius) && (! ERMISS ( gnum1[boxindx] ) ) ) { 

                            if  ( gnum1[boxindx] <= thresh ) { 
                                gnumn[indx] = gnumn[indx] + 1;
                            } else {
                            /* Grid point is nearby one meeting threshold  */
                                nearby[boxindx] = 1; 
                            }
                        }   
                    }
                }
             }
           }
         }
      }
      
    for ( row = jgymin; row <= jgymax; row++ ) {
       for ( col = jgxmin; col <= jgxmax; col++ ) {
         indx=(row-1)*kxd+(col-1);
         if ( ! ERMISS ( gnum1[indx] ) && nearby[indx] == 1 ) {
                gdspdx= gddx / gkxms[indx];
                gdspdx= gddx / gkxms[indx];
                gdspdy= gddy / gkyms[indx];
    
       /*  Constructing box for each grid point */
                ibeg = col- G_NINT(radius / gdspdx);
                iend = col+ G_NINT(radius / gdspdx);
                jbeg = row- G_NINT(radius / gdspdy);
                jend = row+ G_NINT(radius / gdspdy);
                if (ibeg < jgxmin) {
                   ibeg = jgxmin;
                }
                if (iend > jgxmax) {
                   iend = jgxmax;
                }
                if (jbeg < jgymin) {
                   jbeg = jgymin;
                }
                if (jend > jgymax) {
                   jend = jgymax;
                }
                for ( ibox = ibeg; ibox <= iend; ibox++ ) {
                    for ( jbox = jbeg; jbox <= jend; jbox++ ) {
                        boxindx=(jbox-1)*kxd+(ibox-1);
                        if ((glat[indx] == glat[boxindx]) && (glon[indx] == glon[boxindx])) {
                            dist[boxindx]=0.0;
                        } else {
        /* Great Circle Distance calculation */
                            dist[boxindx] = acos(sin(glat[boxindx])*sin(glat[indx]) + cos(glat[boxindx])*cos(glat[indx])*cos((glon[boxindx])-(glon[indx])));
                            dist[boxindx] = RADIUS * dist[boxindx];
                        }
/* Calculate count if neighboring point is defined and within radius of influence. */
                        if ( (dist[boxindx] <= radius) && (! ERMISS ( gnum1[boxindx] ) ) ) { 
                            if  ( gnum1[boxindx] <= thresh ) { 
                                gnumn[indx] = gnumn[indx] + 1;
                            }
                        }   
                    }
                }
             }
           }
         }
  }

    /*
     * Make a name of the form 'NCLE'//S and update header;
     * update stack.
     */
    dg_updh ( "NCLE", &num, &num1, &num2, iret );
    dg_puts ( &num, iret );
    dg_esub ( &num, &zero, &zero, &zero, &ier );
    if ( ier != 0 ) *iret = ier;

    return;
} 
