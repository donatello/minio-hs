module Network.Minio.API
  (
    connect
  , defaultConnectInfo
  , RequestInfo(..)
  , runMinio
  , executeRequest
  , mkStreamRequest
  , requestInfo
  ) where

import qualified Network.HTTP.Types as HT
import           Network.HTTP.Conduit (Response)
import qualified Network.HTTP.Conduit as NC
import           Network.HTTP.Types (Method, Header, Query)

import           Lib.Prelude

import qualified Data.Conduit as C

import           Network.Minio.Data
import           Network.Minio.Data.Crypto
import           Network.Minio.Sign.V4

-- runRequestDebug r mgr = do
--   print $ "runRequestDebug"
--   print $ NC.method r
--   print $ NC.secure r
--   print $ NC.host r
--   print $ NC.port r
--   print $ NC.path r
--   print $ NC.queryString r
--   print $ NC.requestHeaders r
--   -- print $ NC.requestBody r
--   NC.httpLbs r mgr

executeRequest :: RequestInfo -> Minio (Response LByteString)
executeRequest ri = do
  let PayloadSingle pload = riPayload ri
      phash = hashSHA256 pload
      newRI = ri {
          riPayloadHash = phash
        , riHeaders = ("x-amz-content-sha256", phash) : (riHeaders ri)
        }

  ci <- asks mcConnInfo

  reqHeaders <- liftIO $ signV4 ci newRI

  mgr <- asks mcConnManager

  let req = NC.defaultRequest {
          NC.method = riMethod newRI
        , NC.secure = connectIsSecure ci
        , NC.host = encodeUtf8 $ connectHost ci
        , NC.port = connectPort ci
        , NC.path = getPathFromRI ri
        , NC.queryString = HT.renderQuery False $ riQueryParams ri
        , NC.requestHeaders = reqHeaders
        , NC.requestBody = NC.RequestBodyBS pload
        }

  NC.httpLbs req mgr

mkStreamRequest :: RequestInfo
                -> Minio (Response (C.ResumableSource Minio ByteString))
mkStreamRequest ri = do
  let PayloadSingle pload = riPayload ri
      phash = hashSHA256 pload
      newRI = ri {
          riPayloadHash = phash
        , riHeaders = ("x-amz-content-sha256", phash) : (riHeaders ri)
        }

  ci <- asks mcConnInfo

  reqHeaders <- liftIO $ signV4 ci newRI

  mgr <- asks mcConnManager

  let req = NC.defaultRequest {
          NC.method = riMethod newRI
        , NC.secure = connectIsSecure ci
        , NC.host = encodeUtf8 $ connectHost ci
        , NC.port = connectPort ci
        , NC.path = getPathFromRI ri
        , NC.queryString = HT.renderQuery False $ riQueryParams ri
        , NC.requestHeaders = reqHeaders
        , NC.requestBody = NC.RequestBodyBS pload
        }

  NC.http req mgr

requestInfo :: Method -> Maybe Bucket -> Maybe Object
            -> Query -> [Header] -> Payload
            -> RequestInfo
requestInfo m b o q h p = RequestInfo m b o q h p "" Nothing