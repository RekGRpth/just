function require (path) {
  const { vm } = just
  const params = ['exports', 'require', 'module']
  const exports = {}
  const module = { exports, type: 'native' }
  module.text = vm.builtin(path)
  if (!module.text) return
  const fun = vm.compile(module.text, path, params, [])
  module.function = fun
  fun.call(exports, exports, p => require(p, module), module)
  return module.exports
}
function runMain () {
  const { vm } = just
  const params = []
  const source = vm.builtin('just')
  if (!source) return
  const fun = vm.compile(source, 'just.js', params, [])
  fun.call(exports)
}
let waitForInspector = false
just.args = just.args.filter(arg => {
  const found = (arg === '--inspector')
  if (found) waitForInspector = true
  return !found
})
if (waitForInspector) {
  const inspectorModule = require('inspector')
  if (!inspectorModule) throw new Error('inspector not enabled')
  just.error('waiting for inspector...')
  global.inspector = inspectorModule.createInspector({
    title: 'Just!',
    onReady: () => runMain()
  })
} else {
  runMain()
}