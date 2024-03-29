;(load "~/git/route/source/rRouteAll.il")
;(mload "~/git/route/source/")
;(setq scv (geGetWindowCellView ))

(defvar RINER)
(setplist 'RINER
          '(ROUTER_COMMAND
             ""
             SCHEM_GRID_LEN 0.1875
             SCHEM_GRID_OFFSET 0.0625
             SCHEM_PIN_WIDTH 0.05       
             PHYSC_GRID_LEN 15
             PTL1_PATH_WIDTH 0.0875
             PTL1_COLOR "tan"
             PTL2_PATH_WIDTH 0.075
             PTL2_COLOR "MediumVioletRed"
             LGC_PATH_WIDTH  0.0625
             CELL_BNDRY_LPP ("device" "drawing")
             WIRE_LPP       ("wire" "drawing")
             BNDRY_LPP      ("Unrouted" "drawing4")
             GRID_LPP       ("hilite" "drawing4")
             ERR_LPP        ("marker" "warning")
             BNDRY_HL_SET   nil
             GRID_HL_SET    nil
             ERR_HL_SET     nil
             LGC            0
             PTL2           1
             PTL1           2
             VIA            (1 2)
             PIN            3
             DEFAULT_PIN_LAYER 1
             SEARCH_REGION_EXPANSION 7
             REGARDING_FLOATING_PIN_AS_BLOCKAGE nil
             REGARDING_DRVsandRECs_AS_BLOCKAGE t
             REGARDING_UNROUTED_PIN_AS_BLOCKAGE t
             SHOWING_DIALOGS t
             ))
(let (s)
  (sprintf s "java -server -jar %s/tools/dfII/local/lib/skill/route/source/sfqcad.riner114v2.jar -p %s/tools/dfII/local/lib/skill/route/source/adp.prcs -r ./out.riner --num_RRR_loop 100"
           (getShellEnvVar "CDS_INST_DIR")
           (getShellEnvVar "CDS_INST_DIR")
           )
  RINER.ROUTER_COMMAND = s)


(defun rRoute (scv flagSelNet)
  (let ( nets
         netCoords
         boundary
         blockages
         res)
    (setq nets (selRoutingNets scv flagSelNet))
    (printf "number of routing net is %d.\n" (length nets))
    (setq boundary (roGetBoundary (ruSBBtoGBB scv~>bBox)))
    (setq netCoords (getAllNetCoords nets))
    (setq blockages (append blockages (roGetGridsAroundDRVsandRECs scv boundary)))
    (roWriteFile netCoords boundary blockages)
    (setq res (riReadRouterOut))
    (foreach net nets
             (foreach fig net~>figs
                      (dbDeleteObject fig)))
    (deleteNetConnectedPin scv)
    (rCreateWireAll scv "./in.riner" nets)
    ))

;util

(defun deleteNetConnectedPin (scv)
  (foreach netCpin (setof x scv~>nets (andList x~>pins))
           (foreach fig netCpin~>figs
                    (dbDeleteObject fig))))


