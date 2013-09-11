module.exports = (grunt) ->

	# Project configuration.
	grunt.initConfig
		pkg: grunt.file.readJSON('package.json')
		regarde:
			serverjs:
				files: ["_src/**/*.coffee"]
				tasks: [ "coffee:serverchanged", "includereplace" ]
			frontendjs:
				files: ["_src_static/js/**/*.coffee"]
				tasks: [ "coffee:frontendchanged", "includereplace" ]
			jade:
				files: ["_src_static/templates/*.jade"]
				tasks: [ "jade:frontend" ]
			css:
				files: ["_src_static/css/*.styl"]
				tasks: [ "stylus" ]
			static:
				files: ["_src_static/static/**/*.*"]
				tasks: [ "copy:static" ]
			#cson:
			#	files: ["_src/i18n/**/*.cson"]
			#	tasks: [ "cson:locals" ]
		coffee:
			serverchanged:
				expand: true
				cwd: '_src'
				src:	[ '<% print( _.first( ((typeof grunt !== "undefined" && grunt !== null ? (_ref = grunt.regarde) != null ? _ref.changed : void 0 : void 0) || ["_src/nothing"]) ).slice( "_src/".length ) ) %>' ]
				# template to cut off `_src/` and throw on error on non-regrade call
				# CF: `_.first( grunt?.regarde?.changed or [ "_src/nothing" ] ).slice( "_src/".length )
				dest: ''
				ext: '.js'

			frontendchanged:
				expand: true
				cwd: '_src_static/js'
				src:	[ '<% print( _.first( ((typeof grunt !== "undefined" && grunt !== null ? (_ref = grunt.regarde) != null ? _ref.changed : void 0 : void 0) || ["_src_static/js/nothing"]) ).slice( "_src_static/js/".length ) ) %>' ]
				# template to cut off `_src_static/js/` and throw on error on non-regrade call
				# CF: `_.first( grunt?.regarde?.changed or [ "_src_static/js/nothing" ] ).slice( "_src_static/js/".length )
				dest: 'static/js'
				ext: '.js'

			backend_base:
				expand: true
				cwd: '_src',
				src: ["**/*.coffee"]
				dest: ''
				ext: '.js'

			frontend_base:
				expand: true
				cwd: '_src_static/js',
				src: ["**/*.coffee"]
				dest: 'static/js'
				ext: '.js'
		# cson:
		# 	locales:
		# 		expand: true
		# 		cwd: '_src'
		# 		src: ['i18n/**/*.cson' ]
		# 		dest: 'static'
		# 		ext: '.json'

		stylus:
			options:
				"include css": true
			styles:
				files:
					"static/css/styles.css": ["_src_static/css/_main.styl"]
			login:
				files:
					"static/css/login.css": ["_src_static/css/_login.styl"]

		mochacli:
			options:
				require: [ "should" ]
				reporter: "spec"
				bail: false
				timeout: 3000
				slow: 1

			main: [ "test/general.js" ]
			#old: [ "test/old.js" ]
			#all: [ "test/general.js" , "test/old.js" ]

		includereplace:
			pckg:
				options:
					globals:
						version: "<%= pkg.version %>"

					prefix: "@@"
					suffix: ''

				files:
					"": ["index.js"]

		copy:
			static:
				expand: true
				cwd: '_src_static/static',
				src: [ "**" ]
				dest: "static/"


		jade: 
			frontend:
				options:
					debug: false
					client: true
					namespace: "Tmpls"
					compileDebug: false
					pretty: true
					amd: true
					processName: ( filename )->
						_l = "_src_static/templates/".length
						return filename[ _l.. ].replace( ".jade", "" )

				files: 
					"static/js/tmpl.js": "_src_static/templates/*.jade"

	# Load npm modules
	grunt.loadNpmTasks "grunt-regarde"
	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-copy"
	grunt.loadNpmTasks "grunt-contrib-jade"
	grunt.loadNpmTasks "grunt-contrib-stylus"
	grunt.loadNpmTasks "grunt-mocha-cli"
	#grunt.loadNpmTasks "grunt-cson"
	grunt.loadNpmTasks "grunt-include-replace"


	# just a hack until this issue has been fixed: https://github.com/yeoman/grunt-regarde/issues/3
	grunt.option('force', not grunt.option('force'))
	
	# ALIAS TASKS
	grunt.registerTask "watch", "regarde"
	grunt.registerTask "default", "build"
	grunt.registerTask "test", [ "mochacli:main" ]

	# build the project
	grunt.registerTask "build",[ "coffee", "includereplace", "copy", "jade", "stylus" ]
