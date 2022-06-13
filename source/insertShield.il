/*
(load "~/git/route/source/insertShield.il")
*/
(defun insertShield ()
  (let (scv wirePTL1 wirePTL2 vias)
    (setq scv (geGetWindowCellView ))
    (setq vias (car scv~>viaHeaders)~>vias)
    (foreach
      via vias
      (setq wirePTL1 (car (setof x (wiresConnectedVia via)
                                 (equal x~>layerName "PTL1"))))
      (setq wirePTL2 (car (setof x (wiresConnectedVia via)
                                 (equal x~>layerName "PTL2"))))
      (when wirePTL1
        (dbCreateInst
          scv 
          (dbOpenCellViewByType
            "test_adp634s_local"
            "shieldPTL1"
            "layout")
          nil
          via~>origin 
          (calculateOrientShield via wirePTL1)
          ))
      (when wirePTL2
        (dbCreateInst
          scv 
          (dbOpenCellViewByType
            "test_adp634s_local" 
            "shieldPTL2"
            "layout")
          nil
          via~>origin 
          (calculateOrientShield via wirePTL2)
          ))
      )
    ))

(defun wiresConnectedVia (via)
  (let (wires)
    (setq wires (setof x via~>net~>figs
                       (or (equal via~>origin x~>endPt)
                           (equal via~>origin x~>beginPt))))
    ))

(defun calculateOrientShield (via wire)
  (let (originAnother)
    (when (member wire (wiresConnectedVia via))
      (setq originAnother (car (setof x 
                                      (list wire~>beginPt wire~>endPt)
                                      (nequal x via~>origin))))
      (cond ((equal (xCoord via~>origin)
                    (xCoord originAnother))
             (if (lessp (yCoord via~>origin)
                        (yCoord originAnother))
               "R90"
               "R270"
               ))
            ((equal (yCoord via~>origin)
                    (yCoord originAnother))
             (if (lessp (xCoord via~>origin)
                        (xCoord originAnother))
               "R0"
               "R180"
               )
             )
            (t nil))
      )))
