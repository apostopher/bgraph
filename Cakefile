fs     = require 'fs'
{exec} = require 'child_process'

appFiles  = [
  # omit src/ and .coffee to make the below lines a little shorter
  { name: 'utils', options: "--bare" }
  { name: 'popup', options: "" }
  { name: 'bgraph', options: "" }
  { name: 'script', options: "" }
]
libFiles  = [
  'lib/underscore-min.js'
  'lib/raphael-min.js'
]
task 'compile', 'Compile individual files debug-friendly', ->
  for file, index in appFiles then do (file, index) ->
    exec "coffee --output lib #{file.options} --compile src/#{file.name}.coffee", (err, stdout, stderr) ->
      throw err if err
      console.log stdout + stderr

task 'build', 'Build single application file from source files', ->
  invoke 'compile'
  appContents = new Array remaining = appFiles.length
  for file, index in appFiles then do (file, index) ->
    appContents[index] = fs.readFileSync "lib/#{file.name}.js", 'utf8'
  
  fs.writeFileSync 'lib/app.js', appContents.join('\n\n'), 'utf8'
  
task 'buildlib', 'Builds a single lib file from all lib files', ->
  libContents = new Array remaining = libFiles.length
  for file, index in libFiles then do (file, index) ->
    libContents[index] = fs.readFileSync file, 'utf8'
   
  fs.writeFileSync 'lib/lib.js', libContents.join('\n'), 'utf8'

task 'buildall', 'Builds single application file from all js files including libraries', ->
  invoke 'buildlib'
  invoke 'build'
  allContent = new Array
  allContent.push fs.readFileSync 'lib/lib.js', 'utf8'
  allContent.push fs.readFileSync 'lib/app.js', 'utf8'
  
  fs.writeFileSync 'lib/app.js', allContent.join('\n\n'), 'utf8'

task 'minify', 'Minify the resulting application file after build', ->
  exec 'java -jar "tools/compiler.jar" --js lib/app.js --js_output_file lib/app.min.js', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

task 'minifyXtreme', 'Minify maximum possible using ADVANCED_OPTIMIZATIONS', ->
  exec 'java -jar "tools/compiler.jar" --js lib/app-all.js --compilation_level ADVANCED_OPTIMIZATIONS --js_output_file lib/app-all.min.js', (err, stdout, stderr) ->
    throw err if err

task 'publish', 'Build and minify project files. Ready for production', ->
  invoke 'build'
  invoke 'minify'

task 'px', 'Publish Xtreme', ->
  invoke 'buildall'
  invoke 'minifyXtreme'