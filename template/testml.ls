require! '../lib/TestML'
require! './TestMLBridge'

testml = new TestML {
  testml: 'testml/%NAME%.tml'
  bridge: TestMLBridge
}

testml.run()
