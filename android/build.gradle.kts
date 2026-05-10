allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect build outputs to [flutter_project]/build/ so the Flutter tool can locate APKs.
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    project.evaluationDependsOn(":app")
    layout.buildDirectory.value(newBuildDir.dir(project.name))
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}