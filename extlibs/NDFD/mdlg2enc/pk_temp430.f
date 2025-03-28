      SUBROUTINE PK_TEMP430(KFILDO,IPACK,ND5,IS4,NS4,L3264B,
     1                      LOCN,IPOS,IER,*)
C
C        MARCH   2000   LAWRENCE   GSC/TDL   ORIGINAL CODING
C        JANUARY 2001   GLAHN      COMMENTS; IER = 941 CHANGED TO 403;
C                                  CHANGED ALGORITHM FOR CHECKING IS4( )
C                                  SIZE; IER = 403 CHANGED TO 402
C        JANUARY 2001   GLAHN/LAWRENCE CORRECTED ERROR IS4(42) TO
C                                  IS4(14) WHEN CHECKING FOR IS4( ) SIZE
C
C        PURPOSE
C            PACKS TEMPLATE 4.30 INTO PRODUCT DEFINITION SECTION 
C            OF A GRIB2 MESSAGE.  TEMPLATE 4.30 IS FOR A SATELLITE
C            PRODUCT. IT IS THE RESPONSIBILITY OF THE CALLING ROUTINE
C            TO PACK THE FIRST 9 OCTETS IN SECTION 4.
C
C        DATA SET USE
C           KFILDO - UNIT NUMBER FOR OUTPUT (PRINT) FILE. (OUTPUT)
C
C        VARIABLES
C              KFILDO = UNIT NUMBER FOR OUTPUT (PRINT) FILE. (INPUT)
C            IPACK(J) = THE ARRAY THAT HOLDS THE ACTUAL PACKED MESSAGE
C                       (J=1,ND5). (INPUT/OUTPUT)
C                 ND5 = THE SIZE OF THE ARRAY IPACK( ). (INPUT)
C              IS4(J) = CONTAINS THE PRODUCT DEFINITION INFORMATION
C                       FOR TEMPLATE 4.30 (IN ELEMENTS 10 THROUGH
C                       14 OR MORE, DEPENDING ON THE NUMBER OF BANDS,
C                       TO BE PACKED INTO IPACK( ) (J=1,NS4). (INPUT)
C                 NS4 = SIZE OF IS4( ). (INPUT)
C              L3264B = THE INTEGER WORD LENGTH IN BITS OF THE MACHINE
C                       BEING USED. VALUES OF 32 AND 64 ARE
C                       ACCOMMODATED. (INPUT)
C                LOCN = THE WORD POSITION TO PLACE THE NEXT VALUE.
C                       (INPUT/OUTPUT)
C                IPOS = THE BIT POSITION IN LOCN TO START PLACING
C                       THE NEXT VALUE. (INPUT/OUTPUT)
C                 IER = RETURN STATUS CODE. (OUTPUT)
C                        0 = GOOD RETURN.
C                       1-4 = ERROR CODES GENERATED BY PKBG. SEE THE 
C                             DOCUMENTATION IN THE PKBG ROUTINE.
C                       402 = IS4( ) HAS NOT BEEN DIMENSIONED LARGE
C                             ENOUGH TO CONTAIN THE ENTIRE TEMPLATE.
C                   * = ALTERNATE RETURN WHEN IER NE 0.
C
C             LOCAL VARIABLES
C               ISIZE = THE SMALLEST ALLOWABLE DIMENSION FOR IS4( )
C                       WHEN THE DATA FOR ALL OF THE CONTRIBUTING
C                       BANDS HAS BEEN ACCOUNTED FOR.
C             MINSIZE = THE SMALLEST ALLOWABLE DIMENSION FOR IS4( ).
C                   L = A LOOP INDEXING VARIABLE.
C                   M = AN ARRAY INDEXING VARIABLE.
C                   N = L3264B = THE INTEGER WORD LENGTH IN BITS OF
C                       THE MACHINE BEING USED. VALUES OF 32 AND
C                       64 ARE ACCOMMODATED.
C
C        NON SYSTEM SUBROUTINES CALLED
C           PKBG
C
      PARAMETER(MINSIZE=14)
C
      DIMENSION IPACK(ND5), IS4(NS4)
C
      N=L3264B
      IER=0
C
C        CHECK THE DIMENSIONS OF IS4( ).
C
      IF(NS4.LT.MINSIZE)THEN
D        WRITE(KFILDO,10)NS4,MINSIZE
D10      FORMAT(/' IS4( ) IS CURRENTLY DIMENSIONED TO CONTAIN'/
D    1           ' NS4=',I4,' ELEMENTS. THIS ARRAY MUST BE'/
D    2           ' DIMENSIONED TO AT LEAST ',I4,' ELEMENTS'/
D    3           ' TO CONTAIN ALL OF THE DATA IN PRODUCT'/
D    4           ' DEFINITION TEMPLATE 4.30.'/)
         IER=402
      ELSE
C
C           PACK THE PARAMETER CATEGORY.
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(10),8,N,IER,*900)
C
C           PACK THE PARAMETER NUMBER.
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(11),8,N,IER,*900)
C
C           PACK THE TYPE OF GENERATING PROCESS. 
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(12),8,N,IER,*900)
C
C           PACK THE OBSERVATION GENERATING PROCESS IDENTIFIER.
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(13),8,N,IER,*900)
C
C           PACK THE NUMBER OF CONTRIBUTING BANDS.
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(14),8,N,IER,*900)
C
C           CHECK TO MAKE SURE THAT IS4( ) WAS DIMENSIONED
C           LARGE ENOUGH TO CONTAIN THE DATA FOR ALL OF THE
C           CONTRIBUTING BANDS.
C
         IF(NS4.LT.MINSIZE+10*(IS4(14))-3)THEN
            IER=402
C
D           WRITE(KFILDO,20)NS4,ISIZE
D20         FORMAT(/' IS4( ) IS CURRENTLY DIMENSIONED TO CONTAIN'/
D    1              ' NS4=',I4,' ELEMENTS. THIS ARRAY MUST BE'/
D    2              ' DIMENSIONED TO AT LEAST ',I4,' ELEMENTS'/
D    3              ' TO CONTAIN ALL OF THE CONTRIBUTING BAND DATA'/
D    4              ' IN PRODUCT DEFINITION TEMPLATE 4.30.'/)
         ELSE
C
C              FOR EACH OF THE CONTRIBUTING BANDS
C              (INDICATED IN IS4(14)) PACK 5 VALUES.
C
            DO L=1,IS4(14)
               M = 15 + 10*(L-1)
               CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(M),16,N,
     1                   IER,*900)
               CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(M+2),16,N,
     1                   IER,*900)
               CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(M+4),8,N,
     1                   IER,*900)
               CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(M+5),8,N,
     1                   IER,*900)
               CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(M+6),32,N,
     1                   IER,*900)
            ENDDO
C
         ENDIF
C
      ENDIF
C
C       ERROR RETURN SECTION
 900  IF(IER.NE.0)RETURN 1
C
      RETURN
      END
