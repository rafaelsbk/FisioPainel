allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = file("C:/Users/rafae/FisioPainel_build")
rootProject.layout.buildDirectory.value(rootProject.layout.dir(provider { newBuildDir }))

subprojects {
    val newSubprojectBuildDir = File(newBuildDir, project.name)
    project.layout.buildDirectory.value(project.layout.dir(provider { newSubprojectBuildDir }))
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
