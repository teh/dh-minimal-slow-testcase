{-# LANGUAGE TypeApplications, OverloadedStrings, ScopedTypeVariables #-}
module Main where

import Control.Distributed.Process
import Control.Distributed.Process.Node as Node
import Control.Distributed.Process.ManagedProcess
import Control.Distributed.Process.Extras.Internal.Types (ExitReason(..))
import Control.Distributed.Process.Extras.Time (Delay(Infinity))
import Control.Distributed.Process.Extras as E

import Network.Transport.TCP (createTransport, defaultTCPParameters, TCPParameters(..))

-- | Create a WAI application for Holborn
appDefinition :: ProcessDefinition ()
appDefinition = statelessProcess
  { apiHandlers =
      [ handleCall_ (\(n :: Int) -> say "HI" >> return (n * 2))
      ]
  , unhandledMessagePolicy = Log
  , timeoutHandler = \_ _ -> stop $ ExitOther "timeout"
  }

app :: Process ()
app = serve () init' appDefinition
  where
    init' _ = do
      self <- getSelfPid
      register "handlerProcess" self
      pure (InitOk () Infinity)

myRemoteTable = E.__remoteTable initRemoteTable

main :: IO ()
main = do
  Right transport <- createTransport "127.0.0.1" "8001" defaultTCPParameters
  node <- newLocalNode transport myRemoteTable
  print (localNodeId node)

  Node.runProcess node app
