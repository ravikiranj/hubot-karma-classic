module.exports = function (grunt) {
  'use strict';

  grunt.initConfig({
    mochaTest: {
      test: {
        options: {
          reporter: 'spec',
          require: 'coffee-script'
        },
        src: ['test/**/*.coffee']
      }
    },
    release: {
      options: {
        tagName: 'v<%= version %>',
        commitMessage: 'Prepared to release <%= version %>.'
      }
    },
    coffeelint: {
      options: {
        configFile: 'coffeelint.json'
      },
      app: ['src/**/*.coffee', 'test/**/*.coffee']  
    },
    watch: {
      files: ['Gruntfile.js', 'src/**/*.coffee', 'test/**/*.coffee'],
      tasks: ['test']
    }
  });

  // load all grunt tasks
  require('matchdep').filterDev(['grunt-*', '!grunt-cli']).forEach(grunt.loadNpmTasks);

  grunt.registerTask('test', ['mochaTest']);
  grunt.registerTask('lint', ['coffeelint']);
  grunt.registerTask('test:watch', ['watch']);
  grunt.registerTask('default', ['test', 'lint']);
};
