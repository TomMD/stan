{- |
Copyright: (c) 2020 Thomas DuBuisson
SPDX-License-Identifier: MPL-2.0
Maintainer: Tom <thomas.dubuisson@gmail.com>

Export via JSON
-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Stan.JSON
    ( saveOutput
    ) where

import Data.Aeson
import qualified Data.List.NonEmpty as NE
import qualified Data.Map.Strict as Map
import qualified Data.Text as Text
import qualified Slist as S
import Stan.Analysis (Analysis(..))
import Stan.Category (Category(..))
import Stan.Core.Id (Id(..))
import Stan.Core.ModuleName (ModuleName(..))
import Stan.Observation (Observation(..))
import Stan.FileInfo (FileInfo(..))
import Stan.Inspection (Inspection(..))
import Stan.Inspection.All (getInspectionById)
import SrcLoc

saveOutput
    :: Analysis
    -> FilePath
    -> IO ()
saveOutput an outPath =
    case outPath of
        "-" -> putTextLn (decodeUtf8 jsonBytes)
        _   -> writeFileLBS outPath jsonBytes
  where
    jsonBytes = encode an

instance ToJSON Analysis where
    toJSON = toJSON . Map.elems . analysisFileMap

instance ToJSON FileInfo where
    toJSON FileInfo{..} = object
        [ "file" .= toText fileInfoPath
        , "module" .= unModuleName fileInfoModuleName
        , "observations" .= toList (S.sortOn observationLoc fileInfoObservations)
        ]

instance ToJSON Observation where
    toJSON Observation{..} = object
        [ "id" .= unId observationId
        , "severity" .= sev
        , "inspectionId" .= unId observationInspectionId
        , "name" .= inspectionName inspection
        , "description" .= inspectionDescription inspection
        , "category" .= categories
        , "file" .= toText observationFile
        , "startLine" .= srcLocLine (realSrcSpanStart observationLoc)
        , "endLine" .= srcLocLine (realSrcSpanEnd observationLoc)
        ]
      where
        sev :: Text
        sev = show (inspectionSeverity inspection)

        inspection :: Inspection
        inspection = getInspectionById observationInspectionId

        categories :: Text
        categories = Text.intercalate " "
            $ map unCategory $ NE.toList $ inspectionCategory inspection
