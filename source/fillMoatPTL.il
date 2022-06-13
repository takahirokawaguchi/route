(defun fillMoatADP (cellViewId libName)
  (let ( cellbBox
         masterCellViewId
         llX llY urX urY
         lenX lenY
         moatArray
         cellSize xCell yCell corners
         llxCell llyCell urxCell uryCell x y
         (ignoreLibs '( "analogJJ" "basic" ))
         (ignoreCells '( "sfqdc*" "dcsfq*" "ipin" "opin" "^PTL*" "via*" ))
         ( SFQLayoutSymbolUnitLength 0.375)
         )

    (unless libName
      (setq libName
        guessRefLibId( cellViewId )~>name))

    ; check if the moat cell exists
    (if masterCellViewId = 
      (dbOpenCellViewByType
        ;guessRefLibId( cellViewId )~>name
        libName
        "moat"
        "symbol_p"
        nil
        "r")
      then
      ; calculate the number of cells in x and y-axis
      cellbBox = getCellViewbBoxADP( cellViewId SFQLayoutSymbolUnitLength ignoreLibs ignoreCells)
      llX = xCoord( lowerLeft( cellbBox ) )
      llY = yCoord( lowerLeft( cellbBox ) )
      urX = xCoord( upperRight( cellbBox ) )
      urY = yCoord( upperRight( cellbBox ) )

      lenX = floor( (urX - llX) / SFQLayoutSymbolUnitLength )
      lenY = floor( (urY - llY) / SFQLayoutSymbolUnitLength )

      ; declare 2D array for moat filling
      moatArray = makeMoatArray( lenX lenY )
      (for indexY 0 lenY-1
           (for indexX 0 lenX-1
                moatArray[indexX][indexY] = t
                ))

      ; set moatArray t if a cell exists
      (foreach
        inst cellViewId~>instances
        (when !member( inst~>libName ignoreLibs ) &&
          !member( t foreach( mapcar cell ignoreCells
                                     rexMatchp( cell inst~>cellName ) ) )

          ; calculate the lower-left and upper-right coordinates of the instance
          cellbBox = getCellbBoxADP( inst SFQLayoutSymbolUnitLength)
          llxCell = xCoord( lowerLeft( cellbBox ) )
          llyCell = yCoord( lowerLeft( cellbBox ) )
          urxCell = xCoord( upperRight( cellbBox ) )
          uryCell = yCoord( upperRight( cellbBox ) )

          ; set moatArray t in accordnace with the cell coordinates
          (for indexY floor( ( llyCell - llY )/SFQLayoutSymbolUnitLength )
               floor( ( uryCell - llY )/SFQLayoutSymbolUnitLength ) - 1
               (for indexX floor( ( llxCell - llX )/SFQLayoutSymbolUnitLength )
                    floor( ( urxCell - llX )/SFQLayoutSymbolUnitLength ) - 1
                    moatArray[indexX][indexY]=nil
                    ))))

      ; read moatArray and place a moat if moatArray==t
      (for indexY 0 lenY-1
           (for indexX 0 lenX-1
                (when moatArray[indexX][indexY]
                  (dbCreateInst cellViewId
                                masterCellViewId
                                nil
                                llX+indexX*SFQLayoutSymbolUnitLength:
                                llY+indexY*SFQLayoutSymbolUnitLength
                                "R0"
                                ))))
      else
      ; uless a moat cannot find in the cell libaray
      (printf "Error: Cannot find a moat cell in Lib: %s"
              (guessRefLib cellViewId )~>name )
      )))

;   returns the lower-left and upper-right coordinates of the instances
;   in the cellView.
(defun getCellViewbBoxADP (cellViewId SFQLayoutSymbolUnitLength ignoreLibs ignoreCells)
  (let ( ; do not consider cells in ignoreLibs or that matches to ignoreCells
         cellbBox
         llx lly urx ury
         llxCell llyCell urxCell uryCell
         llxInst
         )

    (foreach inst cellViewId~>instances
             (when (null (member inst~>libName ignoreLibs )) &&
               (null (orList (mapcar (lambda (x) (rexMatchp x inst~>cellName ))
                                     ignoreCells)))

               cellbBox = getCellbBoxADP( inst SFQLayoutSymbolUnitLength)
               llxCell = xCoord( lowerLeft( cellbBox ) )
               llyCell = yCoord( lowerLeft( cellbBox ) )
               urxCell = xCoord( upperRight( cellbBox ) )
               uryCell = yCoord( upperRight( cellbBox ) )

               ; initial assignment
               !llx && (llx = llxCell)
               !lly && (lly = llyCell)
               !urx && (urx = urxCell)
               !ury && (ury = uryCell)

               llxCell && llx && llx>llxCell && (llx = llxCell)
               llyCell && lly && lly>llyCell && (lly = llyCell)
               urxCell && urx && urx<urxCell && (urx = urxCell)
               uryCell && ury && ury<uryCell && (ury = uryCell)
               ))
    (list llx:lly urx:ury)
    ))

; declare 2D array
(defun makeMoatArray (nX nY)
  (let ( xArray x )
    (declare xArray[ nX ] )
    (for i 0 nX-1
         declare( x[ nY ] )
         xArray[ i ] = x
         )
    xArray
    ))

; getCellbBoxADP( inst )
; => ( llx:lly urx:ury ) in cellView
(defun getCellbBoxADP ( inst SFQLayoutSymbolUnitLength )
  (let ( cellSize xCell yCell corners llxCell llyCell urxCell uryCell x y )
    (when (isPTL inst)
      (setq SFQLayoutSymbolUnitLength SFQLayoutSymbolUnitLength/2.0))
    (if cellSize = getCellSize( inst~>master )
      then
      xCell = xCoord( cellSize ) * SFQLayoutSymbolUnitLength
      yCell = yCoord( cellSize ) * SFQLayoutSymbolUnitLength
      corners = list( 0:0 xCell:0 xCell:yCell 0:yCell )
      corners = foreach( mapcar corner corners
                                rotateXY( corner inst~>orient ) )
      llxCell = xCoord( car( corners ) )
      llyCell = yCoord( car( corners ) )
      urxCell = xCoord( car( corners ) )
      uryCell = yCoord( car( corners ) )

      (foreach corner corners
               (when llxCell>xCoord( corner )
                 llxCell = xCoord( corner )
                 ); when
               (when llyCell>yCoord( corner )
                 llyCell = yCoord( corner )
                 ); when
               (when urxCell<xCoord( corner )
                 urxCell = xCoord( corner )
                 ); when
               (when uryCell<yCoord( corner )
                 uryCell = yCoord( corner )
                 ))

      x = xCoord( inst~>xy )
      y = yCoord( inst~>xy )

      llxCell = llxCell + x
      llyCell = llyCell + y
      urxCell = urxCell + x
      uryCell = uryCell + y
      list( llxCell:llyCell urxCell:uryCell )
      else
      nil
      )))

(defun getCellSizeADP (cellViewId SFQLayoutSymbolUnitLength)
  (let ( bBox x y xu yu cellViewId)
    (if cellViewId~>viewName=="symbol_p" ||
      cellViewId~>viewName=="symbol_b" 
      then
      if( bBox = car( setof( s cellViewId~>shapes
                               s~>layerName=="instance" &&
                               s~>purpose=="drawing" &&
                               s~>objType=="rect" ) ) ~> bBox
               then
               x = xCoord( upperRight( bBox ) ) - xCoord( lowerLeft( bBox ) )
               y = yCoord( upperRight( bBox ) ) - yCoord( lowerLeft( bBox ) )
               xu = round(x/SFQLayoutSymbolUnitLength)
               yu = round(y/SFQLayoutSymbolUnitLength)
               list( xu yu )
               else
               printf("Warning: No selection box is found in symbol_p of %s in %s. "
                      cellViewId ~>cellName cellViewId~>libName )
               printf("Guessing...")
               if( bBox = car( setof( s cellViewId~>shapes
                                        s~>layerName=="device" &&
                                        s~>purpose=="drawing" &&
                                        lowerLeft( s~>bBox )=='(0 0) ) ) ~> bBox
                        then
                        x = xCoord( upperRight( bBox ) ) - xCoord( lowerLeft( bBox ) )
                        y = yCoord( upperRight( bBox ) ) - yCoord( lowerLeft( bBox ) )
                        xu = round(x/SFQLayoutSymbolUnitLength)
                        yu = round(y/SFQLayoutSymbolUnitLength)
                        printf("(%d %d).\n" xu yu)
                        list( xu yu )
                        else
                        printf(" failed.\n")
                        nil
                        ))
      else
      nil
      )))
