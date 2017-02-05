{-# LANGUAGE TypeApplications, OverloadedStrings #-}
module Main where

import Control.Distributed.Process
import Control.Distributed.Process.Node
import Network.Transport
import Network.Transport.TCP (createTransport, defaultTCPParameters, TCPParameters(..))
import qualified Control.Distributed.Process.ManagedProcess.Client as DClient
import Control.Concurrent (threadDelay)

main :: IO ()
main = do
  Right transport <- createTransport "127.0.0.1" "8002" defaultTCPParameters
  node <- newLocalNode transport initRemoteTable
  print (localNodeId node)

  runProcess node $ do
    let nid = NodeId (EndPointAddress "127.0.0.1:8001:0")
    say "Before"
    response <- DClient.call @_ @Int @Int (nid, "handlerProcess" :: String) 10
    say "After"
    say (show response)
  threadDelay $ 1000 * 1000
