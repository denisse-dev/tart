module UI
  ( drawUI
  )
where

import Brick

import Types
import UI.Main
import UI.CharacterSelect
import UI.PaletteEntrySelect
import UI.ToolSelect
import UI.CanvasSizePrompt
import UI.AskToSave
import UI.TextEntry
import UI.BoxStyleSelect
import UI.StyleSelect

drawUI :: AppState -> [Widget Name]
drawUI s =
    case currentMode s of
        Main                 -> drawMainUI s
        FgPaletteEntrySelect -> drawPaletteEntrySelectUI s
        BgPaletteEntrySelect -> drawPaletteEntrySelectUI s
        ToolSelect           -> drawToolSelectUI s
        CharacterSelect      -> drawCharacterSelectUI s
        CanvasSizePrompt     -> drawCanvasSizePromptUI s
        AskToSave            -> drawAskToSaveUI s
        TextEntry            -> drawTextEntryUI s
        BoxStyleSelect       -> drawBoxStyleSelectUI s
        StyleSelect          -> drawStyleSelectUI s