(defun selRoutingNets (scv flagSelNet)
  (cond
    ((equal flagSelNet "all")
     (setof n scv~>nets (and n~>figs
                             ;(andList n~>instTerms~>inst)
                             (equal (length n~>instTerms) 2)
                             (andList (mapcar 'isPTLDrvRec n~>instTerms~>inst))
                             ;(or 
                             ;  (and (isPTLDrv (car n~>instTerms~>inst))
                             ;       (isPTLRec (cadr n~>instTerms~>inst)))
                             ;  (and (isPTLRec (car n~>instTerms~>inst))
                             ;       (isPTLDrv (cadr n~>instTerms~>inst)))
                             ;  )
                             (andList (mapcar 'isPTLDrvRec n~>instTerms~>inst)))))
    ((equal flagSelNet "selected")
     (let (figs)
       ;(setq figs (setof x (geGetSelSet ) (equal x~>objType "line")))
       (setq figs
             (setof n (geGetSelSet )
                    (and (equal n~>objType "line")
                         n~>net
                         (andList n~>net~>instTerms~>inst)
                         (andList (mapcar 'isPTLDrvRec n~>net~>instTerms~>inst)))))
       (setOfList figs~>net)))))

(defun rhGetPointsOfConnection ()
  (enterSegment
    ?prompts (list "Point at starting point for the router."
                   "Point at ending point for the router.")))
(defun ruGCtoSC (gcoord)
  (mapcar (lambda (x) (RINER.SCHEM_GRID_LEN / 2 + x * RINER.SCHEM_GRID_LEN)) gcoord))
(defun ruSCtoGC (scoord)
  (mapcar (lambda (x) (floor (x / RINER.SCHEM_GRID_LEN))) scoord))
(defun ruSBBtoGBB (sbb)
  (list (ruSCtoGC (lowerLeft sbb)) (ruSCtoGC (upperRight sbb))))
(defun ruGCtosSBB (gcoord)
  (list (mapcar '(lambda (x) (x * RINER.SCHEM_GRID_LEN + 0.01)) gcoord)
        (mapcar '(lambda (x) ((x + 1) * RINER.SCHEM_GRID_LEN - 0.01)) gcoord)))
(defun getAllNetCoords (nets)
  (mapcar '(lambda (itpair) (mapcar 'getInstTermGridCoord itpair)) nets~>instTerms))
(defun roGetBoundary (points)
  (mapcar
    '(lambda (x)
       (mapcar
         '(lambda (x) (cond (x < 0 0)
                            (t x)
                            ))
         x))
    (ruExpandBBox (ruApporopriateBBox points))))

(defun ruExpandBBox (rb)
  (cond
    ((greaterp RINER.SEARCH_REGION_EXPANSION 0)
     (list
       (list ((caar rb) - RINER.SEARCH_REGION_EXPANSION)
             ((cadar rb) - RINER.SEARCH_REGION_EXPANSION))
       (list ((caadr rb) + RINER.SEARCH_REGION_EXPANSION)
             ((cadadr rb) + RINER.SEARCH_REGION_EXPANSION))))
    (t rb)))

(defun ruApporopriateBBox (region)
  (list
    (list (min (caar region) (caadr region))
          (min (cadar region) (cadadr region)))
    (list (max (caar region) (caadr region))
          (max (cadar region) (cadadr region)))))

(defun isPTLWire (net)
  (andList (mapcar (lambda (x) (or (equal x~>width 0.075)
                                   (equal x~>width 0.0875)))
                   net~>figs)))

(defun undoPTLWire (scv)
  ;(printf "%L\n" (setof y scv~>nets (isPTLWire y))~>instTerms)
  (foreach x (setof y scv~>nets 
                    (and
                      ;(isPTLWire y)
                      (equal (length y~>instTerms) 2)
                      ))
           (reRoute x)))

(defun backTrackPTLDrv (outputTerm)
  (cond
    ((isPTLFamily outputTerm~>inst)
     (if (and (car (car (inputTerms outputTerm~>inst))~>net~>pins)
              (isIpin (caar (car (inputTerms outputTerm~>inst))~>net~>pins~>figs)))
       then
       (caar (car (inputTerms outputTerm~>inst))~>net~>pins~>figs)
       else
       (backTrackPTLDrv 
         (car (outputTermsConnected (car (inputTerms outputTerm~>inst)))))))
    ((or
       (isPTLDrv outputTerm~>inst)
       (isPspl outputTerm~>inst))
     outputTerm
     )))

(defun frontTrackPTLRec (outputTerm)
  (let (inputTerm)
    (setq inputTerm
          (car (inputTermsConnected outputTerm)))
    (cond
      ((not inputTerm)
       nil)
      ((or (isPTL inputTerm~>inst)
           (isPTLDrv inputTerm~>inst)
           (isPspl inputTerm~>inst)
           )
       (cons inputTerm~>inst
             (frontTrackPTLRec
               (car (outputTerms inputTerm~>inst)))
             ))
      ((isPTLRec inputTerm~>inst)
       (list inputTerm~>inst)
       ))))

(defun undoPTLCellAll ()
  (let (scv)
    (setq scv (geGetWindowCellView ))
    (mapcar 'undoPTLCell (setof x scv~>instances (isPTL x)))
))

(defun undoPTLCell (cell)
  (let (ep listLayer tmp)
    (when (and (equal cell~>objType "inst")
               (isPTL cell))
      (cond 
        ((equal (ptlType cell) "PTL1")
         (setq listLayer
               (list
                 (list RINER.PTL1_COLOR RINER.PTL1_PATH_WIDTH)
                 (list RINER.PTL1_COLOR RINER.PTL1_PATH_WIDTH)
                 )))
        ((equal (ptlType cell) "PTL2")
         (setq listLayer
               (list
                 (list RINER.PTL2_COLOR RINER.PTL2_PATH_WIDTH)
                 (list RINER.PTL2_COLOR RINER.PTL2_PATH_WIDTH)
                 )))
        ((equal (ptlType cell) "via")
         (setq listLayer
               (list
                 (list RINER.PTL2_COLOR RINER.PTL2_PATH_WIDTH)
                 (list RINER.PTL1_COLOR RINER.PTL1_PATH_WIDTH)
                 )))
        ((equal (ptlType cell) "viar")
         (setq listLayer
               (list
                 (list RINER.PTL1_COLOR RINER.PTL1_PATH_WIDTH)
                 (list RINER.PTL2_COLOR RINER.PTL2_PATH_WIDTH)
                 )))
        )
      (setq ep (mapcar 'getInstTermCoord
                       (list
                         (car (inputTerms cell))
                         (car (outputTerms cell))) 
                       ))
      (if (or 
            (equal (yCoord (car ep))
                   (yCoord (lowerLeft (getCellbBoxADP cell 0.375))))
            (equal (yCoord (car ep))
                   (yCoord (upperRight (getCellbBoxADP cell 0.375))))
            )
        then
        (progn
          (if (or (equal "via" cell~>cellName)
                  (equal "viar" cell~>cellName))
            (setq tmp (min (yCoord (car ep)) (yCoord (cadr ep)))
                  + RINER.SCHEM_GRID_LEN/2.0)
            (setq tmp (yCoord (cadr ep)))
            )
          (schCreateWire
            scv
            "route"
            "direct"
            (list (car ep)
                  (list (xCoord (car ep)) tmp))
            0
            0
            (cadr (car listLayer))
            (car (car listLayer))
            )
          (schCreateWire
            scv
            "route"
            "direct"
            (list (list (xCoord (car ep)) tmp)
                  (cadr ep))
            0
            0
            (cadr (cadr listLayer))
            (car (cadr listLayer))
            )
          )
        else
        (progn
          (if (or (equal "via" cell~>cellName)
                  (equal "viar" cell~>cellName))
            (setq tmp (min (xCoord (car ep)) (xCoord (cadr ep)))
                  + RINER.SCHEM_GRID_LEN/2.0)
            (setq tmp (xCoord (cadr ep)))
            )
          (schCreateWire
            scv
            "route"
            "direct"
            (list (car ep)
                  (list tmp (yCoord (car ep))))
            0
            0
            (cadr (car listLayer))
            (car (car listLayer))
            )
          (schCreateWire
            scv
            "route"
            "direct"
            (list (list tmp (yCoord (car ep)))
                  (cadr ep))
            0
            0
            (cadr (cadr listLayer))
            (car (cadr listLayer))
            )
          )
        )
      (dbDeleteObject cell)
      )))


(defun undoPTLCellSelected ()
  (let (scv drvTerms cells recTerms ptls ep listLayer tmp)
    (setq scv (geGetWindowCellView ))
    (setq cells (geGetSelSet ))
    (setq cells (setof x cells 
                       (and 
                         x~>purpose=="cell"
                         (or
                           (isPTL x)
                           (isPTLDrvRec x))
                         )))
    (setq drvTerms nil)
    (foreach x cells
             (setq drvTerms (append (mapcar 'backTrackPTLDrv (outputTerms x))
                                    drvTerms)))
    (setq drvTerms (setOfList drvTerms))
    (setq drvTerms (setof x drvTerms 
                          (or
                            (isIpin x)
                            (and
                              (isPTLDrvRec x~>inst)
                              (andList
                                (mapcar 'isPTL
                                        (inputTermsConnected x)~>inst 
                                        ))))))
    (foreach drvTerm drvTerms
             (setq ptls (frontTrackPTLRec drvTerm))
             (setq ptls (setof x ptls (and
                                        (not (isPTLDrv x))
                                        (not (isPspl x))
                                        (not (isPTLRec x)))))
             (foreach
               x ptls 
               (cond 
                 ((equal (ptlType x) "PTL1")
                  (setq listLayer
                        (list
                          (list RINER.PTL1_COLOR RINER.PTL1_PATH_WIDTH)
                          (list RINER.PTL1_COLOR RINER.PTL1_PATH_WIDTH)
                          )))
                 ((equal (ptlType x) "PTL2")
                  (setq listLayer
                        (list
                          (list RINER.PTL2_COLOR RINER.PTL2_PATH_WIDTH)
                          (list RINER.PTL2_COLOR RINER.PTL2_PATH_WIDTH)
                          )))
                 ((equal (ptlType x) "via")
                  (setq listLayer
                        (list
                          (list RINER.PTL2_COLOR RINER.PTL2_PATH_WIDTH)
                          (list RINER.PTL1_COLOR RINER.PTL1_PATH_WIDTH)
                          )))
                 ((equal (ptlType x) "viar")
                  (setq listLayer
                        (list
                          (list RINER.PTL1_COLOR RINER.PTL1_PATH_WIDTH)
                          (list RINER.PTL2_COLOR RINER.PTL2_PATH_WIDTH)
                          )))
                 )
               (setq ep (mapcar 'getInstTermCoord
                                (list
                                  (car (inputTerms x))
                                  (car (outputTerms x))) 
                                ))
               (if (or 
                     (equal (yCoord (car ep))
                            (yCoord (lowerLeft (getCellbBoxADP x 0.375))))
                     (equal (yCoord (car ep))
                            (yCoord (upperRight (getCellbBoxADP x 0.375))))
                     )
                 then
                 (progn
                   (if (or (equal "via" x~>cellName)
                           (equal "viar" x~>cellName))
                     (setq tmp (min (yCoord (car ep)) (yCoord (cadr ep)))
                           + RINER.SCHEM_GRID_LEN/2.0)
                     (setq tmp (yCoord (cadr ep)))
                     )
                   (schCreateWire
                     scv
                     "route"
                     "direct"
                     (list (car ep)
                           (list (xCoord (car ep)) tmp))
                     0
                     0
                     (cadr (car listLayer))
                     (car (car listLayer))
                     )
                   (schCreateWire
                     scv
                     "route"
                     "direct"
                     (list (list (xCoord (car ep)) tmp)
                           (cadr ep))
                     0
                     0
                     (cadr (cadr listLayer))
                     (car (cadr listLayer))
                     )
                   )
                 else
                 (progn
                   (if (or (equal "via" x~>cellName)
                           (equal "viar" x~>cellName))
                     (setq tmp (min (xCoord (car ep)) (xCoord (cadr ep)))
                           + RINER.SCHEM_GRID_LEN/2.0)
                     (setq tmp (xCoord (cadr ep)))
                     )
                   (schCreateWire
                     scv
                     "route"
                     "direct"
                     (list (car ep)
                           (list tmp (yCoord (car ep))))
                     0
                     0
                     (cadr (car listLayer))
                     (car (car listLayer))
                     )
                   (schCreateWire
                     scv
                     "route"
                     "direct"
                     (list (list tmp (yCoord (car ep)))
                           (cadr ep))
                     0
                     0
                     (cadr (cadr listLayer))
                     (car (cadr listLayer))
                     )
                   )
                 )
               (dbDeleteObject x)
               ))))


(defun reRoute (net)
  (let (ep scv)
    (setq ep (mapcar 'getInstTermCoord net~>instTerms))
    (printf "%L\n" ep)
    (setq scv net~>cellView)
    (foreach figs net~>figs
             (dbDeleteObject figs))
    (schCreateWire
      scv
      "route"
      "flight"
      ep
      0
      0
      0
      "cadetBlue")))


(defun rNet2ptl (flag)
  (let (scv figs selectedNets)
    (setq scv (geGetWindowCellView ))
    (if (geGetWindowCellView )~>lib~>techLibName
      (setq NET2PTL_PTLLIB (geGetWindowCellView )~>lib~>techLibName)
      (setq NET2PTL_PTLLIB "adp634s")
      )
    (when (equal flag "selected")
      (setq figs (setof x (geGetSelSet )
                        (equal x~>objType "path")
                        ))
      (setq selectedNets (setOfList figs~>net))
      )
    (when (equal flag "all")
      (setq selectedNets (setof x scv~>nets
                                (andList
                                  (mapcar (lambda (y) (equal y~>objType "path"))
                                          x~>figs))
                                )))
    (setq selectedNets (setof x selectedNets 
                              ;(or
                              (and
                                (equal (length x~>instTerms) 2)
                                (or 
                                  (and (or (isPTLDrv (car x~>instTerms~>inst))
                                           (isPspl (car x~>instTerms~>inst)))
                                       (isPTLRec (cadr x~>instTerms~>inst)))
                                  (and (or (isPTLDrv (cadr x~>instTerms~>inst))
                                           (isPspl (cadr x~>instTerms~>inst)))
                                       (isPTLRec (car x~>instTerms~>inst)))
                                  ))
                              ;  (and
                              ;    (equal (length x~>instTerms) 1)
                              ;    (isPTLRec (car x~>instTerms~>inst))
                              ;    (isIpin (car (car x~>terms)~>pins)~>fig)
                              ;    ))
                              ))
    (setq selectedNets (setof x selectedNets 
                              (andList
                                (mapcar (lambda (fig)
                                          (or
                                            (equal (xCoord (car fig~>points))
                                                   (xCoord (cadr fig~>points)))
                                            (equal (yCoord (car fig~>points))
                                                   (yCoord (cadr fig~>points))
                                                   )))
                                        x~>figs
                                        ))))
    (printf "number of PTL net is %d.\n" (length selectedNets))
    (foreach n selectedNets
             (if (equal n~>instTermCount 2)
               (SetNetCells scv n t)
               (printf "ERROR:number of instTerm connetcted to selected net is %L"
                       n~>instTermCount) 
               ))))
