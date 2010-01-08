{-# LANGUAGE RecordWildCards #-}

module Type where

import HSE.All
import Data.Char
import Data.List
import Data.Maybe
import Data.Ord
import Language.Haskell.HsColour.TTY
import Language.Haskell.HsColour.Colourise


---------------------------------------------------------------------
-- GENERAL DATA TYPES

data Rank = Ignore | Warning | Error
            deriving (Eq,Ord,Show)

-- (modulename,functionname)
-- either being blank implies universal matching
type FuncName = (String,String)


---------------------------------------------------------------------
-- IDEAS/SETTINGS

-- Classify and MatchExp are read from the Settings file
-- Idea are generated by the program
data Setting
    = Classify {rankS :: Rank, hintS :: String, funcS :: FuncName}
    | MatchExp {rankS :: Rank, hintS :: String, lhs :: Exp, rhs :: Exp, side :: Maybe Exp}
    | Builtin String -- use a builtin hint set
      deriving Show

data Idea
    = Idea {func :: FuncName, rank :: Rank, hint :: String, loc :: SrcLoc, from :: String, to :: String}
    | ParseError {rank :: Rank, hint :: String, loc :: SrcLoc, msg :: String, from :: String}
      deriving Eq


isClassify Classify{} = True; isClassify _ = False
isMatchExp MatchExp{} = True; isMatchExp _ = False
isParseError ParseError{} = True; isParseError _ = False


instance Show Idea where
    show = showEx id


showANSI :: IO (Idea -> String)
showANSI = do
    prefs <- readColourPrefs
    return $ showEx (hscolour prefs)

showEx :: (String -> String) -> Idea -> String
showEx tt Idea{..} = unlines $
    [showSrcLoc loc ++ " " ++ show rank ++ ": " ++ hint] ++ f "Found" from ++ f "Why not" to
    where f msg x = (msg ++ ":") : map ("  "++) (lines $ tt x)

showEx tt ParseError{..} = unlines $
    [showSrcLoc loc ++ " Parse error","Error message:","  " ++ msg,"Code:"] ++ map ("  "++) (lines $ tt from)


-- The real key will be filled in by applyHint
rawIdea = Idea ("","")
idea rank hint loc from to = rawIdea rank hint loc (f from) (f to)
    where f = dropWhile isSpace . prettyPrint
warn mr = idea Warning mr


-- Any 1-letter variable names are assumed to be unification variables
isUnifyVar :: String -> Bool
isUnifyVar [x] = x == '?' || isAlpha x
isUnifyVar _ = False
