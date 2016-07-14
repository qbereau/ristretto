require('Objective-J/Jake');

var sourcePaths = new jake.FileList(),
    BUILD_DIR = '../Build';

sourcePaths.include('**/*.j');

tasks.makeFramework('Ristretto', nil,
    {
        preprocess: true,
        sourcePaths: sourcePaths,
        buildDirectory: BUILD_DIR
    });

task('default', ['Ristretto']);
