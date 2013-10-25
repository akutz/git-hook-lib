# encoding: utf-8

module GitHookLib

COMMIT_MESSAGE_ABORTED_ERROR = <<EOT
################################################################################
##                       !!! INVALID COMMIT MESSAGE(S) !!!                    ##
################################################################################

The following commit message(s) do not comply with this project's commit 
message format:

%s

This project requires that a tracking ticket be used in commit messages in
conjunction with a subject and more detailed description of the commit. For
example:

  [JIRA-123] Subject - Description

The text inside the brackets can also denote a Remedy AR with either:

  [AR123456] Subject - Description

or

  [AR 123456] Subject - Description

For the purpose of brevity, the subject portion of a commit message can be no
longer than 25 characters in length.
EOT

COMMIT_ABORTED_INSUFFICIENT_PERMS_MSG = <<EOT
################################################################################
##                       !!! INSUFFICIENT PERMISSIONS !!!                     ##
################################################################################

This project implements branch-level permissions and the current commit(s) 
exceed the granted access.

%s
EOT

COMMIT_ABORTED_PRE_COMMIT_BRANCH_NAME_MSG = <<EOT
################################################################################
##                        !!! INVALID BRANCH NAME(S) !!!                      ##
################################################################################

This project enforces a strict branch model, including permissible branch name
formats. One or more branches included in the commit or with changes staged for
commit does not meet the required branch name standards:

  %s

Acceptable branch names and branch name patterns are as follows:

  master

    The project's master branch. Only release-ready code is ever committed to
    this branch.

  develop

    The project's integration branch. Features and bugfixes should be tested
    in their own branches prior to merging them into the integration branch.

  release/MAJOR.MINOR.PATCH[-Comment]

    There may be one or more release branches at any given time. Release
    branches are created by branching off of the develop branch at an agreed
    upon point-in-time when the project is scheduled to move into the release
    phase.

    Release branches exist while the development code is tested and prepared 
    for a scheduled release. Only features and bugfixes that have been 
    thoroughly tested on the integration branch as well as tested by QA teams
    should be considered for release. 

    Once the project stakeholders agree to sign off on the release, the release
    branch is locked down and merged into the master branch from which the GA
    release is built.

    After the release branch is merged into master, it is also merged back into
    the develop branch to account for any last-minute bugfixes that may have
    occurred on the release branch while prepping for release.

    Once a release has shipped the release branch is often deleted and an
    annotated tag is created that points to the commit ID of the release.

    Please note that the release branch name requires a prefix of "release/"
    and a suffix that includes the first three components of the targeted
    release version. An optional comment, prefixed with a hyphen, is allowed 
    after the version.

  hotfix/MAJOR.MINOR.PATCH[-Comment]

    There may be one or more hotfix branches at any given time. Hotfix
    branches are created by branching from the last release tag in the 
    repository when a bug is found that needs to be fixed and cannot wait
    until the next scheduled release.

    Hotfix branches exist while the hotfix code is tested and prepared 
    for a hotfix release. Hotfix builds should be tested by automated builds
    and QA teams before the hotfix should be considered for release. However,
    unlike a scheduled release, a hotfix release is much smaller and isolated
    to the problem for which the hotfix is being created. Thus the number of 
    changes leading to potential problems should also be smaller.

    Once the project stakeholders agree to sign off on the hotfix, the hotfix
    branch is locked down and merged into the master branch from which the 
    hotfix release is built.

    After the hotfix branch is merged into master, it is also merged back into
    the develop branch to account for the bug fixes that were the purpose of 
    the hotfix's creation in the first place.

    Once a hotfix has shipped the hotfix branch is often deleted and an
    annotated tag is created that points to the commit ID of the hotfix.

    Please note that the hotfix branch name requires a prefix of "hotfix/"
    and a suffix that includes the first three components of the targeted
    hotfix version. An optional comment, prefixed with a hyphen, is allowed 
    after the version.

  feature/AR123456|JIRA-123[-MAJOR.MINOR.PATCH][-Comment]

    There may be one or more feature branches at any given time. Feature 
    branches are created off of the develop branch whenever a new feature is
    desired for the project. These features are often linked to user stories
    from a managed backlog, but not always.

    Feature branches exist while the feature is being developed and tested.
    There should be automated builds in place that will test feature branches
    automatically when they appear to the continuous integration system. 

    Once a feature has been completed, and its testing is successful, the 
    feature branch should be merged into the develop branch for integration
    testing. There are a few notes about this process:

      * It is often useful to rebase the feature branch prior to merging it 
        into the develop branch so that the merge into the develop branch will
        occur without any problems. For example:

          git checkout feature/JIRA-123-NewFeature
          git rebase develop

        Please keep in mind that if there are merge conflicts you will need
        to resolve them or abort the rebase. However, if there are merge 
        conflicts as a result of a rebase, it is almost certain there will be
        as well when merging the feature branch into develop. Thus it is in
        the project's best interest to go ahead and resolve the conflicts as
        part of the rebase operation.

      * Instead of merging the feature branch into the develop branch with 
        every single commit from the feature branch, it is requested that 
        the merge into develop be squashed. For example:

          git checkout develop
          git merge --squash feature/JIRA-123-NewFeature
          git commit -m "[JIRA-123] NewFeature - Integrated NewFeature"

        The above commands checkout the develop branch and then merges the 
        feature branch while squashing it. That means that if the feature 
        branch had contained 25 commits, instead of those 25 commits being
        applied to the develop branch, a single commit representing a 
        patchset built from those 25 commits will be applied to the develop
        branch using the specified message.

        So why squash commits? All the individual commits on the feature branch
        are lost forever, right? Well, three things:

          1. There is no rule that the feature branch *has* to be deleted from
             the development system on which it was created. Keep it around if 
             it's believed there may be some future use for those commits.

          2. Features should be atomic anyway. Can it be said that any 
             partitioned set of commits that went into creating that feature
             are useful in isolation? Features (and bugfixes) are supposed to
             be the smallest, atomic piece of shippable code. While we're all
             often proud of singular commits, only the sum of the parts is
             useful to the success of the project.

          3. Most importantly though is this: the power of a strict branching
             model isn't the ability to add features, bugfixes, or any kind of
             change to an integration or any other branch.

             The power of a strict branching model is the ability to *REMOVE*
             those changes if they are found to cause problems.

             And squashing a feature branch prior to merging it into the 
             integration branch means that the entire feature can be removed
             with a single revert or reset.

  * bugfix/AR123456|JIRA-123[-MAJOR.MINOR.PATCH][-Comment]

      A bugfix branch is exactly like a feature branch except it is created 
      to repair existing functionality instead of adding new functionality. For
      more information on bugfix branches please see the documentation above
      regarding feature branches.

  * attic/AR123456|JIRA-123[-MAJOR.MINOR.PATCH][-Comment]

      Attic branches are basically feature or bugfix branches that were pulled 
      from the scheduled release not because the contained code caused problems,
      but for any number of other reasons such as insufficient testing, the
      requested feature/bugfix was put on the schedule too late, etc.

      An attic branch is simply a way to shelve the code until it can be added
      to a future release.

  * support/AR123456|JIRA-123[-MAJOR.MINOR.PATCH][-Comment]

      Support branches are created from released code or even development code,
      and are destined to be tailored solutions for specific problems. The
      functionality inside a support branch may possibly never be merged into
      an official release.
EOT

end