#!/usr/bin/env stack
-- stack --resolver lts-11.1 runghc --package minio-hs

--
-- MinIO Haskell SDK, (C) 2017, 2018 MinIO, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

{-# LANGUAGE OverloadedStrings #-}

import           Network.Minio
import           Prelude

main :: IO ()
main = do
  let
    bucket = "mybucket"
    object = "myobject"

  res <- runMinio minioPlayCI $
           removeObject bucket object

  case res of
    Left _ -> putStrLn $ "Failed to remove " ++ show bucket ++ "/" ++ show object
    Right _ -> putStrLn "Removed object successfully"
