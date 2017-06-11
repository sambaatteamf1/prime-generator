LIB="lib"
TEST="test"

module.exports = (grunt)->

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        coffee: {
            app: {
                files: grunt.file.expandMapping(['coffee/*.coffee'], '',{
                        rename: (destBase, destPath)->
                            return destBase + destPath.replace("coffee","#{LIB}/js").replace(/\.coffee$/,".js")
                    })
            }

            test: {
                files: grunt.file.expandMapping(['coffee/test/*.coffee'], '',{
                        rename: (destBase, destPath)->
                            return destBase + destPath.replace("coffee",".").replace(/\.coffee$/,".js")
                    })
            }            

        }

        watch: {
            files: ['coffee/**/*.coffee'],
            tasks: ['coffee']
        }

    })

    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-exec');

    grunt.registerTask('default', [
        'coffee'
    ])
