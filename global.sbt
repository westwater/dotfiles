// Stops compilation failing on warnings during development
// run with dev= sbt
scalacOptions := {
    if(sys.env.contains("dev")){
        scalacOptions.value.filterNot(_ == "-Xfatal-warnings")
    } else scalacOptions.value
}
