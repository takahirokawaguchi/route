(defun rhPostInstallTrigger (arg)
  (let (menuList)
    (unless (boundp 'guiTranslateCellItem)
      (setq guiTranslateCellItem
            (hiCreateMenuItem
              ?name 'guiTranslateCellItem
              ?itemText "cell(s) translater"
              ?callback "(guiTranslateCell )")))
    (unless (boundp 'mloadMySkillItem)
      (setq mloadMySkillItem
            (hiCreateMenuItem
              ?name 'mloadMySkillItem
              ?itemText "mloadMySkill"
              ?callback "(mload \"~/git/route/source\") (mload \"~/git/dat/source\") (mload \"~/git/placement/source\") (mload \"~/git/skill\")")))
    (unless (boundp 'setqScvGeGetWindowCellViewItem)
      (setq setqScvGeGetWindowCellViewItem
            (hiCreateMenuItem
              ?name 'setqScvGeGetWindowCellViewItem
              ?itemText "setqScvGeGetWindowCellView"
              ?callback "(setq scv (geGetWindowCellView ))")))
    (unless (boundp 'fillMoatADPItem)
      (setq fillMoatADPItem
            (hiCreateMenuItem
              ?name 'fillMoatADPItem
              ?itemText "fillMoatADP"
              ?callback "(fillMoatADP (geGetWindowCellView ) nil)")))
    ;(unless (boundp 'placeOnGridStretchItem)
    ; (setq placeOnGridStretchItem
    ;       (hiCreateMenuItem
    ;         ?name 'placeOnGridStretchItem
    ;         ?itemText "placeOnGridStretch"
    ;         ?callback "(roAdjustAllInsts (geGetWindowCellView ) \"stretch\")")))
    (unless (boundp 'placeOnGridMoveItem)
      (setq placeOnGridMoveItem
            (hiCreateMenuItem
              ?name 'placeOnGridMoveItem
              ?itemText "placeOnGrid"
              ?callback "(roAdjustAllInsts (geGetWindowCellView ))")))
    (unless (boundp 'rRouteAllItem)
      (setq rRouteAllItem
            (hiCreateMenuItem
              ?name 'rRouteAllItem
              ?itemText "routeAll"
              ?callback "(rRoute (geGetWindowCellView ) \"all\")")))
    (unless (boundp 'rRouteSlectedItem)
      (setq rRouteSlectedItem
            (hiCreateMenuItem
              ?name 'rRouteSlectedItem
              ?itemText "routeSelected"
              ?callback "(rRoute (geGetWindowCellView ) \"selected\")")))
    (unless (boundp 'makePtlWireItem)
      (setq makePtlWireItem
            (hiCreateMenuItem
              ?name 'makePtlWireItem
              ?itemText "selected nets -> ptl nets"
              ?callback "(makePtlWire )")))
    (unless (boundp 'undoPTLWireItem)
      (setq undoPTLWireItem
            (hiCreateMenuItem
              ?name 'undoPTLWireItem
              ?itemText "all ptl nets -> nets"
              ?callback "(undoPTLWire (geGetWindowCellView ))")))
    (unless (boundp 'undoPTLCellAllItem)
      (setq undoPTLCellAllItem
            (hiCreateMenuItem
              ?name 'undoPTLCellAllItem
              ?itemText "all ptl cells -> ptl nets"
              ?callback "(undoPTLCellAll ) ")))
    (unless (boundp 'undoPTLCellSelectedItem)
      (setq undoPTLCellSelectedItem
            (hiCreateMenuItem
              ?name 'undoPTLCellSelectedItem
              ?itemText "selected ptl cells -> ptl nets"
              ?callback "(undoPTLCellSelected ) ")))
    (unless (boundp 'rNet2ptlAllItem)
      (setq rNet2ptlAllItem
            (hiCreateMenuItem
              ?name 'rNet2ptlAllItem
              ?itemText "all ptl nets -> ptl cells"
              ?callback "(rNet2ptl \"all\") ")))
    (unless (boundp 'net2ptlSelectedItem)
      (setq net2ptlSelectedItem
            (hiCreateMenuItem
              ?name 'net2ptlSelectedItem
              ?itemText "selected ptl nets -> ptl cells"
              ?callback "(rNet2ptl \"selected\" )")))
    (unless (boundp 'datGuiItem)
      (setq datGuiItem
            (hiCreateMenuItem
              ?name 'datGuiItem
              ?itemText "displayArrivalTime"
              ?callback "(datGui )")))
    ;(unless (boundp 'getOverlapBiasLeadsItem)
    ;  (setq getOverlapBiasLeadsItem
    ;        (hiCreateMenuItem
    ;          ?name 'getOverlapBiasLeadsItem
    ;          ?itemText "getOverlapBiasLeads"
    ;          ?callback "(getOverlapBiasLeads )")))
    (unless (boundp 'scvCellNamesItem)
      (setq scvCellNamesItem
            (hiCreateMenuItem
              ?name 'scvCellNamesItem
              ?itemText "scvCellNames"
              ?callback "(scvCellNames (geGetWindowCellView ))")))
    (unless (boundp 'c2vFrontItem)
      (setq c2vFrontItem
            (hiCreateMenuItem
              ?name 'c2vFrontItem
              ?itemText "logicExtraction"
              ?callback "(c2vFront )")))
;    (unless (boundp 'loadCdsinitItem)
;      (setq loadCdsinitItem
;            (hiCreateMenuItem
;              ?name 'loadCdsinitItem
;              ?itemText "loadDotCdsinit"
;              ?callback "(load \"./.cdsinit\")")))
    (unless (boundp 'storeSelectedCell2varDebugItem)
      (setq storeSelectedCell2varDebugItem
            (hiCreateMenuItem
              ?name 'storeSelectedCell2varDebugItem
              ?itemText "storeSelectedCell2varDebug"
              ?callback "(setq varDebug (geGetSelSet ))")))
    (unless (boundp 'deleteNormalLabelItem)
      (setq deleteNormalLabelItem
            (hiCreateMenuItem
              ?name 'deleteNormalLabelItem
              ?itemText "deleteNormalLabel"
              ?callback "(deleteNormalLabel )")))

    ;pulldown menu
    (hiCreatePulldownMenu
      'subRouterSliderMenu
      "Router pulldown menu"
      (list
        ;placeOnGridStretchItem
        placeOnGridMoveItem
        rRouteAllItem
        rRouteSlectedItem
        makePtlWireItem
        undoPTLWireItem
        undoPTLCellAllItem
        undoPTLCellSelectedItem
        rNet2ptlAllItem     
        net2ptlSelectedItem
        )
      "")
    (hiCreatePulldownMenu
      'subDebugSliderMenu
      "Debug pulldown menu"
      (list
        mloadMySkillItem
        setqScvGeGetWindowCellViewItem
        scvCellNamesItem
        ;loadCdsinitItem
        storeSelectedCell2varDebugItem
        deleteNormalLabelItem
        )
      "")
    ;slider menu
    (setq routerSliderMenu
          (hiCreateSliderMenuItem
            ?name       'routerSliderMenu
            ?itemText   "router"
            ?subMenu	subRouterSliderMenu
            ))
    (setq debugSliderMenu
          (hiCreateSliderMenuItem
            ?name       'debugSliderMenu
            ?itemText   "debug"
            ?subMenu	subDebugSliderMenu
            ))
    ;main menu
    (setq sfqRouteMenu
          (hiCreatePulldownMenu
            'sfqRouteMenu
            "SFQ-Route"
            (list
              fillMoatADPItem
              routerSliderMenu
              datGuiItem
              ;getOverlapBiasLeadsItem
              c2vFrontItem
              guiTranslateCellItem
              debugSliderMenu
              )))
    hiInsertBannerMenu(hiGetCurrentWindow() sfqRouteMenu 11)
    ))
(deRegUserTriggers "schematic" nil nil 'rhPostInstallTrigger)
