{-# LANGUAGE TypeApplications, OverloadedStrings, ScopedTypeVariables, DeriveGeneric #-}
module Main where

import Control.Distributed.Process
import Control.Distributed.Process.Node as Node
import Control.Distributed.Process.ManagedProcess
import Control.Distributed.Process.ManagedProcess.Client as Client
import Control.Distributed.Process.Extras.Internal.Types (ExitReason(..))
import Control.Distributed.Process.Extras.Time (Delay(Infinity))
import Control.Distributed.Process.Extras as E
import Network.Transport.TCP (createTransport, defaultTCPParameters, TCPParameters(..))
import Network.Transport (EndPointAddress(..))
import Network.Wai.Handler.Warp (run)
import Control.Concurrent.STM.TMVar
import Control.Concurrent.STM
import Network.HTTP.Types (RequestHeaders, Query)
import Data.Binary (Binary)
import GHC.Generics (Generic)
import Network.HTTP.Types (status200)
import Network.Wai (Request, requestHeaders, responseLBS, remoteHost, Application, responseFile, pathInfo, isSecure, queryString)
import Data.ByteString.Lazy as BSL
import Control.Monad (forever)
import Control.Concurrent (threadDelay)

-- Fake request
data HttpRequest = HttpRequest BSL.ByteString deriving (Generic, Show)
-- Fake response
data HttpResponse = HttpResponse BSL.ByteString deriving (Generic, Show)
instance Binary HttpResponse
instance Binary HttpRequest

type ProcessChannel = TMVar (TMVar HttpResponse, HttpRequest)

response502 :: HttpResponse
response502 = HttpResponse "backend error"

initialProcessChannel :: IO ProcessChannel
initialProcessChannel = newEmptyTMVarIO

rpcProcess :: ProcessChannel -> Process ()
rpcProcess processChannel = forever $ do
  (replyVar, httpRequest) <- liftIO $ atomically $ takeTMVar processChannel

  -- NB I don't have a server on the other side yet
  let nid = NodeId (EndPointAddress "127.0.0.1:8081:0")
  response <- Client.tryCall (nid, "http" :: String) httpRequest
  case response of
    Nothing -> liftIO $ atomically $ putTMVar replyVar response502
    Just r -> liftIO $ atomically $ putTMVar replyVar r

httpApp :: ProcessChannel -> Application
httpApp processChannel req respond = do
  responseVar <- newEmptyTMVarIO
  let httpRequest = HttpRequest "fake"
  atomically $ putTMVar processChannel (responseVar, httpRequest)
  HttpResponse body <- atomically $ takeTMVar responseVar
  respond $ responseLBS status200 [] body


main :: IO ()
main = do
  Right transport <- createTransport "127.0.0.1" "8001" (defaultTCPParameters { tcpNoDelay = True })
  node <- newLocalNode transport initRemoteTable
  print (localNodeId node)

  processChannel <- initialProcessChannel
  _ <- forkProcess node (rpcProcess processChannel)
  run 8000 (httpApp processChannel)
