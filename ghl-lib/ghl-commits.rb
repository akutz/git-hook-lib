module GitHookLib

    ##
    # A class that contains information about a commit.
    ##
    class CommitInfo
        @commit_id = nil
        def commit_id
            @commit_id
        end
        @branch = nil
        def branch
            @branch
        end
        @user = nil
        def user
            @user
        end
        @subject = nil
        def subject
            @subject
        end
        @files = nil
        def files
            @files
        end

        def initialize(commit_id, branch, user, subject, files=nil)
            @commit_id = commit_id
            @branch = branch
            @user = user
            @subject = subject
            @files = files
        end
    end

    class StagedCommitInfo < CommitInfo
        def initialize(git_repo, subject=nil)
            @branch = git_repo.current_branch
            @user = git_repo.current_user
            @subject = subject
            @files = git_repo.modified_files
        end
    end

    class CommitInfoFile
        @path
        def path
            @path
        end
        @writeable
        def writeable
            @writeable
        end
        def writeable=(writeable)
            @writeable = writeable
        end

        def initialize(path)
            @path = trim(path)
            @writeable = true
        end
    end

end