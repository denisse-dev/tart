module Util
  ( checkForMouseSupport
  , setTool
  , setFgPaletteIndex
  , setBgPaletteIndex
  , beginFgPaletteSelect
  , beginBgPaletteSelect
  , beginToolSelect
  , setMode
  , increaseCanvasSize
  , decreaseCanvasSize

  , tools

  , beginCharacterSelect
  , cancelCharacterSelect
  , selectCharacter
  )
where

import Control.Monad (when, forM_)
import Control.Monad.Trans (liftIO)
import qualified Graphics.Vty as V
import qualified Data.Array.MArray as A
import System.Exit (exitFailure)
import Lens.Micro.Platform
import qualified Data.Array.Unsafe as A

import Brick

import Types

tools :: [(Tool, Int)]
tools =
    [ (FreeHand, 1)
    , (Eraser, 0)
    ]

increaseCanvasSize :: AppState -> EventM Name AppState
increaseCanvasSize s =
    resizeCanvas s (s^.canvasSize & _1 %~ (+ 4) & _2 %~ (+ 2))

decreaseCanvasSize :: AppState -> EventM Name AppState
decreaseCanvasSize s =
    resizeCanvas s (s^.canvasSize & _1 %~ (max 1 . (subtract 4))
                                  & _2 %~ (max 1 . (subtract 2)))

setMode :: Mode -> AppState -> AppState
setMode m s = s & mode .~ m

beginToolSelect :: AppState -> AppState
beginToolSelect s =
    if s^.showHud
    then setMode ToolSelect s
    else s

beginFgPaletteSelect :: AppState -> AppState
beginFgPaletteSelect s =
    if s^.showHud
    then setMode FgPaletteEntrySelect s
    else s

beginBgPaletteSelect :: AppState -> AppState
beginBgPaletteSelect s =
    if s^.showHud
    then setMode BgPaletteEntrySelect s
    else s

setTool :: AppState -> Tool -> AppState
setTool s t = s & tool .~ t

setFgPaletteIndex :: AppState -> Int -> AppState
setFgPaletteIndex s i = setMode Main $ s & drawFgPaletteIndex .~ i

setBgPaletteIndex :: AppState -> Int -> AppState
setBgPaletteIndex s i = setMode Main $ s & drawBgPaletteIndex .~ i

beginCharacterSelect :: AppState -> AppState
beginCharacterSelect = setMode CharacterSelect

cancelCharacterSelect :: AppState -> AppState
cancelCharacterSelect = setMode Main

selectCharacter :: Char -> AppState -> AppState
selectCharacter c s = setMode Main $ s & drawCharacter .~ c

checkForMouseSupport :: IO ()
checkForMouseSupport = do
    vty <- V.mkVty =<< V.standardIOConfig

    when (not $ V.supportsMode (V.outputIface vty) V.Mouse) $ do
        putStrLn "Error: this terminal does not support mouse interaction"
        exitFailure

    V.shutdown vty

resizeCanvas :: AppState -> (Int, Int) -> EventM n AppState
resizeCanvas s newSz = do
    -- If the new bounds are different than the old, create a new array
    -- and copy.
    case newSz /= s^.canvasSize of
        False -> return s
        True -> liftIO $ do
            -- Create a new draw array with the right bounds
            let newBounds = ((0, 0), (newSz & each %~ pred))
            newDraw <- A.newArray newBounds blankPixel

            -- Use the difference in size to determine the range of data
            -- to copy to the new canvas
            let (maxW, maxH) = ( min (newSz^._1) (s^.canvasSize._1)
                               , min (newSz^._2) (s^.canvasSize._2)
                               )

            forM_ [0..maxW-1] $ \w ->
                forM_ [0..maxH-1] $ \h ->
                    A.writeArray newDraw (w, h) =<<
                        A.readArray (s^.drawing) (w, h)

            newDrawFrozen <- A.unsafeFreeze newDraw

            return $ s & drawing .~ newDraw
                       & drawingFrozen .~ newDrawFrozen
                       & canvasSize .~ newSz
