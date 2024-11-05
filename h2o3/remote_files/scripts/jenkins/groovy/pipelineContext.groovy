def call(final String h2o3Root, final String mode, final scmEnv, final boolean ignoreChanges) {
    return call(h2o3Root, mode, scmEnv, ignoreChanges, null)
}

def call(final String h2o3Root, final String mode, final scmEnv, boolean ignoreChanges, final List<String> gradleOpts) {
    final String BUILD_SUMMARY_SCRIPT_NAME = 'buildSummary.groovy'
    final String BUILD_CONFIG_SCRIPT_NAME = 'buildConfig.groovy'
    final String PIPELINE_UTILS_SCRIPT_NAME = 'pipelineUtils.groovy'
    final String EMAILER_SCRIPT_NAME = 'emailer.groovy'
    final String HEALTH_CHECKER_SCRIPT_NAME = 'healthChecker.groovy'

    env.COMMIT_MESSAGE = sh(script: "cd ${h2o3Root} && git log -1 --pretty=%B", returnStdout: true).trim()
    env.BRANCH_NAME = scmEnv['GIT_BRANCH'].replaceAll('origin/', '')
    env.GIT_SHA = scmEnv['GIT_COMMIT']
    env.GIT_DATE = sh(script: "cd ${h2o3Root} && git show -s --format=%ci", returnStdout: true).trim()

    def final buildSummaryFactory = load("${h2o3Root}/scripts/jenkins/groovy/${BUILD_SUMMARY_SCRIPT_NAME}")
    def final buildConfigFactory = load("${h2o3Root}/scripts/jenkins/groovy/${BUILD_CONFIG_SCRIPT_NAME}")
    def final pipelineUtilsFactory = load("${h2o3Root}/scripts/jenkins/groovy/${PIPELINE_UTILS_SCRIPT_NAME}")
    def final emailerFactory = load("${h2o3Root}/scripts/jenkins/groovy/${EMAILER_SCRIPT_NAME}")
    def final healthCheckerFactory = load("${h2o3Root}/scripts/jenkins/groovy/${HEALTH_CHECKER_SCRIPT_NAME}")

    def final buildinfoPath = "${h2o3Root}/h2o-dist/buildinfo.json"

    def final pipelineUtils = pipelineUtilsFactory()
    def changes = null
    if (!ignoreChanges) {
        changes = getChanges(h2o3Root, scmEnv['GIT_TARGET'])
        if (changes == null) {
            ignoreChanges = true
        }
    }
    return new PipelineContext(
            buildConfigFactory(this, mode, env.COMMIT_MESSAGE, changes, ignoreChanges,
                    pipelineUtils.readSupportedHadoopDistributions(this, buildinfoPath), gradleOpts,
                    pipelineUtils.readCurrentXGBVersion(this, h2o3Root),
                    pipelineUtils.readCurrentGradleVersion(this, h2o3Root)
            ),
            buildSummaryFactory(true),
            pipelineUtils,
            emailerFactory(),
            healthCheckerFactory()
    )
}

private List<String> getChanges(final String h2o3Root, final String targetBranch) {
    sh """
        cd ${h2o3Root}
        git fetch --no-tags --progress https://github.com/h2oai/h2o-3 +refs/heads/${targetBranch}:refs/remotes/origin/${targetBranch}
    """
    def result
    try {
        final String mergeBaseSHA = sh(script: "cd ${h2o3Root} && git merge-base HEAD origin/${targetBranch}", returnStdout: true).trim()
        output = sh(script: "cd ${h2o3Root} && git diff --name-status ${mergeBaseSHA}", returnStdout: true)
        result = output
                .trim()
                .tokenize('\n')
                .collectEntries {
                    it.tokenize('\t').reverse()
                }
    } catch (Exception ignore) {
        result = null
    }
    return result
}

class PipelineContext{

    private final buildConfig
    private final buildSummary
    private final pipelineUtils
    private final emailer
    private final healthChecker
    private prepareBenchmarkDirStruct

    private PipelineContext(final buildConfig, final buildSummary, final pipelineUtils, final emailer, final healthChecker) {
        this.buildConfig = buildConfig
        this.buildSummary = buildSummary
        this.pipelineUtils = pipelineUtils
        this.emailer = emailer
        this.healthChecker = healthChecker
    }

    def getBuildConfig() {
        return buildConfig
    }

    def getBuildSummary() {
        return buildSummary
    }

    def getUtils() {
        return pipelineUtils
    }

    def getEmailer() {
        return emailer
    }

    def getHealthChecker() {
        return healthChecker
    }

    def getPrepareBenchmarkDirStruct(final context, final mlBenchmarkRoot) {
        if (prepareBenchmarkDirStruct == null) {
            prepareBenchmarkDirStruct = context.load("${mlBenchmarkRoot}/jenkins/groovy/prepareBenchmarkDirStruct.groovy")
        }
        return prepareBenchmarkDirStruct
    }

}

return this
